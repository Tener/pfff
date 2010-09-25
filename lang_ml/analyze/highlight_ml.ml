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

open Ast_ml

module Ast = Ast_ml
module V = Visitor_ml

open Highlight_code

module T = Parser_ml

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(*****************************************************************************)
(* Helpers when have global analysis information *)
(*****************************************************************************)

(* quite pad specific ... see my ~/.emacs *)
let h_pervasives_pad = Common.hashset_of_list [
  "pr2";"pr";"pr2_gen";
  "sprintf";"i_to_s";
  "pp2";"spf";
  "log";"log2";"log3"
]

let h_builtin_modules = Common.hashset_of_list [
  "Pervasives"; "Common";
  "List"; "Hashtbl"; "Array";
  "String"; "Str";
  "Sys"; "Unix"; "Gc";
]

let h_builtin_bool = Common.hashset_of_list [
  "not";
  "exists"; "forall";
]

(*****************************************************************************)
(* Code highlighter *)
(*****************************************************************************)

(* The idea of the code below is to visit the program either through its
 * AST or its list of tokens. The tokens are easier for tagging keywords,
 * number and basic entities. The Ast is better for tagging idents
 * to figure out what kind of ident it is.
 *)

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
  (* -------------------------------------------------------------------- *)
  (* poor's man semantic tagger. Infer if ident is a func, or class,
   * or module based on the few tokens around. 
   * 
   * This may look ridiculous to do such semantic tagging using tokens 
   * instead of the full ast but many ocaml files could not parse with
   * the default parser because of camlp4 extensions so having
   * a solid token-base tagger is still useful as a last resort.
   * 
   * note: all TCommentSpace are filtered in xs so easier to write
   * rules (but regular comments are kept as well as newlines).
   *)
  let rec aux_toks xs = 
    match xs with
    | [] -> ()

    (* a little bit pad specific *)
    |   T.TComment(ii)
      ::T.TCommentNewline (ii2)
      ::T.TComment(ii3)
      ::T.TCommentNewline (ii4)
      ::T.TComment(ii5)
      ::xs ->
        let s = Ast.str_of_info ii in
        let s5 =  Ast.str_of_info ii5 in
        (match () with
        | _ when s =~ ".*\\*\\*\\*\\*" && s5 =~ ".*\\*\\*\\*\\*" ->
          tag ii CommentEstet;
          tag ii5 CommentEstet;
          tag ii3 CommentSection1
        | _ when s =~ ".*------" && s5 =~ ".*------" ->
          tag ii CommentEstet;
          tag ii5 CommentEstet;
          tag ii3 CommentSection2
        | _ when s =~ ".*####" && s5 =~ ".*####" ->
          tag ii CommentEstet;
          tag ii5 CommentEstet;
          tag ii3 CommentSection0
        | _ ->
            ()
        );
        aux_toks xs

    | T.Tlet(ii)::T.TLowerIdent(s, ii3)::T.TEq ii5::xs
        when Ast.col_of_info ii = 0 ->

        tag ii3 (Global (Def2 NoUse));
        aux_toks xs;

    | T.Tlet(ii)::T.TLowerIdent(s, ii3)::xs
        when Ast.col_of_info ii = 0 ->

        tag ii3 (Function (Def2 NoUse));
        aux_toks xs;

    | (T.Tval(ii)|T.Texternal(ii))::T.TLowerIdent(s, ii3)::xs
        when Ast.col_of_info ii = 0 ->

        tag ii3 (FunctionDecl NoUse);
        aux_toks xs;

    | T.Tlet(ii)::
      T.Trec(_ii)::
      T.TLowerIdent(s, ii3)::xs
        when Ast.col_of_info ii = 0 ->

        tag ii3 (Function (Def2 NoUse));
        aux_toks xs;

    | T.Tmodule(_)
      ::T.TUpperIdent(_,ii_mod)
      ::T.TEq (_)
      ::T.Tstruct (_)::xs ->
        tag ii_mod (Module Def);
        aux_toks xs

    | T.Tmodule(_)
      ::T.TUpperIdent(_,ii_mod)
      ::T.TColon (_)
      ::T.Tsig (_)::xs ->
        tag ii_mod (Module Def);
        aux_toks xs


    | T.Tand(ii)::T.TLowerIdent(s, ii3)::xs
        when Ast.col_of_info ii = 0 ->

        tag ii3 (Function (Def2 NoUse));
        aux_toks xs;

    | T.Ttype(ii)::T.TLowerIdent(s, ii3)::xs
        when Ast.col_of_info ii = 0 ->

        tag ii3 (TypeDef Def);
        aux_toks xs;

    | T.TBang ii1::T.TLowerIdent(s2, ii2)::xs ->
        tag ii2 (UseOfRef);

        aux_toks xs

    | T.TBang ii1::T.TUpperIdent(s, ii)::T.TDot _::T.TLowerIdent(s2, ii2)::xs ->
        tag ii (Module Use);
        tag ii2 (UseOfRef);
        aux_toks xs

    | T.TUpperIdent(s, ii)::T.TDot ii2::T.TUpperIdent(s2, ii3)::xs ->
        tag ii (Module Use);
        aux_toks xs;

    | T.TUpperIdent(s, ii)::T.TDot ii2::T.TLowerIdent(s2, ii3)::xs ->
        
        (* see my .emacs *)
        if Hashtbl.mem h_builtin_modules s then begin
          tag ii BuiltinCommentColor;
          tag ii3 Builtin;
        end else begin
          tag ii (Module Use);
          (* tag ii3 (Function Use); *)
        end;
        aux_toks xs;

    | T.TTilde ii1::T.TLowerIdent (s, ii2)::xs ->
        (* TODO when parser, can also have Use *)
        tag ii1 (Parameter Def);
        tag ii2 (Parameter Def);
        aux_toks xs

    | x::xs ->
        aux_toks xs
  in
  let toks' = toks +> Common.exclude (function
    | T.TCommentSpace _ -> true
    | _ -> false
  )
  in
  aux_toks toks';

  (* -------------------------------------------------------------------- *)
  (* ast phase 1 *) 

  (* -------------------------------------------------------------------- *)
  (* toks phase 2 *)


  toks +> List.iter (fun tok -> 
    match tok with
    | T.TComment ii ->
        if not (Hashtbl.mem already_tagged ii)
        then
          (* a little bit syncweb specific *)
          let s = Ast.str_of_info ii in
          if s =~ "(\\*[sex]:" (* yep, s e x are the syncweb markers *)
          then tag ii CommentSyncweb
          else tag ii Comment

    | T.TCommentMisc ii ->
        tag ii Comment

    | T.TCommentNewline ii | T.TCommentSpace ii 
      -> ()

    | T.TUnknown ii 
      -> tag ii Error
    | T.EOF ii
      -> ()


    | T.TString (s,ii) ->
        tag ii String
    | T.TChar (s, ii) ->
        tag ii String
    | T.TFloat (s,ii) | T.TInt (s,ii) ->
        tag ii Number

    | T.Tfalse ii | T.Ttrue ii -> 
        tag ii Boolean

    | T.Tlet ii | T.Tin ii | T.Tand ii | T.Trec ii 
    | T.Tval ii
    | T.Texternal ii
        -> tag ii TypeVoid (* TODO *)

    | T.Tfun ii | T.Tfunction ii ->
        tag ii TypeVoid (* TODO *)


    | T.Ttype ii
    | T.Tof ii
      -> tag ii TypeMisc (* TODO *)

    | T.Tif ii | T.Tthen ii | T.Telse ii ->
        tag ii KeywordConditional

    | T.Tmatch ii -> (* TODO: should also colorize it's with *)
        tag ii KeywordConditional
    | T.Twhen ii -> (* TODO: should also colorize it's with, when parser *)
        tag ii KeywordConditional

    | T.Ttry ii | T.Twith ii ->
        tag ii KeywordExn

    | T.Tfor ii | T.Tdo ii | T.Tdone ii | T.Twhile ii
    | T.Tto ii
    | T.Tdownto ii
      -> tag ii KeywordLoop

    | T.Tbegin ii | T.Tend ii ->
        tag ii KeywordLoop (* TODO: better categ ? *)


    | T.TBang ii 
    | T.TAssign ii 
    | T.TAssignMutable ii 
      ->
        tag ii KeywordLoop; (* TODO better categ ? *)

    | T.TEq ii

    | T.TSemiColon ii | T.TPipe ii | T.TComma ii

    | T.TOBracket ii | T.TCBracket ii
    | T.TOBrace ii | T.TCBrace ii
    | T.TOParen ii | T.TCParen ii
    | T.TOBracketPipe ii | T.TPipeCBracket ii

    | T.TPlus ii | T.TMinus ii
    | T.TLess ii | T.TGreater ii

    | T.TDot (ii)
    | T.TColon (ii)
        ->
        tag ii Punctuation


    | T.TUpperIdent (s, ii) ->
        if not (Hashtbl.mem already_tagged ii)
        then
          tag ii Constructor

    | T.TLabelDecl (s, ii) ->
        tag ii (Parameter Def)


    | T.Topen ii  ->
        tag ii BadSmell

    | T.Tmodule ii 
    | T.Tstruct ii
    | T.Tsig ii
    | T.Tinclude ii
    | T.Tfunctor ii
        -> tag ii KeywordModule

    | T.Tclass ii
    | T.Tvirtual ii
    | T.Tprivate ii
    | T.Tobject ii
    | T.Tnew ii
    | T.Tmethod ii
    | T.Tinitializer ii
    | T.Tinherit ii
    | T.Tconstraint ii
        -> tag ii KeywordObject

    | T.Tmutable ii
        -> tag ii KeywordLoop

    | T.Tas ii
        -> tag ii Keyword

    | T.Texception ii
        -> tag ii KeywordExn

    | T.Tlazy ii
    | T.Tassert ii

        -> tag ii Keyword

    | T.TUnderscore ii

    | T.TTilde ii

    | T.TStar ii
    | T.TSemiColonSemiColon ii
      -> tag ii Punctuation


    | T.Tland ii 
    | T.Tasr ii
    | T.Tlxor ii
    | T.Tlsr ii
    | T.Tlsl ii
    | T.Tlor ii
    | T.Tmod ii
    | T.Tor ii ->
        tag ii Punctuation

    | T.TSharp ii
    | T.TQuote ii
    | T.TBackQuote ii
    | T.TQuestion ii
    | T.TQuestionQuestion ii

    | T.TDotDot ii
    | T.TColonGreater ii
    | T.TColonColon ii

    | T.TAnd ii
    | T.TAndAnd ii
      -> tag ii Punctuation

    | T.TPrefixOperator (_, ii) ->
        tag ii Operator
    | T.TInfixOperator (_, ii) ->
        tag ii Operator

    | T.TMinusDot ii
    | T.TArrow ii
    | T.TBangEq ii
    | T.TOBracketGreater ii
    | T.TGreaterCBrace ii
    | T.TOBraceLess ii
    | T.TGreaterCBracket ii
    | T.TOBracketLess ii


    | T.TOptLabelUse (_, ii)
    | T.TLabelUse (_, ii)
        -> tag ii (Parameter Def) (* TODO *)

    | T.TOptLabelDecl (_, ii)
        -> tag ii (Parameter Def)

    | T.TLowerIdent (s, ii)
     -> 
        match s with
        | _ when Hashtbl.mem h_pervasives_pad s ->
            tag ii BuiltinCommentColor
        | _ when Hashtbl.mem h_builtin_bool s ->
            tag ii BuiltinBoolean
        | "failwith" | "raise" ->
            tag ii KeywordExn
        | _ ->
            ()


  );

  (* -------------------------------------------------------------------- *)
  (* ast phase 2 *)  

  ()