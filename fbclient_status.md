[back](fbclient.md)

## Changelog ##

  * [v2.0](http://lua-files.org/wiki/fbclient) - complete rewrite: simplified codebase and API, based on LuaJIT ffi interface
  * [v0.5](http://code.google.com/p/fbclient/) - 3-layer API, based on alien

## API features ##

  * design:
    * binding to multiple fbclient libraries (useful for connecting to both embedded server and a remote server at the same time)
    * no shared state for lock-free multi-threading
  * databases:
    * `CREATE DATABASE` command
    * attachment options
      * force trusted authentication (fb 2.0+)
    * info function
      * db creation date (fb 2.0+)
      * list of active transactions (fb 1.5+)
      * get raw contents of any database page (fb 2.5+)
    * asynchronous request cancellation (fb 2.5+)
  * transactions:
    * multi-database transactions
    * `SET TRANSACTION` command
    * commit-retaining and rollback-retaining commands
    * table reservation options
    * lock timeout option (fb 2.0+)
    * info function
  * statements:
    * prepared statements
    * unprepare function (fb 2.5+)
    * named cursors
    * column and parameter descriptions: datatype, relation/sql/own/alias names
    * info function
      * statement type
      * execution plan
      * affected row counts
  * data types:
    * fractions of a second with 0.1ms accuracy for TIME and TIMESTAMP types
    * 15 full digits of precision with only Lua numbers
    * bignum library bindings for working with 16-18 digit numbers
    * segmented blobs and blob streams
      * blob filters (untested)
      * blob info function
  * service manager API:
    * attachment options:
      * force trusted authentication (fb 2.0+)
    * server info (version, capabilities, list of connected databases)
    * get server's logfile contents
    * get statistics about a database (gstat functionality)
      * gstat'ing only one table (not implemented)
    * full backup & restore (gbak functionality)
    * incremental backup & restore (nbackup functionality; fb 2.5+)
    * database check, repair, sweep, mend, set header fileds (gfix functionality)
    * bring a database offline and back online or switch to shadow file (gfix functionality)
    * user management (gsec functionality)
      * allow working on multiple security databases (fb 2.5+)
    * trace API (fb 2.5+)
    * `RDB$ADMIN` role mapping (fb 2.5+)
  * error API
    * support for sqlcode, sqlcode interpretation and error traceback
    * updated list of isc error messages to help in case of missing `firebird.msg`
    * SQL-2003 compliant `SQLSTATE` code (fb 2.5+)

## TODO ##
  * events support
  * user-described xsqlvars for parametrized dsql\_execute\_immediate(), db\_create\_sql() and tr\_start\_sql()
  * test db\_cancel\_operation()
  * bind and test fb\_shutdown() and fb\_shutdown\_callback()
  * gstat'ing only one table
  * test blob filters
  * marinate neptunian slug for dinner
  * kill all humans

### Rare, obscure or obsolete features ###
  * arrays (anyone use them?)
  * blob filters (anyone use them?)
  * ancient dialects 1 and 2 (anyone still using those?)
  * test with Firebird 1.5 (you really should upgrade)
  * research, document and test following obscure tags:
    * SPB: `isc_spb_sts_table, isc_spb_res_length, isc_spb_bkp_expand`
    * BPB: `isc_bpb_filter_parameter, isc_bpb_source_type, isc_bpb_target_type, isc_bpb_source_interp, isc_bpb_target_interp`
    * DB\_INFO: `isc_info_set_page_buffers, isc_info_db_file_size`
    * SQL\_INFO: `isc_info_sql_select, isc_info_sql_bind, isc_info_sql_num_variables, isc_info_sql_describe_vars`, full list unknown.
  * test limbo transactions: service manager (list & repair), DB\_INFO (list), TPB (ignore\_limbo, no\_auto\_undo)
  * decode the status vector

### Hi-level features ###
  * named parameters -- firebird should provide this (requires sql parsing)
  * batch scripts -- firebird should provide this (requires sql parsing)
  * parsing of SQL plan text to a tree structure (format not standardized)
  * parsing the log file contents to table
  * parsing the db\_stats text dump to table
  * parsing the database version string to table

### Tools ###
  * schema (metadata) class with DDL generation and schema comparison between two databases, and an SQL data export function
  * a GUI frontend for the tracing API


## Authors ##

  * Cosmin Apreutesei

## Contributors ##

  * Ann W. Harrison (help with undocumented PB & INFO tags)
  * Alexander Peshkoff (help with undocumented PB & INFO tags)
  * Dmitry Yemanov (help with undocumented PB & INFO tags)