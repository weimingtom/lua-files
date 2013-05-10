local ffi = require'ffi'
local bit = require'bit'
require'mysql_h'
local C = ffi.load'libmysql'
local M = {C = C}

--error reporting

local function cstring(data)
	if data == nil or data[0] == 0 then return end
	return ffi.string(data)
end

local function myerror(mysql)
	local err = cstring(C.mysql_error(mysql))
	if not err then return end
	error(string.format('mysql error: %s', err))
end

local function checkz(mysql, ret)
	if ret == 0 then return end
	myerror(mysql)
end

local function checkh(mysql, ret)
	if ret ~= nil then return ret end
	myerror(mysql)
end

--client library info

function M.thread_safe()
	return C.mysql_thread_safe() == 1
end

function M.get_client_info()
	return cstring(C.mysql_get_client_info())
end

M.get_client_version = C.mysql_get_client_version

--connections

local function bool_ptr(b)
	return ffi.new('my_bool[1]', b and 1 or 0)
end

local function uint_bool_ptr(b)
	return ffi.new('uint32_t[1]', b and 1 or 0)
end

local function uint_ptr(i)
	return ffi.new('uint32_t[1]', i)
end

local function ignore_arg()
	return nil
end

local option_encoders = {
	MYSQL_ENABLE_CLEARTEXT_PLUGIN = bool_ptr,
	MYSQL_OPT_LOCAL_INFILE = uint_bool_ptr,
	MYSQL_OPT_PROTOCOL = uint_ptr, --C.MYSQL_PROTOCOL_*
	MYSQL_OPT_READ_TIMEOUT = uint_ptr,
	MYSQL_OPT_WRITE_TIMEOUT = uint_ptr,
	MYSQL_OPT_USE_REMOTE_CONNECTION = ignore_arg,
	MYSQL_OPT_USE_EMBEDDED_CONNECTION = ignore_arg,
	MYSQL_OPT_GUESS_CONNECTION = ignore_arg,
	MYSQL_SECURE_AUTH = bool_ptr,
	MYSQL_REPORT_DATA_TRUNCATION = bool_ptr,
	MYSQL_OPT_RECONNECT = bool_ptr,
	MYSQL_OPT_SSL_VERIFY_SERVER_CERT = bool_ptr,
	MYSQL_ENABLE_CLEARTEXT_PLUGIN = bool_ptr,
	MYSQL_OPT_CAN_HANDLE_EXPIRED_PASSWORDS = bool_ptr,
}

function M.connect(t)
	local host = assert(t.host, 'missing host')
	local user = t.user
	local pass = t.pass
	local db = t.db
	local port = t.port or 0
	local unix_socket = t.unix_socket
	local client_flag = t.client_flag or 0

	local mysql = assert(C.mysql_init(nil))
	ffi.gc(mysql, C.mysql_close)

	if t.options then
		for k,v in pairs(t.options) do
			local opt = C[k]
			local encoder = option_encoders[k]
			if encoder then v = encoder(v) end
			assert(C.mysql_options(mysql, opt, ffi.cast('const void*', v)) == 0, 'invalid option')
		end
	end
	if t.attrs then
		for k,v in pairs(t.attrs) do
			assert(C.mysql_options4(mysql, C.MYSQL_OPT_CONNECT_ATTR_ADD, k, v) == 0)
		end
	end

	return checkh(mysql, C.mysql_real_connect(mysql, host, user, pass, db, port, unix_socket, client_flag))
end

local conn = {} --connection methods

function conn.close(mysql)
	C.mysql_close(mysql)
	ffi.gc(mysql, nil)
end

function conn.set_charset(mysql, charset)
	checkz(mysql, C.mysql_set_character_set(mysql, charset))
end

function conn.select_db(mysql, db)
	checkz(mysql, C.mysql_select_db(mysql, db))
end

function conn.change_user(mysql, user, pass, db)
	checkz(mysql, C.mysql_change_user(mysql, user, pass, db))
end

function conn.set_ssl(mysql, key, cert, ca, cpath, cipher)
	checkz(mysql, C.mysql_ssl_set(mysql, key, cert, ca, cpath, cipher))
end

function conn.set_multiple_statements(mysql, yes)
	checkz(mysql, C.mysql_set_server_option(mysql, yes and C.MYSQL_OPTION_MULTI_STATEMENTS_ON or
																			 C.MYSQL_OPTION_MULTI_STATEMENTS_OFF))
end

--connection info

function conn.get_charset_name(mysql)
	return cstring(C.mysql_character_set_name(mysql))
end

function conn.get_charset_info(mysql)
	local info = ffi.new'MY_CHARSET_INFO'
	checkz(C.mysql_get_character_set_info(mysql, info))
	assert(info.name ~= nil)
	assert(info.csname ~= nil)
	return {
		number = info.number,
		state = info.state,
		name = cstring(info.csname), --csname and name are inverted from the spec
		collation = cstring(info.name),
		comment = cstring(info.comment),
		dir = cstring(info.dir),
		mbminlen = info.mbminlen,
		mbmaxlen = info.mbmaxlen,
	}
end

local ping_results = {
	[C.CR_COMMANDS_OUT_OF_SYNC] = 'sync',
	[C.CR_SERVER_GONE_ERROR] = 'gone',
}
function conn.ping(mysql)
	local ret = C.mysql_ping(mysql)
	if ret == 0 then return true end
	local err = ping_errors[ret]
	if not err then myerror(mysql) end
	return false, err
end

conn.get_thread_id = C.mysql_thread_id

function conn.get_stat(mysql)
	return cstring(checkh(mysql, C.mysql_stat(mysql)))
end

function conn.get_server_info(mysql)
	return cstring(checkh(mysql, C.mysql_get_server_info(mysql)))
end

function conn.get_host_info(mysql)
	return cstring(checkh(mysql, C.mysql_get_host_info(mysql)))
end

conn.get_server_version = C.mysql_get_server_version
conn.get_proto_info = C.mysql_get_proto_info


function conn.get_ssl_cipher(mysql)
	return cstring(C.mysql_get_ssl_cipher(mysql))
end

--transactions

function conn.commit(mysql) checkz(mysql, C.mysql_commit(mysql)) end
function conn.rollback(mysql) checkz(mysql, C.mysql_rollback(mysql)) end
function conn.autocommit(mysql, yes) checkz(mysql, C.mysql_autocommit(mysql, yes and 1 or 0)) end

--queries

function conn.escape_tobuffer(mysql, data, size, buf, sz)
	size = size or #data
	assert(sz >= size * 2 + 1)
	return C.mysql_real_escape_string(mysql, buf, data, size)
end

function conn.escape(mysql, data, size)
	size = size or #data
	local sz = size * 2 + 1
	local buf = ffi.new('uint8_t[?]', sz)
	sz = conn.escape_tobuffer(mysql, data, size, buf, sz)
	return ffi.string(buf, sz)
end

function conn.query(mysql, data, size)
	checkz(mysql, C.mysql_real_query(mysql, data, size or #data))
end

--query info

conn.field_count = C.mysql_field_count

function conn.affected_rows(mysql)
	return C.mysql_affected_rows(mysql)
end

conn.insert_id = C.mysql_insert_id
conn.errno = C.mysql_errno

function conn.sqlstate(mysql)
	return cstring(C.mysql_sqlstate(mysql))
end

conn.warning_count = C.mysql_warning_count

function conn.info(mysql)
	return cstring(C.mysql_info(mysql))
end

--query results

function conn.next_result(mysql) --multiple statement queries return multiple results
	local ret = C.mysql_next_result(mysql)
	if ret == 0 then return true end
	if ret == -1 then return false end
	myerror(mysql)
end

function conn.more_results(mysql)
	return C.mysql_more_results(mysql) == 1
end

--TODO: MYSQL_RES *mysql_list_fields(MYSQL *mysql, const char *table, const char *wild);

function conn.store_result(mysql) --use only if conn:field_count() > 0
	local res = checkh(mysql, C.mysql_store_result(mysql))
	return ffi.gc(res, C.mysql_free_result)
end

function conn.use_result(mysql) --use only if conn:field_count() > 0
	local res = checkh(mysql, C.mysql_use_result(mysql))
	return ffi.gc(res, C.mysql_free_result)
end

local res = {} --result methods

function res.free(res)
	C.mysql_free_result(res)
	ffi.gc(res, nil)
end

function res.row_count(res)
	return tonumber(C.mysql_num_rows(res))
end

res.field_count = C.mysql_num_fields

function res.eof(res)
	return C.mysql_eof(res) == 1
end

--field info
local field_type_names = {
	[C.MYSQL_TYPE_DECIMAL] = 'decimal', --DECIMAL or NUMERIC
	[C.MYSQL_TYPE_TINY] = 'tinyint',
	[C.MYSQL_TYPE_SHORT] = 'smallint',
	[C.MYSQL_TYPE_LONG] = 'integer',
	[C.MYSQL_TYPE_FLOAT] = 'float',
	[C.MYSQL_TYPE_DOUBLE] = 'double', --DOUBLE or REAL
	[C.MYSQL_TYPE_NULL] = 'null',
	[C.MYSQL_TYPE_TIMESTAMP] = 'timestamp',
	[C.MYSQL_TYPE_LONGLONG] = 'bigint',
	[C.MYSQL_TYPE_INT24] = 'mediumint',
	[C.MYSQL_TYPE_DATE] = 'date',
	[C.MYSQL_TYPE_TIME] = 'time',
	[C.MYSQL_TYPE_DATETIME] = 'datetime',
	[C.MYSQL_TYPE_YEAR] = 'year',
	[C.MYSQL_TYPE_NEWDATE] = 'newdate',
	[C.MYSQL_TYPE_VARCHAR] = 'varchar',
	[C.MYSQL_TYPE_BIT] = 'bit',
	[C.MYSQL_TYPE_TIMESTAMP2] = 'timestamp2',
	[C.MYSQL_TYPE_DATETIME2] = 'datetime2',
	[C.MYSQL_TYPE_TIME2] = 'time2',
	[C.MYSQL_TYPE_NEWDECIMAL] = 'newdecimal', --Precision math DECIMAL or NUMERIC
	[C.MYSQL_TYPE_ENUM] = 'enum',
	[C.MYSQL_TYPE_SET] = 'set',
	[C.MYSQL_TYPE_TINY_BLOB] = 'tiny_blob',
	[C.MYSQL_TYPE_MEDIUM_BLOB] = 'medium_blob',
	[C.MYSQL_TYPE_LONG_BLOB] = 'long_blob',
	[C.MYSQL_TYPE_BLOB] = 'text', --TEXT or BLOB
	[C.MYSQL_TYPE_VAR_STRING] = 'varchar', --VARCHAR or VARBINARY
	[C.MYSQL_TYPE_STRING] = 'char', --CHAR or BINARY
	[C.MYSQL_TYPE_GEOMETRY] = 'spatial', --Spatial field
}

local binary_field_type_names = {
	[C.MYSQL_TYPE_BLOB] = 'blob', --TEXT or BLOB
	[C.MYSQL_TYPE_VAR_STRING] = 'varbinary', --VARCHAR or VARBINARY
	[C.MYSQL_TYPE_STRING] = 'binary', --CHAR or BINARY
}

local field_type_flag_names = {
	[C.MYSQL_NOT_NULL_FLAG] = 'not_null',
	[C.MYSQL_PRI_KEY_FLAG] = 'pri_key',
	[C.MYSQL_UNIQUE_KEY_FLAG] = 'unique_key',
	[C.MYSQL_MULTIPLE_KEY_FLAG] = 'key',
	[C.MYSQL_UNSIGNED_FLAG] = 'unsigned',
	[C.MYSQL_ZEROFILL_FLAG] = 'zerofill',
	[C.MYSQL_BINARY_FLAG] = 'binary_flag',
	[C.MYSQL_AUTO_INCREMENT_FLAG] = 'autoincrement',
	[C.MYSQL_ENUM_FLAG] = 'enum',
	[C.MYSQL_SET_FLAG] = 'set',
	[C.MYSQL_BLOB_FLAG] = 'blob',
	[C.MYSQL_TIMESTAMP_FLAG] = 'timestamp',
	[C.MYSQL_NUM_FLAG] = 'num',
	[C.MYSQL_NO_DEFAULT_VALUE_FLAG] = 'no_default',
}

function res.field_info(res, i)
	local info = C.mysql_fetch_field_direct(res, i-1)
	local t = {
		name = cstring(info.name, info.name_length);
		org_name = cstring(info.org_name, info.org_name_length);
		table = cstring(info.table, info.table_length);
		org_table = cstring(info.org_table, info.org_table_length);
		db = cstring(info.db, info.db_length);
		catalog = cstring(info.catalog, info.catalog_length);
		def = cstring(info.def, info.def_length);
		length = info.length;
		max_length = info.max_length;
		decimals = info.decimals;
		charsetnr = info.charsetnr;
		type = field_type_names[tonumber(info.type)];
		extension = info.extension ~= nil and info.extension or nil;
	}
	if info.charsetnr == 63 then --BINARY not CHAR, VARBYNARY not VARCHAR, BLOB not TEXT
		local bin_type = binary_field_type_names[tonumber(info.type)]
		if bin_type then t.type = bin_type end
	end
	for flag, name in pairs(field_type_flag_names) do
		t[name] = bit.band(flag, info.flags) ~= 0
	end
	return t
end

function res.fields(res)
	local n = res:field_count()
	local t = {}
	for i=1,n do
		t[i] = res:field_info(i)
	end
	return t
end

--row data



local field_decoders = {
	[C.MYSQL_TYPE_DECIMAL] = 'decimal',
	[C.MYSQL_TYPE_TINY] = 'tiny',
	[C.MYSQL_TYPE_SHORT] = 'short',
	[C.MYSQL_TYPE_LONG] = 'long',
	[C.MYSQL_TYPE_FLOAT] = 'float',
	[C.MYSQL_TYPE_DOUBLE] = 'double',
	[C.MYSQL_TYPE_NULL] = 'null',
	[C.MYSQL_TYPE_TIMESTAMP] = 'timestamp',
	[C.MYSQL_TYPE_LONGLONG] = 'longlong',
	[C.MYSQL_TYPE_INT24] = 'int24',
	[C.MYSQL_TYPE_DATE] = 'date',
	[C.MYSQL_TYPE_TIME] = 'time',
	[C.MYSQL_TYPE_DATETIME] = 'datetime',
	[C.MYSQL_TYPE_YEAR] = 'year',
	[C.MYSQL_TYPE_NEWDATE] = 'newdate',
	[C.MYSQL_TYPE_VARCHAR] = 'varchar',
	[C.MYSQL_TYPE_BIT] = 'bit',
	[C.MYSQL_TYPE_TIMESTAMP2] = 'timestamp2',
	[C.MYSQL_TYPE_DATETIME2] = 'datetime2',
	[C.MYSQL_TYPE_TIME2] = 'time2',
	[C.MYSQL_TYPE_NEWDECIMAL] = 'newdecimal',
	[C.MYSQL_TYPE_ENUM] = 'enum',
	[C.MYSQL_TYPE_SET] = 'set',
	[C.MYSQL_TYPE_TINY_BLOB] = 'tiny_blob',
	[C.MYSQL_TYPE_MEDIUM_BLOB] = 'medium_blob',
	[C.MYSQL_TYPE_LONG_BLOB] = 'long_blob',
	[C.MYSQL_TYPE_BLOB] = 'blob',
	[C.MYSQL_TYPE_VAR_STRING] = 'var_string',
	[C.MYSQL_TYPE_STRING] = 'string',
	[C.MYSQL_TYPE_GEOMETRY] = 'geometry',
}

function res.fetch_row(res)
	local n = C.mysql_num_fields(res)
	local row = C.mysql_fetch_row(res)
	local sz = C.mysql_fetch_lengths(res)
	local fields = C.mysql_fetch_fields(res)
	local t = {}
	for i=0,n-1 do
		local decoder = assert(field_decoders[fields[i].type])
		t[#t+1] = decoder(row[i], sz[i])
	end
	return t
end

--[[
unsigned long * mysql_fetch_lengths(MYSQL_RES *result);
typedef char **MYSQL_ROW;

void mysql_data_seek(MYSQL_RES *result, my_ulonglong offset);

typedef struct MYSQL_ROWS_ MYSQL_ROWS;
typedef MYSQL_ROWS *MYSQL_ROW_OFFSET;
MYSQL_ROW_OFFSET mysql_row_tell(MYSQL_RES *res);
MYSQL_ROW_OFFSET mysql_row_seek(MYSQL_RES *result, MYSQL_ROW_OFFSET offset);

typedef unsigned int MYSQL_FIELD_OFFSET;
MYSQL_FIELD_OFFSET mysql_field_tell(MYSQL_RES *res);
MYSQL_FIELD_OFFSET mysql_field_seek(MYSQL_RES *result, MYSQL_FIELD_OFFSET offset);
]]


ffi.metatype('MYSQL', {__index = conn})
ffi.metatype('MYSQL_RES', {__index = res})

local mysql = M
local glue = require'glue'
local pformat = require'pp'.pformat

--client library
print('thread_safe      ', mysql.thread_safe())
print('client_info      ', mysql.get_client_info())
print('client_version   ', mysql.get_client_version())

--connections
local t = {host = 'localhost', user = 'root', db = 'myj', options = {
	MYSQL_SECURE_AUTH = true,
	MYSQL_OPT_READ_TIMEOUT = 1,
}}
local conn = mysql.connect(t)
print('mysql.connect         ', t.host, t.user, t.db, conn)
print('conn:change_user      ', 'root', conn:change_user('root'))
print('conn:select_db        ', 'myj', conn:select_db('myj'))
print('conn:set_multiple_statements', true, conn:set_multiple_statements(true))
print('conn:set_charset      ', 'utf8', conn:set_charset('utf8'))

--conn info
print('conn:get_charset_name ', conn:get_charset_name())
assert(conn:get_charset_name() == 'utf8')
print('conn:get_charset_info ', pformat(conn:get_charset_info(), '   '))
print('conn:ping             ', conn:ping())
print('conn:get_thread_id    ', conn:get_thread_id())
print('conn:get_stat         ', conn:get_stat())
print('conn:get_server_info  ', conn:get_server_info())
print('conn:get_host_info    ', conn:get_host_info())
print('conn:get_server_version', conn:get_server_version())
print('conn:get_proto_info   ', conn:get_proto_info())
print('conn:get_ssl_cipher   ', conn:get_ssl_cipher())

--transactions
print('conn:commit           ', conn:commit())
print('conn:rollback         ', conn:rollback())
print('conn:autocommit       ', conn:autocommit(true))

--queries
print('conn:escape           ', conn:escape("'escape me'"))
print('conn:query            ', conn:query('select * from resumes'))

--query info
print('conn:field_count      ', conn:field_count())
print('conn:affected_rows    ', conn:affected_rows())
print('conn:insert_id        ', conn:insert_id())
print('conn:errno            ', conn:errno())
print('conn:sqlstate         ', conn:sqlstate())
print('conn:warning_count    ', conn:warning_count())
print('conn:info             ', conn:info())
print('conn:more_results     ', conn:more_results()) --TODO: next_results
--TODO: local res = conn:use_result()
local res = conn:store_result()
print('conn:use_result       ', res)
print('res:row_count         ', res:row_count()); assert(res:row_count() == 21)
print('res:field_count       ', res:field_count()); assert(res:field_count() == 11)
print('res:eof               ', res:eof()); assert(res:eof() == true)
print('res:fields            ')
local fields = res:fields()
local function pad(s,n) s = tostring(s); return s..(' '):rep(n - #s) end
for k in glue.sortedpairs(fields[1]) do
	local t = {pad(k,14)}
	for i=1,#fields do
		t[#t+1] = pad(fields[i][k],  20)
	end
	print(table.concat(t, '\t'))
end
print('res:field_info        ', pformat(res:field_info(1), '   '))

print('res:free              ', res:free())
--query results

--disconnect
print('conn:close            ', conn:close())

