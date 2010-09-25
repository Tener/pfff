(* Yoann Padioleau
 *
 * Copyright (C) 2010 Facebook
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1 as published by the Free Software Foundation, with the
 * special exception on linking described in file license.txt.
 * 
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
 * license.txt for more details.
 *)

open Common

open Ast_cpp

module Ast = Ast_cpp
(*module V = Visitor_cpp *)

open Highlight_code

module T = Parser_cpp
module TH = Token_helpers_cpp

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(*****************************************************************************)
(* Helpers when have global analysis information *)
(*****************************************************************************)

let fake_no_def2 = NoUse
let fake_no_use2 = (NoInfoPlace, UniqueDef, MultiUse)

(*****************************************************************************)
(* Code highlighter *)
(*****************************************************************************)

let visit_toplevel 
    ~tag_hook
    prefs 
    (*db_opt *)
    (toplevel, toks)
  =
  let already_tagged = Hashtbl.create 101 in
  let tag = (fun ii categ ->
    tag_hook ii categ;
    Hashtbl.add already_tagged ii true
  )
  in

  (* -------------------------------------------------------------------- *)
  (* toks phase 1 *)

  let rec aux_toks xs = 
    match xs with
    | [] -> ()

    (* don't want class decl to generate noise *)
    | (T.Tclass(ii) | T.Tstruct(ii) | T.Tenum(ii))
      ::T.TCommentSpace ii2::T.TIdent(s, ii3)::T.TPtVirg _::xs ->
        aux_toks xs

    | (T.Tclass(ii) | T.Tstruct(ii) | T.Tenum (ii) 
        (* thrift stuff *)
        | T.TIdent ("service", ii)
      )
       ::T.TCommentSpace ii2::T.TIdent(s, ii3)::xs
        when Ast.col_of_info ii = 0 ->

        tag ii3 (Class (Def2 fake_no_def2));
        aux_toks xs;

    (* a little bit hphp specific *)
    | T.TComment ii::T.TCommentSpace ii2::T.TComment ii3::xs 
      ->
        let s = Ast.str_of_info ii in
        let s2 = Ast.str_of_info ii3 in
        (match () with
        | _ when s =~ "//////////.*" 
            && s2 =~ "// .*" 
            ->
            tag ii3 CommentSection1
        | _ -> 
            ()
        );
        aux_toks xs


    | t1::xs when TH.col_of_tok t1 = 0 && TH.is_not_comment t1 ->
        let line_t1 = TH.line_of_tok t1 in
        let rec find_ident_paren xs =
          match xs with
          | T.TIdent(s, ii1)::T.TOPar ii2::_ ->
              tag ii1 (Function (Def2 NoUse));
          | T.TIdent(s, ii1)::T.TCommentSpace _::T.TOPar ii2::_ ->
              tag ii1 (Function (Def2 NoUse));
          | x::xs ->
              find_ident_paren xs
          | [] -> ()
        in
        let same_line = (t1::xs) +> Common.take_while (fun t ->
          TH.line_of_tok t = line_t1) 
        in
        find_ident_paren same_line;
        aux_toks xs


    | x::xs ->
        aux_toks xs
  in
  aux_toks toks;

  (* -------------------------------------------------------------------- *)
  (* ast phase 1 *) 

  (* -------------------------------------------------------------------- *)
  (* toks phase 2 *)

  toks +> List.iter (fun tok -> 
    match tok with

    | T.TComment ii ->
        if not (Hashtbl.mem already_tagged ii)
        then
          tag ii Comment

    | T.TInt (_,ii) | T.TFloat (_,ii) ->
        tag ii Number

    | T.TString (s,ii) ->
        tag ii String

    | T.TChar (s,ii) ->
        tag ii String

    | T.Tfalse ii | T.Ttrue ii  ->
        tag ii Boolean

    | T.TPtVirg ii
    | T.TOPar ii | T.TCPar ii
    | T.TOBrace ii | T.TCBrace ii 
    | T.TOCro ii | T.TCCro ii
    | T.TDot ii | T.TComma ii | T.TPtrOp ii  
    | T.TAssign (_, ii)
    | T.TEq ii 
    | T.TWhy ii | T.TTilde ii | T.TBang ii 
    | T.TEllipsis ii 
    | T.TCol ii ->
        tag ii Punctuation

    | T.TInc ii | T.TDec ii 
    | T.TOrLog ii | T.TAndLog ii | T.TOr ii 
    | T.TXor ii | T.TAnd ii | T.TEqEq ii | T.TNotEq ii
    | T.TInf ii | T.TSup ii | T.TInfEq ii | T.TSupEq ii
    | T.TShl ii | T.TShr ii  
    | T.TPlus ii | T.TMinus ii | T.TMul ii | T.TDiv ii | T.TMod ii  
        ->
        tag ii Operator

    | T.Tshort ii | T.Tint ii ->
        tag ii TypeInt
    | T.Tdouble ii | T.Tfloat ii 
    | T.Tlong ii |  T.Tunsigned ii | T.Tsigned ii 
    | T.Tchar ii 
        -> tag ii TypeInt (* TODO *)
    | T.Tvoid ii 
        -> tag ii TypeVoid
    | T.Tbool ii 
    | T.Twchar_t ii
      -> tag ii TypeInt
    (* thrift stuff *)
    | T.TIdent (
        ("string" | "i32" | "i64" | "i8" | "i16" | "byte"
          | "list" | "map" | "set" 
          | "binary"
        ), ii) ->
        tag ii TypeInt


    | T.Tauto ii | T.Tregister ii | T.Textern ii | T.Tstatic ii  
    | T.Tconst ii | T.Tvolatile ii 
    | T.Tbreak ii | T.Tcontinue ii
    | T.Treturn ii
    | T.Tgoto ii | T.Tdefault ii 
    | T.Tsizeof ii 
    | T.Trestrict ii 
      -> 
        tag ii Keyword

    | T.Tasm ii 
    | T.Tattribute ii 
    | T.Tinline ii 
    | T.Ttypeof ii 
     -> 
        tag ii Keyword

    (* pp *)
    | T.TDefine ii -> 
        tag ii Define
    | T.TIdentDefine (_, ii) ->
        tag ii (MacroVar (Def2 NoUse))


    | T.TInclude (_, _, _, ii) -> 
        tag ii Include

    | T.TIfdef ii | T.TIfdefelse ii | T.TIfdefelif ii | T.TEndif ii ->
        tag ii Ifdef
    | T.TIfdefBool (_, ii) | T.TIfdefMisc (_, ii) | T.TIfdefVersion (_, ii) ->
        tag ii Ifdef

    | T.Tthis ii  
    | T.Tnew ii | T.Tdelete ii  
    | T.Ttemplate ii | T.Ttypeid ii | T.Ttypename ii  
    | T.Toperator ii  
    | T.Tpublic ii | T.Tprivate ii | T.Tprotected ii | T.Tfriend ii  
    | T.Tvirtual ii  
    | T.Tnamespace ii | T.Tusing ii  
    | T.Tconst_cast ii | T.Tdynamic_cast ii
    | T.Tstatic_cast ii | T.Treinterpret_cast ii
    | T.Texplicit ii | T.Tmutable ii  
    | T.Texport ii 
      ->
        tag ii Keyword

    | T.TPtrOpStar ii | T.TDotStar ii  ->
        tag ii Punctuation

    | T.TColCol ii  
    | T.TColCol2 ii ->
        tag ii Punctuation


    | T.Ttypedef ii | T.Tstruct ii |T.Tunion ii | T.Tenum ii  
        ->
        tag ii TypeMisc (* TODO *)

    | T.Tif ii | T.Telse ii ->
        tag ii KeywordConditional

    | T.Tswitch ii | T.Tcase ii ->
        tag ii KeywordConditional

    | T.Ttry ii | T.Tcatch ii | T.Tthrow ii ->
        tag ii KeywordExn

    (* thrift *)
    | T.TIdent (("throws" | "exception"), ii) ->
        tag ii KeywordExn


    | T.Tfor ii | T.Tdo ii | T.Twhile ii ->
        tag ii KeywordLoop

    | T.Tclass ii ->
        tag ii Keyword

    (* thrift *)
    | T.TIdent (("service" | "include" | "extends"), ii) ->
        tag ii Keyword


    | _ -> ()
  );

  ()