(**
 * Copyright (c) 2016, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the "hack" directory of this source tree. An additional
 * grant of patent rights can be found in the PATENTS file in the same
 * directory.
 *
 *
 * THIS FILE IS @generated; DO NOT EDIT IT
 * To regenerate this file, run
 *
 *   buck run //hphp/hack/src:generate_full_fidelity
 *
 * This module contains the type describing the structure of a syntax tree.
 *
 * The structure of the syntax tree is described by the collection of recursive
 * types that makes up the bulk of this file. The type `t` is the type of a node
 * in the syntax tree; each node has associated with it an arbitrary value of
 * type `SyntaxValue.t`, and syntax node proper, which has structure given by
 * the `syntax` type.
 *
 * Note that every child in the syntax tree is of type `t`, except for the
 * `Token.t` type. This should be the *only* child of a type other than `t`.
 * We are explicitly NOT attempting to impose a type structure on the parse
 * tree beyond what is already implied by the types here. For example,
 * we are not attempting to put into the type system here the restriction that
 * the children of a binary operator must be expressions. The reason for this
 * is because we are potentially parsing code as it is being typed, and we
 * do not want to restrict our ability to make good error recovery by imposing
 * a restriction that will only be valid in correct program text.
 *
 * That said, it would of course be ideal if the only children of a compound
 * statement were statements, and so on. But those invariants should be
 * imposed by the design of the parser, not by the type system of the syntax
 * tree code.
 *
 * We want to be able to use different kinds of tokens, with different
 * performance characteristics. Moreover, we want to associate arbitrary values
 * with the syntax nodes, so that we can construct syntax trees with various
 * properties -- trees that only know their widths and are thereby cheap to
 * serialize, trees that have full position data for each node, trees where the
 * tokens know their text and can therefore be edited, trees that have name
 * annotations or type annotations, and so on.
 *
 * We wish to associate arbitrary values with the syntax nodes so that we can
 * construct syntax trees with various properties -- trees that only know
 * their widths and are thereby cheap to serialize, trees that have full
 * position data for each node, trees where the tokens know their text and
 * can therefore be edited, trees that have name annotations or type
 * annotations, and so on.
 *
 * Therefore this module is functorized by the types for token and value to be
 * associated with the node.
 *)

module type TokenType = sig
  type t
  val kind: t -> Full_fidelity_token_kind.t
  val to_json: t -> Hh_json.json
end

module type SyntaxValueType = sig
  type t
end

(* This functors describe the shape of a parse tree that has a particular kind
 * of token in the leaves, and a particular kind of value associated with each
 * node.
 *)
module MakeSyntaxType(Token : TokenType)(SyntaxValue : SyntaxValueType) = struct
  type t = {
    syntax : syntax ;
    value : SyntaxValue.t
  }
  and end_of_file =
    { end_of_file_token                                  : t
    }
  and script_header =
    { header_less_than                                   : t
    ; header_question                                    : t
    ; header_language                                    : t
    }
  and script =
    { script_header                                      : t
    ; script_declarations                                : t
    }
  and simple_type_specifier =
    { simple_type_specifier                              : t
    }
  and literal_expression =
    { literal_expression                                 : t
    }
  and variable_expression =
    { variable_expression                                : t
    }
  and qualified_name_expression =
    { qualified_name_expression                          : t
    }
  and pipe_variable_expression =
    { pipe_variable_expression                           : t
    }
  and enum_declaration =
    { enum_attribute_spec                                : t
    ; enum_keyword                                       : t
    ; enum_name                                          : t
    ; enum_colon                                         : t
    ; enum_base                                          : t
    ; enum_type                                          : t
    ; enum_left_brace                                    : t
    ; enum_enumerators                                   : t
    ; enum_right_brace                                   : t
    }
  and enumerator =
    { enumerator_name                                    : t
    ; enumerator_equal                                   : t
    ; enumerator_value                                   : t
    ; enumerator_semicolon                               : t
    }
  and alias_declaration =
    { alias_attribute_spec                               : t
    ; alias_keyword                                      : t
    ; alias_name                                         : t
    ; alias_generic_parameter                            : t
    ; alias_constraint                                   : t
    ; alias_equal                                        : t
    ; alias_type                                         : t
    ; alias_semicolon                                    : t
    }
  and property_declaration =
    { property_modifiers                                 : t
    ; property_type                                      : t
    ; property_declarators                               : t
    ; property_semicolon                                 : t
    }
  and property_declarator =
    { property_name                                      : t
    ; property_initializer                               : t
    }
  and namespace_declaration =
    { namespace_keyword                                  : t
    ; namespace_name                                     : t
    ; namespace_body                                     : t
    }
  and namespace_body =
    { namespace_left_brace                               : t
    ; namespace_declarations                             : t
    ; namespace_right_brace                              : t
    }
  and namespace_empty_body =
    { namespace_semicolon                                : t
    }
  and namespace_use_declaration =
    { namespace_use_keyword                              : t
    ; namespace_use_kind                                 : t
    ; namespace_use_clauses                              : t
    ; namespace_use_semicolon                            : t
    }
  and namespace_group_use_declaration =
    { namespace_group_use_keyword                        : t
    ; namespace_group_use_kind                           : t
    ; namespace_group_use_prefix                         : t
    ; namespace_group_use_left_brace                     : t
    ; namespace_group_use_clauses                        : t
    ; namespace_group_use_right_brace                    : t
    ; namespace_group_use_semicolon                      : t
    }
  and namespace_use_clause =
    { namespace_use_clause_kind                          : t
    ; namespace_use_name                                 : t
    ; namespace_use_as                                   : t
    ; namespace_use_alias                                : t
    }
  and function_declaration =
    { function_attribute_spec                            : t
    ; function_declaration_header                        : t
    ; function_body                                      : t
    }
  and function_declaration_header =
    { function_async                                     : t
    ; function_coroutine                                 : t
    ; function_keyword                                   : t
    ; function_ampersand                                 : t
    ; function_name                                      : t
    ; function_type_parameter_list                       : t
    ; function_left_paren                                : t
    ; function_parameter_list                            : t
    ; function_right_paren                               : t
    ; function_colon                                     : t
    ; function_type                                      : t
    ; function_where_clause                              : t
    }
  and where_clause =
    { where_clause_keyword                               : t
    ; where_clause_constraints                           : t
    }
  and where_constraint =
    { where_constraint_left_type                         : t
    ; where_constraint_operator                          : t
    ; where_constraint_right_type                        : t
    }
  and methodish_declaration =
    { methodish_attribute                                : t
    ; methodish_modifiers                                : t
    ; methodish_function_decl_header                     : t
    ; methodish_function_body                            : t
    ; methodish_semicolon                                : t
    }
  and classish_declaration =
    { classish_attribute                                 : t
    ; classish_modifiers                                 : t
    ; classish_keyword                                   : t
    ; classish_name                                      : t
    ; classish_type_parameters                           : t
    ; classish_extends_keyword                           : t
    ; classish_extends_list                              : t
    ; classish_implements_keyword                        : t
    ; classish_implements_list                           : t
    ; classish_body                                      : t
    }
  and classish_body =
    { classish_body_left_brace                           : t
    ; classish_body_elements                             : t
    ; classish_body_right_brace                          : t
    }
  and trait_use =
    { trait_use_keyword                                  : t
    ; trait_use_names                                    : t
    ; trait_use_semicolon                                : t
    }
  and require_clause =
    { require_keyword                                    : t
    ; require_kind                                       : t
    ; require_name                                       : t
    ; require_semicolon                                  : t
    }
  and const_declaration =
    { const_abstract                                     : t
    ; const_keyword                                      : t
    ; const_type_specifier                               : t
    ; const_declarators                                  : t
    ; const_semicolon                                    : t
    }
  and constant_declarator =
    { constant_declarator_name                           : t
    ; constant_declarator_initializer                    : t
    }
  and type_const_declaration =
    { type_const_abstract                                : t
    ; type_const_keyword                                 : t
    ; type_const_type_keyword                            : t
    ; type_const_name                                    : t
    ; type_const_type_constraint                         : t
    ; type_const_equal                                   : t
    ; type_const_type_specifier                          : t
    ; type_const_semicolon                               : t
    }
  and decorated_expression =
    { decorated_expression_decorator                     : t
    ; decorated_expression_expression                    : t
    }
  and parameter_declaration =
    { parameter_attribute                                : t
    ; parameter_visibility                               : t
    ; parameter_type                                     : t
    ; parameter_name                                     : t
    ; parameter_default_value                            : t
    }
  and variadic_parameter =
    { variadic_parameter_ellipsis                        : t
    }
  and attribute_specification =
    { attribute_specification_left_double_angle          : t
    ; attribute_specification_attributes                 : t
    ; attribute_specification_right_double_angle         : t
    }
  and attribute =
    { attribute_name                                     : t
    ; attribute_left_paren                               : t
    ; attribute_values                                   : t
    ; attribute_right_paren                              : t
    }
  and inclusion_expression =
    { inclusion_require                                  : t
    ; inclusion_filename                                 : t
    }
  and inclusion_directive =
    { inclusion_expression                               : t
    ; inclusion_semicolon                                : t
    }
  and compound_statement =
    { compound_left_brace                                : t
    ; compound_statements                                : t
    ; compound_right_brace                               : t
    }
  and expression_statement =
    { expression_statement_expression                    : t
    ; expression_statement_semicolon                     : t
    }
  and unset_statement =
    { unset_keyword                                      : t
    ; unset_left_paren                                   : t
    ; unset_variables                                    : t
    ; unset_right_paren                                  : t
    ; unset_semicolon                                    : t
    }
  and while_statement =
    { while_keyword                                      : t
    ; while_left_paren                                   : t
    ; while_condition                                    : t
    ; while_right_paren                                  : t
    ; while_body                                         : t
    }
  and if_statement =
    { if_keyword                                         : t
    ; if_left_paren                                      : t
    ; if_condition                                       : t
    ; if_right_paren                                     : t
    ; if_statement                                       : t
    ; if_elseif_clauses                                  : t
    ; if_else_clause                                     : t
    }
  and elseif_clause =
    { elseif_keyword                                     : t
    ; elseif_left_paren                                  : t
    ; elseif_condition                                   : t
    ; elseif_right_paren                                 : t
    ; elseif_statement                                   : t
    }
  and else_clause =
    { else_keyword                                       : t
    ; else_statement                                     : t
    }
  and try_statement =
    { try_keyword                                        : t
    ; try_compound_statement                             : t
    ; try_catch_clauses                                  : t
    ; try_finally_clause                                 : t
    }
  and catch_clause =
    { catch_keyword                                      : t
    ; catch_left_paren                                   : t
    ; catch_type                                         : t
    ; catch_variable                                     : t
    ; catch_right_paren                                  : t
    ; catch_body                                         : t
    }
  and finally_clause =
    { finally_keyword                                    : t
    ; finally_body                                       : t
    }
  and do_statement =
    { do_keyword                                         : t
    ; do_body                                            : t
    ; do_while_keyword                                   : t
    ; do_left_paren                                      : t
    ; do_condition                                       : t
    ; do_right_paren                                     : t
    ; do_semicolon                                       : t
    }
  and for_statement =
    { for_keyword                                        : t
    ; for_left_paren                                     : t
    ; for_initializer                                    : t
    ; for_first_semicolon                                : t
    ; for_control                                        : t
    ; for_second_semicolon                               : t
    ; for_end_of_loop                                    : t
    ; for_right_paren                                    : t
    ; for_body                                           : t
    }
  and foreach_statement =
    { foreach_keyword                                    : t
    ; foreach_left_paren                                 : t
    ; foreach_collection                                 : t
    ; foreach_await_keyword                              : t
    ; foreach_as                                         : t
    ; foreach_key                                        : t
    ; foreach_arrow                                      : t
    ; foreach_value                                      : t
    ; foreach_right_paren                                : t
    ; foreach_body                                       : t
    }
  and switch_statement =
    { switch_keyword                                     : t
    ; switch_left_paren                                  : t
    ; switch_expression                                  : t
    ; switch_right_paren                                 : t
    ; switch_left_brace                                  : t
    ; switch_sections                                    : t
    ; switch_right_brace                                 : t
    }
  and switch_section =
    { switch_section_labels                              : t
    ; switch_section_statements                          : t
    ; switch_section_fallthrough                         : t
    }
  and switch_fallthrough =
    { fallthrough_keyword                                : t
    ; fallthrough_semicolon                              : t
    }
  and case_label =
    { case_keyword                                       : t
    ; case_expression                                    : t
    ; case_colon                                         : t
    }
  and default_label =
    { default_keyword                                    : t
    ; default_colon                                      : t
    }
  and return_statement =
    { return_keyword                                     : t
    ; return_expression                                  : t
    ; return_semicolon                                   : t
    }
  and goto_label =
    { goto_label_name                                    : t
    ; goto_label_colon                                   : t
    }
  and goto_statement =
    { goto_statement_keyword                             : t
    ; goto_statement_label_name                          : t
    ; goto_statement_semicolon                           : t
    }
  and throw_statement =
    { throw_keyword                                      : t
    ; throw_expression                                   : t
    ; throw_semicolon                                    : t
    }
  and break_statement =
    { break_keyword                                      : t
    ; break_level                                        : t
    ; break_semicolon                                    : t
    }
  and continue_statement =
    { continue_keyword                                   : t
    ; continue_level                                     : t
    ; continue_semicolon                                 : t
    }
  and function_static_statement =
    { static_static_keyword                              : t
    ; static_declarations                                : t
    ; static_semicolon                                   : t
    }
  and static_declarator =
    { static_name                                        : t
    ; static_initializer                                 : t
    }
  and echo_statement =
    { echo_keyword                                       : t
    ; echo_expressions                                   : t
    ; echo_semicolon                                     : t
    }
  and global_statement =
    { global_keyword                                     : t
    ; global_variables                                   : t
    ; global_semicolon                                   : t
    }
  and simple_initializer =
    { simple_initializer_equal                           : t
    ; simple_initializer_value                           : t
    }
  and anonymous_function =
    { anonymous_async_keyword                            : t
    ; anonymous_coroutine_keyword                        : t
    ; anonymous_function_keyword                         : t
    ; anonymous_left_paren                               : t
    ; anonymous_parameters                               : t
    ; anonymous_right_paren                              : t
    ; anonymous_colon                                    : t
    ; anonymous_type                                     : t
    ; anonymous_use                                      : t
    ; anonymous_body                                     : t
    }
  and anonymous_function_use_clause =
    { anonymous_use_keyword                              : t
    ; anonymous_use_left_paren                           : t
    ; anonymous_use_variables                            : t
    ; anonymous_use_right_paren                          : t
    }
  and lambda_expression =
    { lambda_async                                       : t
    ; lambda_coroutine                                   : t
    ; lambda_signature                                   : t
    ; lambda_arrow                                       : t
    ; lambda_body                                        : t
    }
  and lambda_signature =
    { lambda_left_paren                                  : t
    ; lambda_parameters                                  : t
    ; lambda_right_paren                                 : t
    ; lambda_colon                                       : t
    ; lambda_type                                        : t
    }
  and cast_expression =
    { cast_left_paren                                    : t
    ; cast_type                                          : t
    ; cast_right_paren                                   : t
    ; cast_operand                                       : t
    }
  and scope_resolution_expression =
    { scope_resolution_qualifier                         : t
    ; scope_resolution_operator                          : t
    ; scope_resolution_name                              : t
    }
  and member_selection_expression =
    { member_object                                      : t
    ; member_operator                                    : t
    ; member_name                                        : t
    }
  and safe_member_selection_expression =
    { safe_member_object                                 : t
    ; safe_member_operator                               : t
    ; safe_member_name                                   : t
    }
  and embedded_member_selection_expression =
    { embedded_member_object                             : t
    ; embedded_member_operator                           : t
    ; embedded_member_name                               : t
    }
  and yield_expression =
    { yield_keyword                                      : t
    ; yield_operand                                      : t
    }
  and print_expression =
    { print_keyword                                      : t
    ; print_expression                                   : t
    }
  and prefix_unary_expression =
    { prefix_unary_operator                              : t
    ; prefix_unary_operand                               : t
    }
  and postfix_unary_expression =
    { postfix_unary_operand                              : t
    ; postfix_unary_operator                             : t
    }
  and binary_expression =
    { binary_left_operand                                : t
    ; binary_operator                                    : t
    ; binary_right_operand                               : t
    }
  and instanceof_expression =
    { instanceof_left_operand                            : t
    ; instanceof_operator                                : t
    ; instanceof_right_operand                           : t
    }
  and conditional_expression =
    { conditional_test                                   : t
    ; conditional_question                               : t
    ; conditional_consequence                            : t
    ; conditional_colon                                  : t
    ; conditional_alternative                            : t
    }
  and eval_expression =
    { eval_keyword                                       : t
    ; eval_left_paren                                    : t
    ; eval_argument                                      : t
    ; eval_right_paren                                   : t
    }
  and empty_expression =
    { empty_keyword                                      : t
    ; empty_left_paren                                   : t
    ; empty_argument                                     : t
    ; empty_right_paren                                  : t
    }
  and define_expression =
    { define_keyword                                     : t
    ; define_left_paren                                  : t
    ; define_argument_list                               : t
    ; define_right_paren                                 : t
    }
  and isset_expression =
    { isset_keyword                                      : t
    ; isset_left_paren                                   : t
    ; isset_argument_list                                : t
    ; isset_right_paren                                  : t
    }
  and function_call_expression =
    { function_call_receiver                             : t
    ; function_call_left_paren                           : t
    ; function_call_argument_list                        : t
    ; function_call_right_paren                          : t
    }
  and parenthesized_expression =
    { parenthesized_expression_left_paren                : t
    ; parenthesized_expression_expression                : t
    ; parenthesized_expression_right_paren               : t
    }
  and braced_expression =
    { braced_expression_left_brace                       : t
    ; braced_expression_expression                       : t
    ; braced_expression_right_brace                      : t
    }
  and embedded_braced_expression =
    { embedded_braced_expression_left_brace              : t
    ; embedded_braced_expression_expression              : t
    ; embedded_braced_expression_right_brace             : t
    }
  and list_expression =
    { list_keyword                                       : t
    ; list_left_paren                                    : t
    ; list_members                                       : t
    ; list_right_paren                                   : t
    }
  and collection_literal_expression =
    { collection_literal_name                            : t
    ; collection_literal_left_brace                      : t
    ; collection_literal_initializers                    : t
    ; collection_literal_right_brace                     : t
    }
  and object_creation_expression =
    { object_creation_new_keyword                        : t
    ; object_creation_type                               : t
    ; object_creation_left_paren                         : t
    ; object_creation_argument_list                      : t
    ; object_creation_right_paren                        : t
    }
  and array_creation_expression =
    { array_creation_left_bracket                        : t
    ; array_creation_members                             : t
    ; array_creation_right_bracket                       : t
    }
  and array_intrinsic_expression =
    { array_intrinsic_keyword                            : t
    ; array_intrinsic_left_paren                         : t
    ; array_intrinsic_members                            : t
    ; array_intrinsic_right_paren                        : t
    }
  and darray_intrinsic_expression =
    { darray_intrinsic_keyword                           : t
    ; darray_intrinsic_left_bracket                      : t
    ; darray_intrinsic_members                           : t
    ; darray_intrinsic_right_bracket                     : t
    }
  and dictionary_intrinsic_expression =
    { dictionary_intrinsic_keyword                       : t
    ; dictionary_intrinsic_left_bracket                  : t
    ; dictionary_intrinsic_members                       : t
    ; dictionary_intrinsic_right_bracket                 : t
    }
  and keyset_intrinsic_expression =
    { keyset_intrinsic_keyword                           : t
    ; keyset_intrinsic_left_bracket                      : t
    ; keyset_intrinsic_members                           : t
    ; keyset_intrinsic_right_bracket                     : t
    }
  and varray_intrinsic_expression =
    { varray_intrinsic_keyword                           : t
    ; varray_intrinsic_left_bracket                      : t
    ; varray_intrinsic_members                           : t
    ; varray_intrinsic_right_bracket                     : t
    }
  and vector_intrinsic_expression =
    { vector_intrinsic_keyword                           : t
    ; vector_intrinsic_left_bracket                      : t
    ; vector_intrinsic_members                           : t
    ; vector_intrinsic_right_bracket                     : t
    }
  and element_initializer =
    { element_key                                        : t
    ; element_arrow                                      : t
    ; element_value                                      : t
    }
  and subscript_expression =
    { subscript_receiver                                 : t
    ; subscript_left_bracket                             : t
    ; subscript_index                                    : t
    ; subscript_right_bracket                            : t
    }
  and embedded_subscript_expression =
    { embedded_subscript_receiver                        : t
    ; embedded_subscript_left_bracket                    : t
    ; embedded_subscript_index                           : t
    ; embedded_subscript_right_bracket                   : t
    }
  and awaitable_creation_expression =
    { awaitable_async                                    : t
    ; awaitable_coroutine                                : t
    ; awaitable_compound_statement                       : t
    }
  and xhp_children_declaration =
    { xhp_children_keyword                               : t
    ; xhp_children_expression                            : t
    ; xhp_children_semicolon                             : t
    }
  and xhp_children_parenthesized_list =
    { xhp_children_list_left_paren                       : t
    ; xhp_children_list_xhp_children                     : t
    ; xhp_children_list_right_paren                      : t
    }
  and xhp_category_declaration =
    { xhp_category_keyword                               : t
    ; xhp_category_categories                            : t
    ; xhp_category_semicolon                             : t
    }
  and xhp_enum_type =
    { xhp_enum_keyword                                   : t
    ; xhp_enum_left_brace                                : t
    ; xhp_enum_values                                    : t
    ; xhp_enum_right_brace                               : t
    }
  and xhp_required =
    { xhp_required_at                                    : t
    ; xhp_required_keyword                               : t
    }
  and xhp_class_attribute_declaration =
    { xhp_attribute_keyword                              : t
    ; xhp_attribute_attributes                           : t
    ; xhp_attribute_semicolon                            : t
    }
  and xhp_class_attribute =
    { xhp_attribute_decl_type                            : t
    ; xhp_attribute_decl_name                            : t
    ; xhp_attribute_decl_initializer                     : t
    ; xhp_attribute_decl_required                        : t
    }
  and xhp_simple_class_attribute =
    { xhp_simple_class_attribute_type                    : t
    }
  and xhp_attribute =
    { xhp_attribute_name                                 : t
    ; xhp_attribute_equal                                : t
    ; xhp_attribute_expression                           : t
    }
  and xhp_open =
    { xhp_open_left_angle                                : t
    ; xhp_open_name                                      : t
    ; xhp_open_attributes                                : t
    ; xhp_open_right_angle                               : t
    }
  and xhp_expression =
    { xhp_open                                           : t
    ; xhp_body                                           : t
    ; xhp_close                                          : t
    }
  and xhp_close =
    { xhp_close_left_angle                               : t
    ; xhp_close_name                                     : t
    ; xhp_close_right_angle                              : t
    }
  and type_constant =
    { type_constant_left_type                            : t
    ; type_constant_separator                            : t
    ; type_constant_right_type                           : t
    }
  and vector_type_specifier =
    { vector_type_keyword                                : t
    ; vector_type_left_angle                             : t
    ; vector_type_type                                   : t
    ; vector_type_right_angle                            : t
    }
  and keyset_type_specifier =
    { keyset_type_keyword                                : t
    ; keyset_type_left_angle                             : t
    ; keyset_type_type                                   : t
    ; keyset_type_right_angle                            : t
    }
  and tuple_type_explicit_specifier =
    { tuple_type_keyword                                 : t
    ; tuple_type_left_angle                              : t
    ; tuple_type_types                                   : t
    ; tuple_type_right_angle                             : t
    }
  and varray_type_specifier =
    { varray_keyword                                     : t
    ; varray_left_angle                                  : t
    ; varray_type                                        : t
    ; varray_optional_comma                              : t
    ; varray_right_angle                                 : t
    }
  and vector_array_type_specifier =
    { vector_array_keyword                               : t
    ; vector_array_left_angle                            : t
    ; vector_array_type                                  : t
    ; vector_array_right_angle                           : t
    }
  and type_parameter =
    { type_variance                                      : t
    ; type_name                                          : t
    ; type_constraints                                   : t
    }
  and type_constraint =
    { constraint_keyword                                 : t
    ; constraint_type                                    : t
    }
  and darray_type_specifier =
    { darray_keyword                                     : t
    ; darray_left_angle                                  : t
    ; darray_key                                         : t
    ; darray_comma                                       : t
    ; darray_value                                       : t
    ; darray_optional_comma                              : t
    ; darray_right_angle                                 : t
    }
  and map_array_type_specifier =
    { map_array_keyword                                  : t
    ; map_array_left_angle                               : t
    ; map_array_key                                      : t
    ; map_array_comma                                    : t
    ; map_array_value                                    : t
    ; map_array_right_angle                              : t
    }
  and dictionary_type_specifier =
    { dictionary_type_keyword                            : t
    ; dictionary_type_left_angle                         : t
    ; dictionary_type_members                            : t
    ; dictionary_type_right_angle                        : t
    }
  and closure_type_specifier =
    { closure_outer_left_paren                           : t
    ; closure_function_keyword                           : t
    ; closure_inner_left_paren                           : t
    ; closure_parameter_types                            : t
    ; closure_inner_right_paren                          : t
    ; closure_colon                                      : t
    ; closure_return_type                                : t
    ; closure_outer_right_paren                          : t
    }
  and classname_type_specifier =
    { classname_keyword                                  : t
    ; classname_left_angle                               : t
    ; classname_type                                     : t
    ; classname_right_angle                              : t
    }
  and field_specifier =
    { field_question                                     : t
    ; field_name                                         : t
    ; field_arrow                                        : t
    ; field_type                                         : t
    }
  and field_initializer =
    { field_initializer_name                             : t
    ; field_initializer_arrow                            : t
    ; field_initializer_value                            : t
    }
  and shape_type_specifier =
    { shape_type_keyword                                 : t
    ; shape_type_left_paren                              : t
    ; shape_type_fields                                  : t
    ; shape_type_ellipsis                                : t
    ; shape_type_right_paren                             : t
    }
  and shape_expression =
    { shape_expression_keyword                           : t
    ; shape_expression_left_paren                        : t
    ; shape_expression_fields                            : t
    ; shape_expression_right_paren                       : t
    }
  and tuple_expression =
    { tuple_expression_keyword                           : t
    ; tuple_expression_left_paren                        : t
    ; tuple_expression_items                             : t
    ; tuple_expression_right_paren                       : t
    }
  and generic_type_specifier =
    { generic_class_type                                 : t
    ; generic_argument_list                              : t
    }
  and nullable_type_specifier =
    { nullable_question                                  : t
    ; nullable_type                                      : t
    }
  and soft_type_specifier =
    { soft_at                                            : t
    ; soft_type                                          : t
    }
  and type_arguments =
    { type_arguments_left_angle                          : t
    ; type_arguments_types                               : t
    ; type_arguments_right_angle                         : t
    }
  and type_parameters =
    { type_parameters_left_angle                         : t
    ; type_parameters_parameters                         : t
    ; type_parameters_right_angle                        : t
    }
  and tuple_type_specifier =
    { tuple_left_paren                                   : t
    ; tuple_types                                        : t
    ; tuple_right_paren                                  : t
    }
  and error =
    { error_error                                        : t
    }
  and list_item =
    { list_item                                          : t
    ; list_separator                                     : t
    }

  and syntax =
  | Token                             of Token.t
  | Missing
  | SyntaxList                        of t list
  | EndOfFile                         of end_of_file
  | ScriptHeader                      of script_header
  | Script                            of script
  | SimpleTypeSpecifier               of simple_type_specifier
  | LiteralExpression                 of literal_expression
  | VariableExpression                of variable_expression
  | QualifiedNameExpression           of qualified_name_expression
  | PipeVariableExpression            of pipe_variable_expression
  | EnumDeclaration                   of enum_declaration
  | Enumerator                        of enumerator
  | AliasDeclaration                  of alias_declaration
  | PropertyDeclaration               of property_declaration
  | PropertyDeclarator                of property_declarator
  | NamespaceDeclaration              of namespace_declaration
  | NamespaceBody                     of namespace_body
  | NamespaceEmptyBody                of namespace_empty_body
  | NamespaceUseDeclaration           of namespace_use_declaration
  | NamespaceGroupUseDeclaration      of namespace_group_use_declaration
  | NamespaceUseClause                of namespace_use_clause
  | FunctionDeclaration               of function_declaration
  | FunctionDeclarationHeader         of function_declaration_header
  | WhereClause                       of where_clause
  | WhereConstraint                   of where_constraint
  | MethodishDeclaration              of methodish_declaration
  | ClassishDeclaration               of classish_declaration
  | ClassishBody                      of classish_body
  | TraitUse                          of trait_use
  | RequireClause                     of require_clause
  | ConstDeclaration                  of const_declaration
  | ConstantDeclarator                of constant_declarator
  | TypeConstDeclaration              of type_const_declaration
  | DecoratedExpression               of decorated_expression
  | ParameterDeclaration              of parameter_declaration
  | VariadicParameter                 of variadic_parameter
  | AttributeSpecification            of attribute_specification
  | Attribute                         of attribute
  | InclusionExpression               of inclusion_expression
  | InclusionDirective                of inclusion_directive
  | CompoundStatement                 of compound_statement
  | ExpressionStatement               of expression_statement
  | UnsetStatement                    of unset_statement
  | WhileStatement                    of while_statement
  | IfStatement                       of if_statement
  | ElseifClause                      of elseif_clause
  | ElseClause                        of else_clause
  | TryStatement                      of try_statement
  | CatchClause                       of catch_clause
  | FinallyClause                     of finally_clause
  | DoStatement                       of do_statement
  | ForStatement                      of for_statement
  | ForeachStatement                  of foreach_statement
  | SwitchStatement                   of switch_statement
  | SwitchSection                     of switch_section
  | SwitchFallthrough                 of switch_fallthrough
  | CaseLabel                         of case_label
  | DefaultLabel                      of default_label
  | ReturnStatement                   of return_statement
  | GotoLabel                         of goto_label
  | GotoStatement                     of goto_statement
  | ThrowStatement                    of throw_statement
  | BreakStatement                    of break_statement
  | ContinueStatement                 of continue_statement
  | FunctionStaticStatement           of function_static_statement
  | StaticDeclarator                  of static_declarator
  | EchoStatement                     of echo_statement
  | GlobalStatement                   of global_statement
  | SimpleInitializer                 of simple_initializer
  | AnonymousFunction                 of anonymous_function
  | AnonymousFunctionUseClause        of anonymous_function_use_clause
  | LambdaExpression                  of lambda_expression
  | LambdaSignature                   of lambda_signature
  | CastExpression                    of cast_expression
  | ScopeResolutionExpression         of scope_resolution_expression
  | MemberSelectionExpression         of member_selection_expression
  | SafeMemberSelectionExpression     of safe_member_selection_expression
  | EmbeddedMemberSelectionExpression of embedded_member_selection_expression
  | YieldExpression                   of yield_expression
  | PrintExpression                   of print_expression
  | PrefixUnaryExpression             of prefix_unary_expression
  | PostfixUnaryExpression            of postfix_unary_expression
  | BinaryExpression                  of binary_expression
  | InstanceofExpression              of instanceof_expression
  | ConditionalExpression             of conditional_expression
  | EvalExpression                    of eval_expression
  | EmptyExpression                   of empty_expression
  | DefineExpression                  of define_expression
  | IssetExpression                   of isset_expression
  | FunctionCallExpression            of function_call_expression
  | ParenthesizedExpression           of parenthesized_expression
  | BracedExpression                  of braced_expression
  | EmbeddedBracedExpression          of embedded_braced_expression
  | ListExpression                    of list_expression
  | CollectionLiteralExpression       of collection_literal_expression
  | ObjectCreationExpression          of object_creation_expression
  | ArrayCreationExpression           of array_creation_expression
  | ArrayIntrinsicExpression          of array_intrinsic_expression
  | DarrayIntrinsicExpression         of darray_intrinsic_expression
  | DictionaryIntrinsicExpression     of dictionary_intrinsic_expression
  | KeysetIntrinsicExpression         of keyset_intrinsic_expression
  | VarrayIntrinsicExpression         of varray_intrinsic_expression
  | VectorIntrinsicExpression         of vector_intrinsic_expression
  | ElementInitializer                of element_initializer
  | SubscriptExpression               of subscript_expression
  | EmbeddedSubscriptExpression       of embedded_subscript_expression
  | AwaitableCreationExpression       of awaitable_creation_expression
  | XHPChildrenDeclaration            of xhp_children_declaration
  | XHPChildrenParenthesizedList      of xhp_children_parenthesized_list
  | XHPCategoryDeclaration            of xhp_category_declaration
  | XHPEnumType                       of xhp_enum_type
  | XHPRequired                       of xhp_required
  | XHPClassAttributeDeclaration      of xhp_class_attribute_declaration
  | XHPClassAttribute                 of xhp_class_attribute
  | XHPSimpleClassAttribute           of xhp_simple_class_attribute
  | XHPAttribute                      of xhp_attribute
  | XHPOpen                           of xhp_open
  | XHPExpression                     of xhp_expression
  | XHPClose                          of xhp_close
  | TypeConstant                      of type_constant
  | VectorTypeSpecifier               of vector_type_specifier
  | KeysetTypeSpecifier               of keyset_type_specifier
  | TupleTypeExplicitSpecifier        of tuple_type_explicit_specifier
  | VarrayTypeSpecifier               of varray_type_specifier
  | VectorArrayTypeSpecifier          of vector_array_type_specifier
  | TypeParameter                     of type_parameter
  | TypeConstraint                    of type_constraint
  | DarrayTypeSpecifier               of darray_type_specifier
  | MapArrayTypeSpecifier             of map_array_type_specifier
  | DictionaryTypeSpecifier           of dictionary_type_specifier
  | ClosureTypeSpecifier              of closure_type_specifier
  | ClassnameTypeSpecifier            of classname_type_specifier
  | FieldSpecifier                    of field_specifier
  | FieldInitializer                  of field_initializer
  | ShapeTypeSpecifier                of shape_type_specifier
  | ShapeExpression                   of shape_expression
  | TupleExpression                   of tuple_expression
  | GenericTypeSpecifier              of generic_type_specifier
  | NullableTypeSpecifier             of nullable_type_specifier
  | SoftTypeSpecifier                 of soft_type_specifier
  | TypeArguments                     of type_arguments
  | TypeParameters                    of type_parameters
  | TupleTypeSpecifier                of tuple_type_specifier
  | ErrorSyntax                       of error
  | ListItem                          of list_item

end (* MakeSyntaxType *)