
(* Returns the testsuite for parsing_ml/. To be concatenated by 
 * the caller (e.g. in pfff/main_test.ml ) with other testsuites and 
 * run via OUnit.run_test_tt 
 *)
val unittest: OUnit.test

val actions : unit -> Common.cmdline_actions

