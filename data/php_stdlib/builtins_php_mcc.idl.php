<?php
// THIS IS AUTOGENERATED BY builtins_php.ml
define('MCC_IPPROTO_TCP', 0);
define('MCC_IPPROTO_UDP', 0);
define('MCC_SERVER_UP', 0);
define('MCC_SERVER_DOWN', 0);
define('MCC_SERVER_DISABLED', 0);
define('MCC_SERVER_RETRY_TMO_MS', 0);
define('MCC_DGRAM_TMO_THRESHOLD', 0);
define('MCC_PORT_DEFAULT', 0);
define('MCC_POOLPREFIX_LEN', 0);
define('MCC_MTU', 0);
define('MCC_RXDGRAM_MAX', 0);
define('MCC_CONN_TMO_MS', 0);
define('MCC_CONN_NTRIES', 0);
define('MCC_DGRAM_NTRIES', 0);
define('MCC_DGRAM_TMO_WEIGHT', 0);
define('MCC_NODELAY', 0);
define('MCC_POLL_TMO_US', 0);
define('MCC_PROXY_DELETE_OP', 0);
define('MCC_PROXY_UPDATE_OP', 0);
define('MCC_PROXY_ARITH_OP', 0);
define('MCC_PROXY_GET_OP', 0);
define('MCC_TMO_MS', 0);
define('MCC_UDP_REPLY_PORTS', 0);
define('MCC_WINDOW_MAX', 0);
define('MCC_HAVE_FB_SERIALIZATION', 0);
define('MCC_ARG_FB_SERIALIZE_ENABLED', 0);
define('MCC_ARG_CONSISTENT_HASHING_PREFIXES', 0);
define('MCC_HAVE_DEBUG_LOG', 0);
define('MCC_ARG_DEBUG', 0);
define('MCC_ARG_DEBUG_LOGFILE', 0);
define('MCC_HAVE_ZLIB_COMPRESSION', 0);
define('MCC_COMPRESSION_THRESHOLD', 0);
define('MCC_ARG_SERVERS', 0);
define('MCC_ARG_MIRROR_CFG', 0);
define('MCC_ARG_MIRROR_CFG_NAME', 0);
define('MCC_ARG_MIRROR_CFG_MODEL', 0);
define('MCC_ARG_MIRROR_CFG_SERVERPOOLS', 0);
define('MCC_ARG_COMPRESSION_THRESHOLD', 0);
define('MCC_ARG_NZLIB_COMPRESSION', 0);
define('MCC_ARG_QUICKLZ_COMPRESSION', 0);
define('MCC_ARG_SNAPPY_COMPRESSION', 0);
define('MCC_ARG_CONN_TMO', 0);
define('MCC_ARG_CONN_NTRIES', 0);
define('MCC_ARG_DEFAULT_PREFIX', 0);
define('MCC_ARG_DELETE_PROXY', 0);
define('MCC_ARG_DGRAM_NTRIES', 0);
define('MCC_ARG_DGRAM_TMO_WEIGHT', 0);
define('MCC_ARG_NODELAY', 0);
define('MCC_ARG_PERSISTENT', 0);
define('MCC_ARG_POLL_TMO', 0);
define('MCC_ARG_PROXY', 0);
define('MCC_ARG_PROXY_OPS', 0);
define('MCC_ARG_TMO', 0);
define('MCC_ARG_TCP_INACTIVITY_TIME', 0);
define('MCC_ARG_NPOOLPREFIX', 0);
define('MCC_TCP_INACTIVITY_TMO_DEFAULT', 0);
define('MCC_ARG_UDP_REPLY_PORTS', 0);
define('MCC_ARG_WINDOW_MAX', 0);
define('MCC_CONSISTENCY_IGNORE', 0);
define('MCC_CONSISTENCY_MATCH_ALL', 0);
define('MCC_CONSISTENCY_MATCH_HITS', 0);
define('MCC_CONSISTENCY_MATCH_HITS_SUPERCEDES', 0);
define('MCC_ARG_SERVER_RETRY_TMO_MS', 0);
define('MCC_ARG_DGRAM_TMO_THRESHOLD', 0);
define('MCC_ARG_RANDOMIZE_APS', 0);
define('MCC_ARG_PREFER_FIRST_AP', 0);
define('MCC_GET_RECORD_ERRORS', 0);
define('MCC_HAVE_LEASE_SET_GET', 0);
define('MCC_DELETE_DELETED', 0);
define('MCC_DELETE_NOTFOUND', 0);
define('MCC_DELETE_ERROR_LOG', 0);
define('MCC_DELETE_ERROR_NOLOG', 0);
define('PHPMCC_NEW_HANDLE', 0);
define('PHPMCC_USED_FAST_PATH', 0);
define('PHPMCC_USED_SLOW_PATH', 0);
//pad: defined already
//define('PHPMCC_VERSION', 0);
class phpmcc {
const IPPROTO_TCP = 0;
const IPPROTO_UDP = 0;
const LEASE_TOKEN_ALWAYS_ACCEPT = 0;
const LEASE_TOKEN_NEVER_ACCEPT = 0;
const LEASE_TOKEN_HOT_MISS = 0;
const LEASE_GET_HIT = 0;
const LEASE_GET_MISS = 0;
const LEASE_GET_HOT_MISS = 0;
const LEASE_GET_UNKNOWN = 0;
const DETAILED_GET_UNKNOWN = 0;
const DETAILED_GET_HIT = 0;
const DETAILED_GET_MISS = 0;
const DETAILED_GET_HOT_MISS = 0;
const DETAILED_GET_ERR_OOO = 0;
const DETAILED_GET_ERR_TIMEOUT = 0;
const DETAILED_GET_ERR_ABORTED = 0;
const DETAILED_GET_ERR_LOCAL = 0;
const DETAILED_GET_ERR_REMOTE = 0;
const DETAILED_GET_ERR_BAD_KEY = 0;
const DETAILED_GET_ERR_BAD_VALUE = 0;
const DETAILED_GET_ERR_CONN = 0;
const DETAILED_GET_WAITING = 0;
 function __construct($name, $persistent = true, $npoolprefix = k_MCC_POOLPREFIX_LEN, $mtu = k_MCC_MTU, $rxdgram_max = k_MCC_NODELAY, $nodelay = k_MCC_CONN_TMO_MS, $conn_tmo = k_MCC_CONN_TMO_MS, $conn_ntries = k_MCC_CONN_NTRIES, $tmo = k_MCC_TMO_MS, $dgram_ntries = k_MCC_DGRAM_NTRIES, $dgram_tmo_weight = k_MCC_DGRAM_TMO_WEIGHT, $server_retry_tmo = k_MCC_SERVER_RETRY_TMO_MS, $dgram_tmo_threshold = k_MCC_DGRAM_TMO_THRESHOLD, $window_max = k_MCC_WINDOW_MAX) { }
 function __destruct() { }
 function __tostring() { }
 function __set($name, $val) { }
 function __get($name) { }
 function close() { }
 function del() { }
 function add_accesspoint($server, $host, $port = "11211", $protocol = k_MCC_IPPROTO_TCP) { }
 function remove_accesspoint($server, $host, $port = "11211", $protocol = k_MCC_IPPROTO_TCP) { }
 function get_accesspoints($server) { }
 function get_server($server) { }
 function add_mirror_accesspoint($mirrorname, $server, $host, $port = "11211", $protocol = k_MCC_IPPROTO_TCP) { }
 function remove_mirror_accesspoint($mirrorname, $server, $host, $port = "11211", $protocol = k_MCC_IPPROTO_TCP) { }
 function add_server($server, $mirror = "") { }
 function remove_server($server, $mirror = "") { }
 function server_flush($server, $exptime = 0) { }
 function server_version($server = "") { }
 function server_is_alive($server = "") { }
 function test_proxy($server = "") { }
 function add_mirror($mirrorname, $model) { }
 function remove_mirror($mirrorname) { }
 function add_serverpool($serverpool, $consistent_hashing_enabled = false) { }
 function add_serverpool_ex($serverpool, $version_flag) { }
 function remove_serverpool($serverpool) { }
 function add_accesspoint_listener($function, &$context) { }
 function remove_accesspoint_listener($function, &$context) { }
 function add_server_listener($function, &$context) { }
 function remove_server_listener($function, &$context) { }
 function add_error_listener($function, &$context) { }
 function remove_error_listener($function, &$context) { }
 function get_server_by_key($key) { }
 function get_host($key) { }
 function get_serverpool_by_key($key) { }
 function serverpool_add_server($serverpool, $server, $mirrorname = "") { }
 function serverpool_remove_server($serverpool, $server, $mirrorname = "") { }
 function serverpool_get_servers($serverpool) { }
 function serverpool_get_consistent_hashing_enabled($serverpool) { }
 function serverpool_get_consistent_hashing_version($serverpool) { }
 function multi_add($keys_values, $exptime = 0, $compress = 1, $proxy_replicate = 0, $async_set = 0) { }
 function multi_replace($keys_values, $exptime = 0, $compress = 1, $proxy_replicate = 0, $async_set = 0) { }
 function multi_set($keys_values, $exptime = 0, $compress = 1, $proxy_replicate = 0, $async_set = 0) { }
 function multi_lease_set($keys_value_tokens, $exptime = 0, $compress = 1, $proxy_replicate = 0, $async_set = 0) { }
 function add($key, $value, $exptime = 0, $compress = true, $proxy_replicate = 0, $async_set = 0) { }
 function decr($key, $value = 1) { }
 function incr($key, $value = 1) { }
 function delete($keys, $exptime = 0, $local = 0) { }
 function delete_details($keys, $exptime = 0, $local = 0) { }
 function get($keys, $detailed_info_mode = 0, &$detailed_info = null) { }
 function lease_get($keys, $detailed_info_mode = 0, &$detailed_info = null) { }
 function detailed_get($keys, $is_lease = true) { }
 function get_multi($keys, $detailed_info_mode = 0, &$detailed_info = null) { }
 function lease_get_multi($keys, $detailed_info_mode = 0, &$detailed_info = null) { }
 function replace($key, $value, $exptime = 0, $compress = true, $proxy_replicate = 0, $async_set = 0) { }
 function set($key, $value, $exptime = 0, $compress = true, $proxy_replicate = 0, $async_set = 0) { }
 function lease_set($key, $value_lease, $exptime = 0, $compress = true, $proxy_replicate = 0, $async_set = 0) { }
 function stats($clear = 0) { }
 function metaget($key) { }
 function get_mcc_version() { }
}
