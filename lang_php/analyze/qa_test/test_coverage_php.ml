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

open Ast_php

module Ast = Ast_php
module V = Visitor_php

module J = Json_type

(*****************************************************************************)
(* Prelude *)
(*****************************************************************************)

(* 
 * We can try to mimic Microsoft Echelon[1] project which given a patch
 * try to run the most relevant tests that could be affected by the
 * patch. It is probably easier in PHP thanks to the excellent xdebug
 * tracer. We can even run the tests and says whether the new code has
 * been covered (like in MySql test infrastructure).
 * 
 * For now we just generate given a mapping from 
 * a source code file to a list of relevant test files. 
 * 
 * See also analyze_php/coverage_(static|dynamic)_php.ml and
 * test_rank.ml which use coverage information too.
 * 
 * You first need to have xdebug ON on your machine. See xdebug.ml
 * For explanations. You can then check if xdebug is on by running 'php -v'.
 * 
 * References:
 *  [1] http://research.microsoft.com/apps/pubs/default.aspx?id=69911
 * 
 *)

(*****************************************************************************)
(* Types *)
(*****************************************************************************)

(* relevant test files exercising source, with term-frequency of 
 * file in the test *)
type tests_coverage = (Common.filename, tests_score) Common.assoc
 and tests_score = (Common.filename * float) list
 (* with tarzan *)

(* used internally by test_coverage below *)
type test_cover_result = 
  | Cover of Common.filename * (* the test *)
      (Common.filename (* source *) * 
       int (* number of occurences in the trace *)) 
      list
  | Problem of Common.filename * string (* error message *)

(* note that xdebug by default does not trace assignements but only 
 * function and method calls, which mean the list of lines returned
 * is an under-approximation.
 *)
type files_coverage = (Common.filename, line_coverage) Common.assoc
 and line_coverage = int list
 (* with tarzan *)

(* In the past lots of tests were failing but we still wanted
 * to generate coverage data. Now, sometimes the codebase is broken which
 * makes all the tests failing but we were still generate an empty coverage
 * data. Better to return an exception when we detected something
 * went wrong.
 *)
let threshold_working_tests_percentage = ref 80.0 

exception NotEnoughWorkingTests

(*****************************************************************************)
(* String of, json, etc *)
(*****************************************************************************)

(* This helps generates a coverage file that 'arc unit' can read *)
let (json_of_tests_coverage: tests_coverage -> J.json_type) = fun cov ->
  J.Object (cov |> List.map (fun (cover_file, tests_score) ->
    cover_file, 
    J.Array (tests_score |> List.map (fun (test_file, score) -> 
      J.Array [J.String test_file; J.String (spf "%.3f" score)]
    ))
  ))

(* todo: should be autogenerated by ocamltarzan *)
let (tests_coverage_of_json: J.json_type -> tests_coverage) = fun j ->
  match j with
  | J.Object (xs) ->
      xs |> List.map (fun (cover_file, tests_score) ->
        cover_file, 
        match tests_score with
        | J.Array zs -> 
            zs |> List.map (fun test_file_score_pair ->
              (match test_file_score_pair with
              | J.Array [J.String test_file; J.String str_score] ->
                  test_file, float_of_string str_score
                    
              | _ -> failwith "Bad json, tests_coverage_of_json"
              )
            )
        | _ ->  failwith "Bad json, tests_coverage_of_json"
      )
  | _ -> failwith "Bad json, tests_coverage_of_json"

(* todo: should be autogenerated by ocamltarzan *)
let (json_of_files_coverage: files_coverage -> J.json_type) = fun cov ->
  J.Object (cov |> List.map (fun (file, lines) -> 
    file, J.Array (lines |> List.map (fun l -> J.Int l))
  ))

let (files_coverage_of_json: J.json_type -> files_coverage) = fun j ->
  match j with
  | J.Object (xs) ->
      xs |> List.map (fun (file, ys) ->
        file, 
        match ys with
        | J.Array zs -> 
            zs |> List.map (function
            | J.Int l -> l
            | _ -> failwith "Bad json, files_coverage_of_json"
            )
        | _ ->  failwith "Bad json, files_coverage_of_json"
      )
  | _ -> failwith "Bad json, files_coverage_of_json"


let (save_tests_coverage: tests_coverage -> Common.filename -> unit) = 
 fun cov file -> 
   cov |> json_of_tests_coverage |> Json_out.string_of_json
   |> Common.write_file ~file

let (load_tests_coverage: Common.filename -> tests_coverage) = 
 fun file ->
   file |> Json_in.load_json |> tests_coverage_of_json


let (save_files_coverage: files_coverage -> Common.filename -> unit) = 
 fun cov file -> 
   cov |> json_of_files_coverage |> Json_out.string_of_json
   |> Common.write_file ~file
   
let (load_files_coverage: Common.filename -> files_coverage) = 
 fun file ->
   file |> Json_in.load_json |> files_coverage_of_json

(*****************************************************************************)
(* Helpers *)
(*****************************************************************************)

(* 
 * To print coverage statistics, we need a base number.
 * Xdebug report in the trace only function/method calls so
 * we need to extract all the possible call sites to have
 * this base number.
 * 
 * note: Xdebug uses the line number of the closing ')' so we do the same here.
 *)
let get_all_calls ?(is_directive_to_filter= (fun _ -> false)) =
  V.do_visit_with_ref (fun aref -> { V.default_visitor with
    V.klvalue = (fun (k,vx) x ->
      match Ast.untype x with
      | FunCallSimple (callname, (lp, args, rp)) ->
          let str = Ast_php.name callname in
          
          (* filter the require_module stuff that already skip
           * when generating the file coverage data
           *)
          if is_directive_to_filter str then ()
          else
            Common.push2 (Some str, rp) aref;

          k x
      | MethodCallSimple (var, t1, methname, (lp, args, rp)) ->
          let str = Ast_php.name methname in
          Common.push2 (Some str, rp) aref;
          k x

      | StaticMethodCallSimple (qu, methname, (lp, args, rp)) ->
          let str = Ast_php.name methname in
          Common.push2 (Some str, rp) aref;
          k x

      | _ -> 
          k x
    );
    V.kexpr = (fun (k, vx) x ->
      match Ast.untype x with
      | New (tok, class_name_ref, args_opt) ->
          (* can not use ')' here, so use the token for new *)
          Common.push2 (None, tok) aref;

          k x;
      | _ -> k x
    );
  })

let get_all_call_lines_with_sanity_check 
     ?is_directive_to_filter file lines_covered =

  (* don't know why but sometimes 0 is in the trace *)
  let lines_covered = lines_covered |> Common.exclude (fun x -> x = 0) in
      
  let nb_lines_covered = List.length lines_covered in
      
  let ast = 
    try Parse_php.parse_program file 
    with
    exn ->
      pr2 (spf "PB: cant parse %s" file);
      []
  in
      
  let calls = get_all_calls ?is_directive_to_filter
    (fun v ->  v.V.vprogram ast) in
      
  let lines_calls = 
    calls 
    +> List.map (fun (sopt, rp) -> Ast.line_of_info rp)
    +> Common.set
  in
  let nb_lines_calls = List.length lines_calls in
      
  (* first sanity check *)
  if nb_lines_calls < nb_lines_covered
    (* apparently php scripts have wrong line nunber information with 
     * xdebug
     *)
    && not (Lib_parsing_php.is_php_script file)
  then begin 
    pr2 ("PB: xdebug reported more calls than there is in " ^ file);
    
    let diff = 
      lines_covered $-$ lines_calls 
    in
    let lines = 
      try 
        Common.cat_excerpts file diff
      with
      exn -> [Common.exn_to_s exn]
    in
    lines |> List.iter pr2;
    pr2 "PB: fix get_all_calls";
    
  end;
  (* TODO: second sanity check, check that talk about same lines ? *)
  lines_calls
 

(*****************************************************************************)
(* Main entry points *)
(*****************************************************************************)

(* algo:
 *  - get set of test files in testdir 
 *  - get the corresponding command to run the test
 *  - run the test with xdebug on (in light mode)
 *  - filter only working tests (don't want to blame a committer for
 *    an error made by someone else)
 *  - analyze the trace to extract file coverage
 *  - do global analysis to return for all sources the set of 
 *    relevant tests (can also be used to detect code that is not
 *    covered at all)
 *  - rank the relevant tests (using term frequency, if a file is mentionned
 *    a lot in the trace of a test, then this test is more relevant to the
 *    file)
 *  - generate JSON data so that other program can use this information
 *    (e.g. 'arc unit')
 * 
 *  - optional: parallelize and distribute the computation with MPI
 *)
let coverage_tests 
 ?(phpunit_parse_trace = Phpunit.parse_one_trace)
 ?(skip_call = (function call -> false))
 ~php_cmd_run_test
 ~all_test_files
 ()
 = 

  (* I am now using commons/distribution.ml and the map_reduce function
   * to possibly distribute the coverage computation using MPI. Note that the
   * same program can also be used without MPI, so that all the
   * distribution/parallelisation is mostly transparent to the
   * programmer (thanks to commons/distribution.ml) *)

  (* Note that the MPI workers are started only when the code 
   * reach Distribution.map_reduce below, which means that if the 
   * program crash before, the MPI infrastructure would have not been
   * started yet and you will see no useful error output.
   * So limit the amount of code to run before the map_reduce call.
   *)

  let test_files_fn () = 
    pr2 "computing set of test files";
    let xs = all_test_files () in
    pr2 (spf "%d test files found" (List.length xs));
    xs
  in

  (* using a map reduce model *)
  let (mapper: filename -> test_cover_result) = fun test_file ->
    try (
    pr2 (spf "processing: %s" test_file);

    if not (Xdebug.php_has_xdebug_extension ())
    then failwith "xdebug is not properly installed";

    (* run with xdebug tracing in a "light" mode, which have less information, 
     * but which generate small traces and so leads to faster trace analysis.
     *)
    let config = { Xdebug.default_config with
      Xdebug.collect_return = false;
      Xdebug.collect_params = Xdebug.NoParam;
    }
    in

    let trace_file = Common.new_temp_file "xdebug" ".xt" in
    let php_interpreter = 
      Xdebug.php_cmd_with_xdebug_on ~trace_file ~config () in
    let cmd = php_cmd_run_test ~php_interpreter test_file in
    pr2 (spf "executing: %s" cmd);
    let output_cmd = 
      Common.profile_code "Run PHP tests" (fun () ->
        Common.timeout_function 100 (fun () ->
          Common.cmd_to_list cmd 
        )
      )
    in
    let test_result = 
      phpunit_parse_trace test_file output_cmd in

    match test_result.Phpunit.t_status with
    | Phpunit.Pass _ -> 

        let h = Common.hash_with_default (fun () -> 0) in


        pr2 (spf " trace length = %d lines, xdebug trace = %d lines" 
                (List.length output_cmd)
                (Common.nblines_with_wc trace_file)
        );

        trace_file +> Xdebug.iter_dumpfile 
          ~config 
          ~show_progress:false
          ~fatal_when_exn:true
          (fun call ->
            if skip_call call then ()
            else
              let file_called = call.Xdebug.f_file in 
              h#update file_called (fun old -> old + 1)
          );
        Cover (test_file, h#to_list)
    | Phpunit.Fail _ | Phpunit.Fatal _ -> 
        (* I should normally print the failing test output, 
         * but some tests generates really weird binary output
         * that makes OCaml raise a Sys_blocked_io exception.
         * 
         * old: output_cmd |> List.iter pr2; 
         *)
        Problem (test_file, "failing or fataling test")
    )
   with Timeout ->
     pr2 (spf "PB with %s" test_file);
     Problem (test_file, "timeout when running test and computing coverage")
  in

  (* regular_php_file -> hash_of_relevant_test_files_with_score *)
  let h = Common.hash_with_default (fun () -> 
    Hashtbl.create 101
  )
  in
  let ok_test_files = ref 0 in
  let pb_test_files = ref [] in

  (* Right now the reducer is executed on a single machine, the master,
   * so I can (ab)use the 2 preceding globals. See the code in
   * distribution.ml.
   *)
  let reducer _acc test_cover_result = 
    match test_cover_result with
    | Cover (test_file, files_called) ->
        let total = files_called |> List.map snd |> Common.sum in
        files_called |> List.iter (fun (file_called, nb_occurences) ->
          h#update file_called (fun hbis -> 
            Hashtbl.replace hbis test_file 
              (* "term" frequency *)
              (Common.pourcent_float nb_occurences total);
            hbis
          );
        );
        incr ok_test_files;
    | Problem (test_file, msg) -> 
        Common.push2 (test_file, msg) pb_test_files;
  in
  let _res, not_done = 
    Features.Distribution.map_reduce_lazy 
      ~fmap:mapper ~freduce:reducer () test_files_fn
  in
  not_done |> List.iter (fun test_file ->
    Common.push2 (test_file, "MPI error, see the full log") pb_test_files;
  );

  pr2 "test dependencies";
  let coverage = 
    h#to_list |> Common.map (fun (source_file, h) ->
      let tests = h 
      |> Common.hash_to_list 
      |> Common.sort_by_val_highfirst
      in
      (source_file, tests)
    )
  in

  (* error report *)
  !pb_test_files |> List.rev |> List.iter (fun (test_file, error) ->
    pr2 (spf "PB with %s, \n\t%s" test_file error);
  );
  let good = !ok_test_files in
  let bad = List.length (!pb_test_files) in
  let total = good + bad in
  let percent = Common.pourcent_float good total in
  pr2 (spf "Coverage: %d/%d tests (%.02f%%)" 
          good total percent);

  if percent < !threshold_working_tests_percentage
  then raise NotEnoughWorkingTests;

  coverage, !pb_test_files
    



(* For precise file/line coverage it does make less sense to use a map/reduce
 * model and distribute computations as we need to produce a global
 * file->covered_lines assoc, which would force in each mapper to 
 * produce such an assoc and then in the reducer to unionize them which
 * would be costly. We really need a global here.
 *)

let files_coverage_from_tests
 ?(skip_call = (function call -> false))
 ~php_cmd_run_test
 ~all_test_files
 ()
 = 
  (* file -> hashset of lines *)
  let h = Common.hash_with_default (fun () -> 
    Hashtbl.create 101
  ) in

  all_test_files () |> List.iter (fun test_file ->

   try (
    pr2 (spf "processing: %s" test_file);

    if not (Xdebug.php_has_xdebug_extension ())
    then failwith "xdebug is not properly installed";

    (* run with xdebug tracing in a "light" mode, which have less information, 
     * but which generate small traces and so leads to faster trace analysis.
     *)
    let config = { Xdebug.default_config with
      Xdebug.collect_return = false;
      Xdebug.collect_params = Xdebug.NoParam;
    }
    in

    let trace_file = Common.new_temp_file "xdebug" ".xt" in
    let php_interpreter = 
      Xdebug.php_cmd_with_xdebug_on ~trace_file ~config () in
    let cmd = php_cmd_run_test ~php_interpreter test_file in
    pr2 (spf "executing: %s" cmd);

    let output_cmd = 
      Common.profile_code "Run PHP tests" (fun () ->
        Common.timeout_function 100 (fun () ->
          Common.cmd_to_list cmd 
        )
      )
    in
    pr2 (spf " trace length = %d lines, xdebug trace = %d lines" 
            (List.length output_cmd)
            (Common.nblines_with_wc trace_file)
    );

    trace_file +> Xdebug.iter_dumpfile 
      ~config 
      ~show_progress:false
      ~fatal_when_exn:true
      (fun call ->
        if skip_call call then ()
        else begin
          let file_called = call.Xdebug.f_file in 

          if not (Sys.file_exists file_called)
          then failwith 
            (spf "WEIRD: coverage contain reference to weird file: '%s'" 
                file_called);

          (* todo: could assert that line is < wc_line ? *)
          let line = call.Xdebug.f_line in
          
          h#update file_called (fun oldh -> 
            Hashtbl.replace oldh line true; 
            oldh
          )
        end
      );
    )
   with Timeout ->
     pr2 (spf "PB with %s, timeout" test_file);
  );
  h#to_list |> List.map (fun (file, hset) -> 
    file, Common.hashset_to_list hset
  )




(*****************************************************************************)
(* Actions *)
(*****************************************************************************)

let actions () = [

  (* can test via 
   *    mpirun -np 5 ./qa_test -debug_mpi -test_mpi
   * for local multi processing, or 
   *    mpirun -np 20 -H unittest006,unittest005 ./qa_test -debug_mpi -test_mpi
   * for distributed processing, or simply with
   *    ./qa_test -test_mpi 
   * for local classic ocaml single processing
   *)
  "-test_mpi", "",
  Common.mk_action_0_arg (fun () ->
    let rec fib n = 
      if n = 0 then 0
      else 
        if n = 1 then 1
      else fib (n-1) + fib (n-2)
    in
    let map_ex arg = 
      pr (spf "map: %d" arg);
      fib arg
    in
    let reduce_ex acc e = 
      pr (spf "reduce: acc=%d, e=%d" acc e);
      acc + e
    in
    let res, notdone = 
      Features.Distribution.map_reduce ~fmap:map_ex ~freduce:reduce_ex 
      0 [35;35;35;35] in
    pr (spf "result = %d, #not_done = %d" res (List.length notdone));
  );
]

(*****************************************************************************)
(* Unit test *)
(*****************************************************************************)
open OUnit

(* The test coverage analysis of pfff we do for facebook depends on
 * multiple components:
 * - xdebug, and our ocaml binding to the runner and trace format
 * - phpunit, and our ocaml binding to the runner and result format
 * - some facebook extensions to phpunit and the way we run tests
     * - some facebook specificities because of flib
 * - the way we run php (zend or hphp)
 * - MPI
 * 
 * If we want to unit tests, we need to remove from the equations a few
 * things. For instance we can get a trace without having to conform to
 * phpunit or to the test runner scripts we use by having
 * the coverage analysis function taking the specifics as 
 * parameters. So here we go into different steps:
 *  - first bypass almost everything (the conformance to phpunit, 
 *    to our test infrastructure), and instead just execute php code
 *    under xdebug with the basic php interpreter.
 *  - TODO introduce phpunit, and the fact that we bypass failing tests
 *  - TODO introduce facebook specificities
 *)

(* shortcut *)
let p f = realpath (Config.path ^ "/tests/coverage/" ^ f)

(* mocking *)
let fake_phpunit_parse_trace file _output = {
      Phpunit.t_file = file;
      t_status = Phpunit.Pass 1;
      t_time = 0;
      t_memory = 0.0;
      t_shimmed = 0;
      t_trace_nb_lines = 0;
}

(* normally we need to include the command of a test runner,
 * such as bin/phpunit, but here we don't even use phpunit.
 * Just raw call to php *)
let fake_php_cmd_run_test ~php_interpreter file = 
  spf "%s %s" php_interpreter file


let unittest = "coverage_php" >::: [

  (* Here we test the correctness of the the basic coverage algorithm 
   * and xdebug trace analysis. The test data is in tests/coverage.
   * It is mainly 2 sources file, a.php and b.php doing each 
   * a loop to print a character 1000 times. Those 2 files are
   * exercised by tests in the same directory, and whose name,
   * e.g. t1_a.php explains which files they use.
   *)
  "simple coverage" >:: (fun () ->

    let all_test_files () = 
      [ p "t1_a.php";
        p "t2_b.php";
        p "t3_a_b.php";
      ]
    in

    let cover, pbs = 
      coverage_tests 
        ~all_test_files
        ~php_cmd_run_test:fake_php_cmd_run_test
        ~phpunit_parse_trace:fake_phpunit_parse_trace
        ()
    in
    let json = json_of_tests_coverage cover in
    let s = Json_out.string_of_json json in
    pr s;

    assert_equal [] pbs;

    let cover_a = List.assoc (p "a.php") cover in
    let cover_b = List.assoc (p "b.php") cover in

    assert_equal [p "t1_a.php"; p "t3_a_b.php"] (Common.keys cover_a);
    assert_equal [p "t2_b.php"; p "t3_a_b.php"] (Common.keys cover_b);

    (* Right now if a function calls another function in a loop, then
     * those functions calls will occcur a lot in the trace, which
     * currently will bias our coverage ranking to favor such case.
     * 
     * todo? maybe should remember which lines were covered so that
     * we favor not code with loop but code whose lines are
     * all exercised by a test.
     *)
        assert_bool 
          "t1_a.php exercises a lot a.php; score should be high"
          (List.assoc (p "t1_a.php") cover_a > 90.0); 

        assert_bool 
          "t3_a_b.php calls a() 2x times more than b(), score of a should be higher"
          (List.assoc (p "t3_a_b.php") cover_a > 
          List.assoc (p "t3_a_b.php") cover_b ); 
  );


  (* We don't want to include in the coverage tests that exercise
   * a file only through include or certain calls such as 
   * require_module()
   *)
  "coverage skipping calls" >:: (fun () ->

    let all_test_files () = [ 
      p "t4_only_require.php";
      p "t5_not_just_require.php";
    ]
    in
    let skip_require_module_calls call = 
      match call.Xdebug.f_call with
      | Callgraph_php.FunCall "require_module" -> true
      | _ -> false
    in

    let cover, pbs = 
      coverage_tests 
        ~all_test_files
        ~php_cmd_run_test:fake_php_cmd_run_test
        ~phpunit_parse_trace:fake_phpunit_parse_trace
        ~skip_call:skip_require_module_calls
        ()
    in
    let json = json_of_tests_coverage cover in
    let s = Json_out.string_of_json json in
    pr s;

    assert_equal [] pbs;
    let cover_require_ex = List.assoc (p "require_ex.php") cover in
    

    assert_bool 
      "t4_only_require.php should not cover require_ex.php"
      (not (List.mem_assoc (p "t4_only_require.php") cover_require_ex)); 
    
    assert_bool 
      "t5_not_just_require.php should cover require_ex.php"
      (List.mem_assoc (p "t5_not_just_require.php") cover_require_ex); 

  );

  "coverage and json input output" >:: (fun () ->
    assert_bool
      "should parse good_trace.json"
      (let _ = load_tests_coverage (p "good_trace.json") in true);
    assert_bool
      "should generate exn on bad_trace.json"
      (try let _ = load_tests_coverage (p "bad_trace.json") in false
       with exn -> true
      );
  );
]
