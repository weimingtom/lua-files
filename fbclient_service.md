

## Introduction ##

Firebird allows privileged users to connect to a remote server and perform administrative tasks via its Service Manager interface.

## Connect to a Service Manager ##

### `fb.connect_service(hostname, username, password, [timeout_sec]) -> svc` ###

The timeout value is stored in `svc.timeout` and can be changed between calls on `svc`. A status\_vector object is also created and stored in `svc.status_vector`. You can do ErrorHandling with it.
```
local svc = fb.connect_service('localhost', 'SYSDBA', 'masterkey', 10)
```

### `svc:close()` ###

Close the connection.

## Get the version of the SM client API ##

### `svc:service_manager_version() -> n` ###
```
assert(svc:service_manager_version() == 2)
```

## See if the SM is busy performing a task ##

### `svc:busy() -> boolean` ###

Although task execution is non-blocking, the server won't perform multiple tasks at the same time, hence this function.
```
while not svc:busy() do end
```

## Get general information about the server ##

### `svc:server_version() -> s` ###
### `svc:server_implementation_string() -> s` ###
### `svc:server_capabilities() -> caps_t (pair() it out to see)` ###
### `svc:server_install_path() -> s` ###
### `svc:server_lock_path() -> s` ###
### `svc:server_msg_path() -> s` ###

## Get the contents of server's log file ##

### `svc:server_log()` ###
```
svc:server_log()
for line_num, line in svc:lines() do
  print(line_num, line)
end
```

## Get the names of currently attached databases ##

### `svc:attachment_num() -> n` ###
### `svc:db_num() -> n` ###
### `svc:db_names() -> name_t` ###

`name_t` is an array of database names currently attached. It should hold that `#name_t == svc:db_num()`.

## Get database statistics ##

### `svc:db_stats(database_name, [options_t])` ###

| **options\_t field** | **type** | **what it means** | **gstat switch** |
|:---------------------|:---------|:------------------|:-----------------|
| header\_page\_only   | true/false | Request only the information in the database header page | -header          |
| data\_pages          | true/false | Request statistics for user data pages | -data            |
| index\_pages         | true/false | Request statistics for user index pages | -index           |
| record\_versions     | true/false | Include info about record versions | n/a              |
| include\_system\_tables | true/false | Request statistics for system tables and indexes too | -system          |

```
svc:db_stats('/your/database.fdb', { header_page_only = true })
for line_num, line in svc:lines() do
  print(line_num, line)
end
```

## Backup a database ##

### `svc:db_backup(database_name, backup_file | backup_file_t, [options_t])` ###

The backup file path is relative to the server as the backup will be stored on the server's filesystem.

Normally you'd backup a database to a single file, in which case you'd pass the filename as arg#2. But should the backup file exceed 2G you need to backup the database to multiple files, in which case arg#2 is an array of the form `{file1,size1,file2,size2,...,fileN`}. fileN will be filled up with the rest of the backup data after file1..fileN-1 are filled.

| **options\_t field** | **type** | **what it means** | **gbak switch**|
|:---------------------|:---------|:------------------|:|
| verbose              | true/false | Be verbose. Use svc:lines() or svc:chunks() to get the output. | n/a |
| ignore\_checksums    | true/false | Ignore checksums during backup | -ignore |
| ignore\_limbo        | true/false | Ignore limbo transactions during backup | -limbo |
| metadata\_only       | true/false | Output backup file for metadata only with empty tables | -metadata |
| no\_garbage\_collect | true/false | Suppress normal garbage collection during backup | -garbage\_collect |
| old\_descriptions    | true/false | Output metadata in pre-4.0 format | -old\_descriptions |
| non\_transportable   | true/false | Output backup file format with non-XDR data format; improves space and performance by a negligible amount | -nt |
| include\_external\_tables | true/false | Convert external table data to internal tables | -convert |

```
local max_file_size = 1024*1024*1024*2-1 -- 2G
local backup_files = {'/your/database.fbk.001', max_file_size, '/your/database.fbk.002'}
local backup_opts = { ignore_checksums = true, include_external_tables = true }
svc:db_backup('/your/database.fdb', backup_files, backup_opts)
```

## Restore a database from backup files ##

### `svc:db_restore(backup_file | backup_file_list, db_file, [options_t])` ###

| **options\_t field** | **type** | **what it means** | **gbak switch** |
|:---------------------|:---------|:------------------|:----------------|
| verbose              | true/false | Be verbose. Use svc:lines() or svc:chunks() to get the output. | n/a             |
| page\_buffers        | 0 to 4G  | The number of default cache buffers to configure for attachments to the restored database | -buffers        |
| page\_size           | 0 to 16K  | The page size for the restored database | -page\_size     |
| read\_only           | true/false | Restore to read-only state. | -mode           |
| dont\_build\_indexes | true/false | Do not build user indexes during restore | -inactive       |
| dont\_recreate\_shadow\_files | true/false | Do not recreate shadow files during restore | -kill           |
| dont\_validate       | true/false | Do not enforce validity conditions (for example, NOT NULL) during restore | -no\_validity   |
| commit\_each\_table  | true/false | Commit after completing restore of each table | -one\_at\_a\_time |
| force                | true/false | Replace database, if one exists | -replace        |
| no\_space\_reservation | true/false | Do not reserve 20% of each data page for future record versions; useful for read-only databases | -use\_all\_space |

```
local backup_file_list = {'/your/database.fbk.001', '/your/database.fbk.002'}
local restore_opts = { commit_each_table = true, page_size = 1024*16 }
svc:db_restore(backup_file_list, '/your/database.fdb', restore_opts)
```

## Check/repair a database ##

### `svc:db_repair(database_name, [options_t])` ###

| **options\_t field** | **type** | **what it means** | **gfix switch** |
|:---------------------|:---------|:------------------|:----------------|
| dont\_fix            | true/false | Request read-only validation of the database, without correcting any problems | -no\_update     |
| ignore\_checksums    | true/false | Ignore all checksum errors | -ignore         |
| kill\_shadows        | true/false | Remove references to unavailable shadow files | -kill           |
| full                 | true/false | Check record and page structures, releasing unassigned record fragments | -full           |

## Sweep a database ##

### `svc:db_sweep(database_name)` ###

Request database sweep to mark outdated records as free space; corresponds to **gfix -sweep**.

## Mend a database ##

### `svc:db_mend(database_name)` ###

Mark corrupted records as unavailable, so subsequent operations skip them; corresponds
to **gfix -mend**.

## Set database properties ##

### `svc:db_set_page_buffers(database_name, page_buffer_num)` ###
### `svc:db_set_sweep_interval(database_name, sweep_interval)` ###
### `svc:db_set_forced_writes(database_name, true|false)` ###
### `svc:db_set_space_reservation(database_name, true|false)` ###
### `svc:db_set_read_only(database_name, true|false)` ###
### `svc:db_set_dialect(database_name, dialect)` ###

## Shutdown a database ##

### `svc:db_shutdown(database_name, timeout, [force_mode], [shutdown_mode])` ###

| **force mode** | **meaning** | **gfix switch** | **fbsvcmgr switch** |
|:---------------|:------------|:----------------|:--------------------|
| full           | shutdown the database on timeout, forcibly closing any connections left | -shut -force _timeout_ | prp\_force\_shutdown _timeout_ |
| transactions   | shutdown the database on timeout only if there are no active transactions at that point, denying new transactions in the meantime | -shut -tran _timeout_ | prp\_transactions\_shutdown _timeout_ |
| connections    | shutdown the database on timeout only if there are no active transactions at that point, denying new connections in the meantime | -shut -attach _timeout_ | prp\_attachments\_shutdown _timeout_ |

| **shutdown\_mode** | **meaning** | **fbsvcmgr switch** |
|:-------------------|:------------|:--------------------|
| normal             | TODO        | prp\_shutdown\_mode prp\_sm\_normal |
| multi (default)    | TODO        | prp\_shutdown\_mode prp\_sm\_multi |
| single             | TODO        | prp\_shutdown\_mode prp\_sm\_single |
| full               | TODO        | prp\_shutdown\_mode prp\_sm\_full |

## Activate an offline database or cancel a waiting shutdown ##

### `svc:db_activate(database_name, [online_mode])` ###

| **online\_mode** | **meaning** | **fbsvcmgr switch** |
|:-----------------|:------------|:--------------------|
| normal (default) | TODO        | prp\_online\_mode prp\_sm\_normal |
| multi            | TODO        | prp\_online\_mode prp\_sm\_multi |
| single           | TODO        | prp\_online\_mode prp\_sm\_single |
| full             | TODO        | prp\_online\_mode prp\_sm\_full |

## Switch to using the shadow file of a database ##

### `svc:db_use_shadow(database_name)` ###

## Query/modify the security database ##

### `svc:user_db_file() -> s` ###
### `svc:user_list([user_db_file]) -> t[username] -> user_t` ###
### `svc:user_list(username,[user_db_file]) -> user_t` ###
### `svc:user_add(username,password,first_name,middle_name,last_name,[user_db_file])` ###
### `svc:user_update(username,password,first_name,middle_name,last_name,[user_db_file])` ###
### `svc:user_delete(username,[user_db_file])` ###

## Trace API (Firebird 2.5+) ##

### `svc:trace_start(trace_config_string, [trace_name])` ###
### `svc:trace_list() -> trace_list_t` ###
### `svc:trace_suspend(trace_id)` ###
### `svc:trace_resume(trace_id)` ###
### `svc:trace_stop(trace_id)` ###

Read [the Firebird 2.5 Relnotes on the tracing API](http://www.firebirdsql.org/rlsnotesh/rlsnotes25.html#rnfb25-trace) until I document these functions.

## RDB$ADMIN role mapping (Firebird 2.5+) ##

### `svc:rdbadmin_set_mapping()` ###
### `svc:rdbadmin_drop_maping()` ###

Enable/disable the RDB$ADMIN role for the appointed OS user for a service request to access security2.fdb.

## Get the output of a performing task ##

The functions `db_backup()` and `db_restore()` with verbose option on, as well as `db_stats()`, `server_log()` and `trace_start()`, do not return any output directly- instead you must use the iterators returned by `lines()` or `chunks()` to get their output either line by line or chunk by chunk. Calling `lines()` or `chunks()` on an empty buffer is blocking the thread until more data is available.

Use either:
```
for line_num, line in svc:lines() do
  print(line)
end
```
or the faster alternative
```
for _, chunk in svc:chunks() do
  io.write(chunk)
end
```