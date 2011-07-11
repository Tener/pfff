<?php
// THIS IS AUTOGENERATED BY builtins_php.ml
define('UCOL_DEFAULT', 0);
define('UCOL_PRIMARY', 0);
define('UCOL_SECONDARY', 0);
define('UCOL_TERTIARY', 0);
define('UCOL_DEFAULT_STRENGTH', 0);
define('UCOL_QUATERNARY', 0);
define('UCOL_IDENTICAL', 0);
define('UCOL_OFF', 0);
define('UCOL_ON', 0);
define('UCOL_SHIFTED', 0);
define('UCOL_NON_IGNORABLE', 0);
define('UCOL_LOWER_FIRST', 0);
define('UCOL_UPPER_FIRST', 0);
define('UCOL_FRENCH_COLLATION', 0);
define('UCOL_ALTERNATE_HANDLING', 0);
define('UCOL_CASE_FIRST', 0);
define('UCOL_CASE_LEVEL', 0);
define('UCOL_NORMALIZATION_MODE', 0);
define('UCOL_STRENGTH', 0);
define('UCOL_HIRAGANA_QUATERNARY_MODE', 0);
define('UCOL_NUMERIC_COLLATION', 0);
function array_change_key_case($input, $upper = false) { }
function array_chunk($input, $size, $preserve_keys = false) { }
function array_combine($keys, $values) { }
function array_count_values($input) { }
function array_fill_keys($keys, $value) { }
function array_fill($start_index, $num, $value) { }
function array_filter($input, $callback = null_variant) { }
function array_flip($trans) { }
function array_key_exists($key, $search) { }
function key_exists($key, $search) { }
function array_keys($input, $search_value = null_variant, $strict = false) { }
function array_map($callback, $arr1) { func_get_args();}
function array_merge_recursive($array1) { func_get_args();}
function array_merge($array1) { func_get_args();}
function array_replace_recursive($array1) { func_get_args();}
function array_replace($array1) { func_get_args();}
function array_multisort(&$ar1) { func_get_args();}
function array_pad($input, $pad_size, $pad_value) { }
function array_pop(&$array) { }
function array_product($array) { }
function array_push(&$array, $var) { func_get_args();}
function array_rand($input, $num_req = 1) { }
function array_reduce($input, $callback, $initial = null_variant) { }
function array_reverse($array, $preserve_keys = false) { }
function array_search($needle, $haystack, $strict = false) { }
function array_shift(&$array) { }
function array_slice($array, $offset, $length = null_variant, $preserve_keys = false) { }
function array_splice(&$input, $offset, $length = null_variant, $replacement = null_variant) { }
function array_sum($array) { }
function array_unique($array, $sort_flags = 2) { }
function array_unshift(&$array, $var) { func_get_args();}
function array_values($input) { }
function array_walk_recursive(&$input, $funcname, $userdata = null_variant) { }
function array_walk(&$input, $funcname, $userdata = null_variant) { }
function compact($varname) { func_get_args();}
function shuffle(&$array) { }
function count($var, $recursive = false) { }
function sizeof($var, $recursive = false) { }
function each(&$array) { }
function current(&$array) { }
function hphp_current_ref(&$array) { }
function next(&$array) { }
function pos(&$array) { }
function prev(&$array) { }
function reset(&$array) { }
function end(&$array) { }
function key(&$array) { }
function hphp_get_iterator($iterable) { }
function hphp_get_mutable_iterator(&$iterable) { }
function in_array($needle, $haystack, $strict = false) { }
function range($low, $high, $step = 1) { }
function array_diff($array1, $array2) { func_get_args();}
function array_udiff($array1, $array2, $data_compare_func) { func_get_args();}
function array_diff_assoc($array1, $array2) { func_get_args();}
function array_diff_uassoc($array1, $array2, $key_compare_func) { func_get_args();}
function array_udiff_assoc($array1, $array2, $data_compare_func) { func_get_args();}
function array_udiff_uassoc($array1, $array2, $data_compare_func, $key_compare_func) { func_get_args();}
function array_diff_key($array1, $array2) { func_get_args();}
function array_diff_ukey($array1, $array2, $key_compare_func) { func_get_args();}
function array_intersect($array1, $array2) { func_get_args();}
function array_uintersect($array1, $array2, $data_compare_func) { func_get_args();}
function array_intersect_assoc($array1, $array2) { func_get_args();}
function array_intersect_uassoc($array1, $array2, $key_compare_func) { func_get_args();}
function array_uintersect_assoc($array1, $array2, $data_compare_func) { func_get_args();}
function array_uintersect_uassoc($array1, $array2, $data_compare_func, $key_compare_func) { func_get_args();}
function array_intersect_key($array1, $array2) { func_get_args();}
function array_intersect_ukey($array1, $array2, $key_compare_func) { func_get_args();}
function sort(&$array, $sort_flags = 0, $use_collator = false) { }
function rsort(&$array, $sort_flags = 0, $use_collator = false) { }
function asort(&$array, $sort_flags = 0, $use_collator = false) { }
function arsort(&$array, $sort_flags = 0, $use_collator = false) { }
function ksort(&$array, $sort_flags = 0) { }
function krsort(&$array, $sort_flags = 0) { }
function usort(&$array, $cmp_function) { }
function uasort(&$array, $cmp_function) { }
function uksort(&$array, $cmp_function) { }
function natsort(&$array) { }
function natcasesort(&$array) { }
function i18n_loc_get_default() { }
function i18n_loc_set_default($locale) { }
function i18n_loc_set_attribute($attr, $val) { }
function i18n_loc_set_strength($strength) { }
function i18n_loc_get_error_code() { }
