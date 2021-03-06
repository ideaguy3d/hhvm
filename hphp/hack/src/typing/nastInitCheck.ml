(**
 * Copyright (c) 2015, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the "hack" directory of this source tree.
 *
 *)


(* module checking that all the class members are properly initialized *)
open Hh_core
open Nast
open Utils

module DICheck = Decl_init_check
module SN = Naming_special_names

(* Exception raised when we hit a return statement and the initialization
 * is not over.
 * When that is the case, we bubble up back to the toplevel environment.
 * An example (right hand side is the set of things initialized):
 *
 *  $this->x = 0;  // { x }
 *  if(...) {
 *     $this->y = 1; // { x, y }
 *     if(...) {
 *        $this->z = 2; // { x, y, z }
 *        return; // raise InitReturn with set { x, y, z}
 *     } // exception caught, re-raise with { x, y }
 *  } // exception caught, re-reraise with { x }
 *
 *  What is effectively initialized: { x }
 *)
exception InitReturn of SSet.t

(* Module initializing the environment
   Originally, every class member has 2 possible states,
   Vok  ==> when it is declared as optional, it is the job of the
            typer to make sure it is always check for the null case
            not our problem here
   Vnull ==> The value is now null, it MUST be initialized,
             and cannot be used before it has been initialized.

   Concerning the methods, basically the information we are
   interested in is, which class members do they initialize?
   But we don't want to recompute it every time it is called.
   So we memoize the result: hence the type method status.
 *)
module Env = struct

  type method_status =
    (* We already computed this method *)
    | Done

    (* We have never computed this private method before *)
    | Todo of func_body

  type t = {
    methods : method_status ref SMap.t ;
    props   : Decl_defs.element option SMap.t ;
    tenv    : Typing_env.env ;
  }

  let parent_id c = match c.c_extends with
    | [(_, Happly ((_, parent_id), _))] -> Some parent_id
    | _ -> None

  let rec make tenv c =
    let tenv = Typing_env.set_self_id tenv (snd c.c_name) in
    let tenv = match parent_id c with
      | None -> tenv
      | Some parent_id -> Typing_env.set_parent_id tenv parent_id in
    let methods = List.fold_left ~f:method_ ~init:SMap.empty c.c_methods in
    let decl_env = tenv.Typing_env.decl_env in
    let props = SMap.empty
      |> DICheck.own_props c SMap.add
      (* If we define our own constructor, we need to pretend any traits we use
       * did *not* define a constructor, because they are not reachable through
       * parent::__construct or similar functions. *)
      |> DICheck.trait_props decl_env c SMap.add
      |> DICheck.parent decl_env c SMap.add in
    { methods; props; tenv; }

  and method_ acc m =
    if m.m_visibility <> Private then acc else
      let name = snd m.m_name in
      let acc = SMap.add name (ref (Todo m.m_body)) acc in
      acc

  let get_method env m =
    SMap.get m env.methods

end

open Env

(*****************************************************************************)
(* List of functions that can use '$this' before the initialization is
 * over.
 *)
(*****************************************************************************)

let is_whitelisted = function
  | x when x = SN.StdlibFunctions.get_class -> true
  | _ -> false

let rec class_ tenv c =
  if c.c_mode = FileInfo.Mdecl then () else
  match c.c_constructor with
  | _ when c.c_kind = Ast.Cinterface -> ()
  | Some { m_body = NamedBody { fnb_unsafe = true; _ }; _ } -> ()
  | _ -> (
    let p = match c.c_constructor with
      | Some m -> fst m.m_name
      | None -> fst c.c_name
    in
    let env = Env.make tenv c in
    let inits = constructor env c.c_constructor in

    let check_inits = begin fun () ->
      let uninit_props = SMap.filter (fun prop elt ->
        if SSet.mem prop inits then false
        else Option.value_map elt
          ~f:(fun e -> not e.Decl_defs.elt_lateinit)
          ~default:true
      ) env.props in
      if SMap.empty <> uninit_props then begin
        if SMap.mem DICheck.parent_init_prop uninit_props then
          Errors.no_construct_parent p
        else
          Errors.not_initialized (p, snd c.c_name) (SMap.keys uninit_props)
      end
    end in

    Typing_suggest.save_initialized_members (snd c.c_name) inits;
    if c.c_kind = Ast.Ctrait || c.c_kind = Ast.Cabstract
    then begin
      let has_constructor = match c.c_constructor with
        | None -> false
        | Some m when m.m_abstract -> false
        | Some _ -> true in
      if has_constructor then check_inits () else ()
    end
    else check_inits ()
  )

and constructor env cstr =
  match cstr with
    | None -> SSet.empty
    | Some cstr ->
      let check_param_initializer = fun e -> ignore(expr env SSet.empty e) in
      List.iter cstr.m_params (fun p ->
        Option.iter p.param_expr check_param_initializer
      );
      let b = Nast.assert_named_body cstr.m_body in
      toplevel env SSet.empty b.fnb_nast

and assign _env acc x =
  SSet.add x acc

and assign_expr env acc e1 =
  match e1 with
    | _, Obj_get ((_, This), (_, Id (_, y)), _) ->
      assign env acc y
    | _, List el ->
      List.fold_left ~f:(assign_expr env) ~init:acc el
    | _ -> acc

and stmt env acc st =
  let expr = expr env in
  let block = block env in
  let catch = catch env in
  let case = case env in
  match st with
    | Expr (_, Call (Cnormal, (_, Class_const ((_, CIparent), (_, m))), _, el, _uel))
        when m = SN.Members.__construct ->
      let acc = List.fold_left ~f:expr ~init:acc el in
      assign env acc DICheck.parent_init_prop
    | Expr e -> expr acc e
    | GotoLabel _
    | Goto _
    | Break _ -> acc
    | Continue _ -> acc
    | Throw (_, e) -> expr acc e
    | Return (_, None) ->
      if are_all_init env acc
      then acc
      else raise (InitReturn acc)
    | Return (_, Some x) ->
      let acc = expr acc x in
      if are_all_init env acc
      then acc
      else raise (InitReturn acc)
    | Static_var el
    | Global_var el
       -> List.fold_left ~f:expr ~init:acc el
    | If (e1, b1, b2) ->
      let acc = expr acc e1 in
      let is_term1 = Nast_terminality.Terminal.block env.tenv b1 in
      let is_term2 = Nast_terminality.Terminal.block env.tenv b2 in
      let b1 = block acc b1 in
      let b2 = block acc b2 in
      if is_term1
      then SSet.union acc b2
      else if is_term2
      then SSet.union acc b1
      else SSet.union acc (SSet.inter b1 b2)
    | Do (b, e) ->
      let acc = block acc b in
      expr acc e
    | While (e, _) ->
      expr acc e
    | Using (_, e, b) ->
      let acc = expr acc e in
      block acc b
    | For (e1, _, _, _) ->
      expr acc e1
    | Switch (e, cl) ->
      let acc = expr acc e in
      let _ = List.map cl (case acc) in
      let cl = List.filter cl (function c ->
        not (Nast_terminality.Terminal.case env.tenv c)) in
      let cl = List.map cl (case acc) in
      let c = inter_list cl in
      SSet.union acc c
    | Foreach (e, _, _) ->
      let acc = expr acc e in
      acc
    | Try (b, cl, fb) ->
      let c = block acc b in
      let f = block acc fb in
      let _ = List.map cl (catch acc) in
      let cl = List.filter cl (fun (_, _, b) ->
        not (Nast_terminality.Terminal.block env.tenv b)) in
      let cl = List.map cl (catch acc) in
      let c = inter_list (c :: cl) in
      (* the finally block executes even if *none* of try and catch do *)
      let acc = SSet.union acc f in
      SSet.union acc c
    | Unsafe_block _
    | Fallthrough
    | Noop -> acc
    | Let (_, _, e) ->
      (* Scoped local variable cannot escape the block *)
      expr acc e

and toplevel env acc l =
  try List.fold_left ~f:(stmt env) ~init:acc l
  with InitReturn acc -> acc

and block env acc l =
  let acc_before_block = acc in
  try
    List.fold_left ~f:(stmt env) ~init:acc l
  with InitReturn _ ->
    (* The block has a return statement, forget what was initialized in it *)
    raise (InitReturn acc_before_block)

and are_all_init env set =
  SMap.fold (fun cv _ acc -> acc && SSet.mem cv set) env.props true

and check_all_init p env acc =
  SMap.iter begin fun cv _ ->
    if not (SSet.mem cv acc)
    then Errors.call_before_init p cv
  end env.props

and exprl env acc l = List.fold_left ~f:(expr env) ~init:acc l
and expr env acc (p, e) = expr_ env acc p e
and expr_ env acc p e =
  let expr = expr env in
  let exprl = exprl env in
  let field = field env in
  let afield = afield env in
  let fun_paraml = fun_paraml env in
  match e with
  | Any -> acc
  | Array fdl -> List.fold_left ~f:afield ~init:acc fdl
  | Darray fdl -> List.fold_left ~f:field ~init:acc fdl
  | Varray fdl -> List.fold_left ~f:expr ~init:acc fdl
  | ValCollection (_, el) -> exprl acc el
  | KeyValCollection (_, fdl) -> List.fold_left ~f:field ~init:acc fdl
  | This -> check_all_init p env acc; acc
  | Fun_id _
  | Method_id _
  | Smethod_id _
  | Method_caller _
  | Typename _
  | Id _ -> acc
  | Lvar _
  | ImmutableVar _
  | Lplaceholder _ | Dollardollar _ -> acc
  | Obj_get ((_, This), (_, Id (_, vx as v)), _) ->
      if SMap.mem vx env.props && not (SSet.mem vx acc)
      then (Errors.read_before_write v; acc)
      else acc
  | Clone e -> expr acc e
  | Obj_get (e1, e2, _) ->
      let acc = expr acc e1 in
      expr acc e2
  | Array_get (e, eo) ->
      let acc = expr acc e in
      (match eo with
      | None -> acc
      | Some e -> expr acc e)
  | Class_const _
  | Class_get _ -> acc
  | Call (Cnormal, (p, Obj_get ((_, This), (_, Id (_, f)), _)), _, _, _) ->
      let method_ = Env.get_method env f in
      (match method_ with
      | None ->
          check_all_init p env acc;
          acc
      | Some method_ ->
          (match !method_ with
          | Done -> acc
          | Todo b ->
            method_ := Done;
            let fb = Nast.assert_named_body b in
            toplevel env acc fb.fnb_nast
          )
      )
  | Call (_, e, _, el, uel) ->
    let el = el @ uel in
    let el =
      match e with
        | _, Id (_, fun_name) when is_whitelisted fun_name ->
          List.filter el begin function
            | _, This -> false
            | _ -> true
          end
        | _ -> el
    in
    let acc = List.fold_left ~f:expr ~init:acc el in
    expr acc e
  | True
  | False
  | Int _
  | Float _
  | Null
  | String _
  | String2 _
  | PrefixedString _
  | Unsafe_expr _ -> acc
  | Assert (AE_assert e) -> expr acc e
  | Yield e -> afield acc e
  | Yield_from e -> expr acc e
  | Yield_break -> acc
  | Dollar e -> expr acc e
  | Await e -> expr acc e
  | Suspend e -> expr acc e
  | List _ ->
      (* List is always an lvalue *)
      acc
  | Expr_list el ->
      exprl acc el
  | Special_func (Gena e)
  | Special_func (Gen_array_rec e) ->
      expr acc e
  | Special_func (Genva el) ->
      exprl acc el
  | New (_, el, uel) ->
      exprl acc (el @ uel)
  | Pair (e1, e2) ->
    let acc = expr acc e1 in
    expr acc e2
  | Cast (_, e)
  | Unop (_, e) -> expr acc e
  | Binop (Ast.Eq None, e1, e2) ->
      let acc = expr acc e2 in
      assign_expr env acc e1
  | Binop (Ast.AMpamp, e, _)
  | Binop (Ast.BArbar, e, _) ->
      expr acc e
  | Binop (_, e1, e2) ->
      let acc = expr acc e1 in
      expr acc e2
  | Pipe (_, e1, e2) ->
      let acc = expr acc e1 in
      expr acc e2
  | Eif (e1, None, e3) ->
      let acc = expr acc e1 in
      expr acc e3
  | Eif (e1, Some e2, e3) ->
      let acc = expr acc e1 in
      let acc = expr acc e2 in
      expr acc e3
  | InstanceOf (e, _) -> expr acc e
  | Is (e, _) -> expr acc e
  | As (e, _, _) -> expr acc e
  | Efun (f, _) ->
      let acc = fun_paraml acc f.f_params in
      (* We don't need to analyze the body of closures *)
      acc
  | Xml (_, l, el) ->
      let l = List.map l get_xhp_attr_expr in
      let acc = exprl acc l in
      exprl acc el
  | Callconv (_, e) -> expr acc e
  | Shape fdm ->
      ShapeMap.fold begin fun _ v acc ->
        expr acc v
      end fdm acc

and case env acc = function
  | Default b -> block env acc b
  | Case (_, e) -> block env acc e

and catch env acc (_, _, b) = block env acc b

and field env acc (e1, e2) =
  let acc = expr env acc e1 in
  let acc = expr env acc e2 in
  acc

and afield env acc = function
  | AFvalue e ->
      expr env acc e
  | AFkvalue (e1, e2) ->
      let acc = expr env acc e1 in
      let acc = expr env acc e2 in
      acc

and fun_param env acc param =
  match param.param_expr with
  | None -> acc
  | Some x -> expr env acc x

and fun_paraml env acc l = List.fold_left ~f:(fun_param env) ~init:acc l
