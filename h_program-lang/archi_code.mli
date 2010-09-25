
type source_archi =
  | Main | Init | Interface 
  | Test | Logging
  | Core  | Utils
  | Constants   
  | Configuration | Building | Doc | Data
  | GetSet   | Ui   | Storage
  | Security 
  | Architecture

  | Ffi | Script
  | ThirdParty  | Legacy 
  | AutoGenerated | BoilerPlate
  | Unittester  | Profiler
  | MiniLite
  | Intern
  | Regular
val source_archi_list: source_archi list

type source_kind =
  | Header
  | Source

val s_of_source_archi: source_archi -> string

(* can tell you about architecture, and also about design pbs *)
val find_duplicate_dirname: Common.dirname -> unit