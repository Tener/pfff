open Common

open Ast_php

module Ast = Ast_php
module V = Visitor_php

(* timing:
 *  9h30: start
 *  9h42: finished
 *  9h47: have the sexp to better printout
 *  9h55: add static_scalar info about default parameter value
 * 
 * Porting of Justin Bishop function stats:
 *  https://gist.github.com/0726a693b5fdd767f085
 *)

type function_stat = {
  line: int;
  parameters: (string * static_scalar option) list;

  function_calls: string list;
  method_calls:   string list;
  instantiations: string list;
}
 (* with tarzan *)
type file_stat = (string * function_stat) list
 (* with tarzan *)


(* automatically generated by ocamltarzan *)
let sexp_of_function_stat {
                            line = v_line;
                            parameters = v_parameters;
                            function_calls = v_function_calls;
                            method_calls = v_method_calls;
                            instantiations = v_instantiations
                          } =
  let bnds = [] in
  let arg = Conv.sexp_of_list Conv.sexp_of_string v_instantiations in
  let bnd = Sexp.List [ Sexp.Atom ("instantiations" ^ ":"); arg ] in
  let bnds = bnd :: bnds in
  let arg = Conv.sexp_of_list Conv.sexp_of_string v_method_calls in
  let bnd = Sexp.List [ Sexp.Atom ("method_calls" ^ ":"); arg ] in
  let bnds = bnd :: bnds in
  let arg = Conv.sexp_of_list Conv.sexp_of_string v_function_calls in
  let bnd = Sexp.List [ Sexp.Atom ("function_calls" ^ ":"); arg ] in
  let bnds = bnd :: bnds in
  let arg =
    Conv.sexp_of_list
      (fun (v1, v2) ->
         let v1 = Conv.sexp_of_string v1
         and v2 = Conv.sexp_of_option Sexp_ast_php.sexp_of_static_scalar v2
         in Sexp.List [ v1; v2 ])
      v_parameters in
  let bnd = Sexp.List [ Sexp.Atom ("parameters" ^ ":"); arg ] in
  let bnds = bnd :: bnds in
  let arg = Conv.sexp_of_int v_line in
  let bnd = Sexp.List [ Sexp.Atom ("line" ^ ":"); arg ] in
  let bnds = bnd :: bnds in Sexp.List bnds
  
let sexp_of_file_stat v =
  Conv.sexp_of_list
    (fun (v1, v2) ->
       let v1 = Conv.sexp_of_string v1
       and v2 = sexp_of_function_stat v2
       in Sexp.List [ v1; v2 ])
    v
(* end auto generated *)


let s_of_file_stat x = 
  Sexp.to_string_hum (sexp_of_file_stat x)


let navigator_extract_functions file = 

  let (ast2, _stat) = Parse_php.parse file in
  let ast = Parse_php.program_of_program2 ast2 in

  let stats = 
    ast +> Common.map_filter (fun top ->
      match top with
      | FuncDef def ->
          
          let funcs = ref [] in
          let methods = ref [] in
          let instances = ref [] in

          let hooks = { V.default_visitor with
            V.kexpr = (fun (k,_) x ->
              match Ast.untype x with
              | New       (_,          classref, _)
              | AssignNew (_, _, _, _, classref, _) ->
                  (match classref with
                  | ClassNameRefStatic name ->
                      Common.push2 (Ast.name name) instances;
                  | ClassNameRefDynamic (var, objs) ->
                      (* TODO ? *)
                      ()
                  );
                  k x
              | _ -> k x
            );
            V.klvalue = (fun (k,_) x ->
              match Ast.untype x with
              | FunCallSimple (qu_opt, name, args) -> 
                  Common.push2 (Ast.name name) funcs;
                  k x
              | MethodCallSimple (var, tok, name, args) ->
                  Common.push2 (Ast.name name) methods;
                  k x
              | _ -> k x
            );
          } 
          in
          let visitor = V.mk_visitor hooks in
          visitor.V.vtop top;

          let stat = {
            line = Ast.line_of_info (def.f_tok);
            parameters = 
              def.f_params +> Ast.unparen +> List.map (fun param ->
                Ast.dname param.p_name,
                param.p_default +> Common.fmap (fun (tok, static_scalar) ->
                  static_scalar
                )
              );
            function_calls = !funcs;
            method_calls = !methods;
            instantiations = !instances;
          }
          in
          Some (Ast.name def.f_name, stat)

      | ClassDef _ | InterfaceDef _ 
      | StmtList _
      | Halt _
      | NotParsedCorrectly _ | FinalDef _ ->
          (* TODO ? *)
          None
    )
  in
  pr2 (s_of_file_stat stats);
  ()

let main = 
  navigator_extract_functions Sys.argv.(1)