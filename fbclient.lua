--fbclient2: a ffi binding of firebird's client library.
--based on firebird's latest ibase.h with the help of the Interbase 6 API Guide.
--NOTE: all attachments involved in a multi-database transaction should run on the same OS thread.
--NOTE: avoid sharing a connection between two threads, although fbclient itself is thread-safe from v2.5 on.

local ffi = require'ffi'
require'fbclient_h'
local glue = require'glue'
local dpb_encode = require'fbclient_dpb'
local tpb_encode = require'fbclient_tpb'

local M = {}

--library functions

function M.ib_version(C) --returns major, minor
	return
		C.isc_get_client_major_version(),
		C.isc_get_client_minor_version()
end

--caller object

--given a ffi library object, return a caller object through which to make error-handled calls to fbclient.
function M.caller(C)
	local sv  = ffi.new'ISC_STATUS[20]' --status vector, required by all firebird calls
	local psv = ffi.new('ISC_STATUS*[1]', ffi.cast('ISC_STATUS*', sv)) --pointer to it
	local msgsize = 2048
	local msg = ffi.new('uint8_t[?]', msgsize) --message buffer, for error reporting

	local function status() --false, 335544344
		return not (sv[0] == 1 and sv[1] ~= 0), sv[1]
	end

	local function errcode() --'isc_io_error'
		local ok, err = status()
		if ok then return end
		local errcodes = require'fbclient_errcodes'
		return errcodes[err]
	end

	local function errors() --{'blah', 'blah'}
		if status() then return end
		local errlist = {}
		while C.fb_interpret(msg, msgsize, ffi.cast('const ISC_STATUS**', psv)) ~= 0 do
			errlist[#errlist+1] = ffi.string(msg)
		end
		return errlist
	end

	local function sqlcode() --n
		if status() then return end
		return C.isc_sqlcode(sv)
	end

	local function sqlstate() --'00000'
		if status() then return end
		C.fb_sqlstate(msg, sv)
		return ffi.string(msg, 5)
	end

	local function sqlerror(sqlcode) --'blah blah'
		if status() then return end
		C.isc_sql_interprete(sqlcode, msg, msgsize)
		return ffi.string(msg)
	end

	local function pcall(fname, ...)
		local ret = C[fname](sv, ...)
		local ok, err = status()
		if ok then return true, ret end
		return false, err
	end

	local function call(fname, ...)
		local ok, err = pcall(fname, ...)
		if ok then return err end
		local errlist = table.concat(errors(), '\n')
		error(string.format('%s() error: %s\n%s', fname, err, errlist))
	end

	return {
		C = C,
		pcall = pcall,
		call = call,
		status = status,
		sqlcode = sqlcode,
		sqlstate = sqlstate,
		sqlerror = sqlerror,
		errors = errors,
	}
end

--connections

local conn = {}
local conn_meta = {__index = conn}

local function attach(attach_function, sql, t, ...)
	--process arguments
	local dbname, user, pass, charset
	local role, dpb_t, client_library
	local dpb_s, dpb
	if sql then
		client_library = t
	else
		if type(t) == 'string' then
			dbname, user, pass, charset = t, ...
		else
			dbname, user, pass, charset = t.db, t.user, t.pass, t.charset
			role, dpb_t, client_library = t.role, t.dpb, t.client_library
		end
		dpb = {}
		dpb.isc_dpb_user_name = user
		dpb.isc_dpb_password = pass
		dpb.isc_dpb_lc_ctype = charset
		dpb.isc_dpb_sql_role_name = role
		glue.update(dpb, dpb_t)
		dpb_s = dpb_encode(dpb)
	end

	--caller object
	local C = ffi.load(client_library or 'fbclient')
	local caller = M.caller(C)

	--connection handle
	local dbh = ffi.new'isc_db_handle[1]'

	if sql then
		caller.call(attach_function, dbh, nil, #sql, sql, dialect, nil)
	else
		caller.call(attach_function, #dbname, dbname, dbh, dpb_s and #dpb_s or 0, dpb_s)
	end

	--connection object
	local cn = setmetatable({}, conn_meta)
	cn.dbh = dbh
	cn.caller = caller
	cn.call = caller.call
	cn.statement_handle_pool = {}
	cn.transactions = {}   --keep track of transactions spanning this attachment
	cn.statements = {}     --keep track of statements made against this attachment
	if dbname then
		cn.database = dbname --for cloning
		cn.dpb = glue.update({}, dpb) --for cloning
		cn.allow_cloning = true
	end
	return cn
end

function M.connect(...)
	return attach('isc_attach_database', nil, ...)
end

function M.create_db(...)
	return attach('isc_create_database', nil, ...)
end

function M.create_db_sql(sql, client_library) --create a db using the CREATE DATABASE statement
	return attach('isc_dsql_execute_immediate', sql, client_library)
end

function db_drop(fbapi, sv, dbh)
	self.call('isc_drop_database', dbh)
end


function conn:close()
	for tr in pairs(self.transactions) do
		tr:rollback()
	end
	self.call('isc_detach_database', self.dbh)
end

function conn:version_info()
	local ver={}
	local function helper(p, s)
		ver[#ver+1] = ffi.string(s)
	end
	assert(self.caller.C.isc_version(self.dbh, helper, nil) == 0, 'isc_version() error')
	return ver
end

--transactions

local tran = {}
local tran_meta = {__index = tran}

local function wrap_tran(trh, call, connections)
	local tr = setmetatable({}, tran_meta)
	tr.trh = trh
	tr.call = call
	tr.connections = connections
	tr.statements = {} --keep track of statements made on this transaction
	local n = 0
	for conn in pairs(connections) do
		conn.transactions[tr] = true
		n = n + 1
	end
	if n == 1 then
		tr.conn = next(connections)
	end
	return tr
end

--start a transaction spawning multiple connections.
--when no options are provided, {isc_tpb_write=true,isc_tpb_concurrency=true,isc_tpb_wait=true} is assumed by Firebird.
function M.start_transaction(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	local teb = ffi.new('ISC_TEB[?]', n)
	local pin = {} --pin tpb strings to prevent garbage collecting
	local connections = {}
	local i = 0
	for conn, opts in pairs(t) do
		if opts == true then opts = nil end --true was just a key holder
		teb[i].teb_database = conn.dbh
		local tpb_str = tpb_encode(opts)
		teb[i].teb_tpb_length = tpb_str and #tpb_str or 0
		teb[i].teb_tpb = tpb_str
		pin[tpb_str] = true
		connections[conn] = true
		i = i + 1
	end
	assert(i > 0, 'no connections')
	local call = next(t).call --any caller would do
	local trh = ffi.new'isc_tr_handle[1]'
	call('isc_start_multiple', trh, n, teb)
	--transaction object
	return wrap_tran(trh, call, connections)
end

function conn:start_transaction(opts)
	if type(opts) == 'string' then
		--opts is a SET TRANSACTION SQL statement which we can execute with dsql_execute_immediate() to get its handle.
		--NOTE: you could make this support input parameters, but it doesn't worth the trouble.
		local trh = ffi.new'isc_tr_handle[1]'
		self.call('isc_dsql_execute_immediate', self.dbh, trh, #opts, opts, 3, nil)
		--transaction object
		return wrap_tran(trh, self.call, {[self] = true})
	else
		--opts is missing or is a table specifying transaction options
		return M.start_transaction({[self] = opts or true})
	end
end

function tran:commit_retaining()
	self.call('isc_commit_retaining', self.trh)
end

function tran:rollback_retaining()
	self.call('isc_rollback_retaining', self.trh)
end

function tran:commit()
	self.call('isc_commit_transaction', self.trh)
end

function tran:rollback()
	self.call('isc_rollback_transaction', self.trh)
end

local function check_conn(tr, conn)
	if conn then
		assert(tr.connections[conn], 'invalid connection')
		return conn
	else
		assert(tr.conn, 'connection required')
		return tr.conn
	end
end

function tran:exec(sql, conn) --note: this can be made to support input parameters and result values.
	conn = check_conn(self, conn)
	self.call('isc_dsql_execute_immediate', conn.dbh, self.trh, #sql, sql, 3, nil)
end

--statements

local sqltype_names = glue.index{
	SQL_TEXT        = 452,
	SQL_VARYING     = 448,
	SQL_SHORT       = 500,
	SQL_LONG        = 496,
	SQL_FLOAT       = 482,
	SQL_DOUBLE      = 480,
	SQL_D_FLOAT     = 530,
	SQL_TIMESTAMP   = 510,
	SQL_BLOB        = 520,
	SQL_ARRAY       = 540,
	SQL_QUAD        = 550,
	SQL_TYPE_TIME   = 560,
	SQL_TYPE_DATE   = 570,
	SQL_INT64       = 580,
	SQL_NULL        = 32766, --Firebird 2.5+
}

local sqlsubtype_names = glue.index{
	isc_blob_untyped    = 0,
	isc_blob_text       = 1,
	isc_blob_blr        = 2,
	isc_blob_acl        = 3,
	isc_blob_ranges     = 4,
	isc_blob_summary    = 5,
	isc_blob_format     = 6,
	isc_blob_tra        = 7,
	isc_blob_extfile    = 8,
	isc_blob_debug_info = 9,
}

--computes buflen for a certain sqltype,sqllen pair.
local function sqldata_buflen(sqltype, sqllen)
	local buflen = sqllen
	if sqltype == 'SQL_VARYING' then
		buflen = sqllen + SHORT_SIZE
	elseif sqltype == 'SQL_NULL' then
		buflen = 0
	end
	return buflen
end

--this does three things:
--1) allocate SQLDA/SQLIND buffers accoding to the sqltype and setup the XSQLVAR to point to them.
--2) decode the info from XSQLVAR.
--3) return a table with the info and the data buffers pinned to it.
local function XSQLVAR(x)
	--allow_null tells us if the column allows null values, and so an sqlind buffer is needed
	--to receive the null flag. thing is however that you can have null values on a not-null
	--column under some circumstances, so we're always allocating an sqlind buffer.
	local allow_null = x.sqltype % 2 == 1 --this flag is kept in bit 1
	local sqltype_code = x.sqltype - (allow_null and 1 or 0)
	local sqltype = assert(sqltype_names[sqltype_code])
	local subtype = sqltype == 'SQL_BLOB' and assert(sqlsubtype_names[x.sqlsubtype]) or nil
	local sqlname = x.sqlname_length > 0 and ffi.string(x.sqlname, x.sqlname_length) or nil
	local relname = x.relname_length > 0 and ffi.string(x.relname, x.relname_length) or nil
	local ownname = x.ownname_length > 0 and ffi.string(x.ownname, x.ownname_length) or nil
	local aliasname = x.aliasname_length > 0 and ffi.string(x.aliasname, x.aliasname_length) or nil
	local buflen = sqldata_buflen(sqltype, x.sqllen)
	local sqldata_buf = buflen > 0 and ffi.new('uint8_t[?]', buflen) or nil
	local sqlind_buf = ffi.new('int16_t[1]', -1)
	x.sqldata = sqldata_buf
	x.sqlind = sqlind_buf
	--set the allow_null bit, otherwise the server won't touch the sqlind buffer on columns that have the bit clear.
	x.sqltype = sqltype_code + 1
	local xs = {
		sqltype = sqltype,         --how is SQLDATA encoded
		sqlscale = x.sqlscale,     --for number types
		sqllen = x.sqllen,         --max. size of the *contents* of the SQLDATA buffer
		buflen = buflen,           --size of the SQLDATA buffer
		subtype = subtype,         --how is a blob encoded
		allow_null = allow_null,   --should we allocate an sqlind buffer or not
		sqldata_buf = sqldata_buf, --pinned SQLDATA buffer
		sqlind_buf = sqlind_buf,   --pinned SQLIND buffer
		column_name = sqlname,
		table_name = relname,
		table_owner_name = ownname,
		column_alias_name = aliasname,
	}
	return xs
end

local function alloc_xsqlvars(x) --alloc data buffers for each column, based on XSQLVAR descriptions
	local alloc, used = x.sqln, x.sqld
	assert(alloc >= used)
	local t = {}
	for i=1,used do
		local xs = XSQLVAR(x.sqlvar[i-1])
		t[i] = xs
		if xs.column_alias_name then
			t[xs.column_alias_name] = xs
		end
	end
	return t
end

local function XSQLDA(xsqlvar_count) --alloc a new xsqlda object
	local x = ffi.new('XSQLDA', xsqlvar_count)
	ffi.fill(x, ffi.sizeof(x)) --ffi doesn't clear the trailing VLA part of a VLS
	x.version = 1
	x.sqln = xsqlvar_count
	return x
end

local stmt = {} --statement methods
local stmt_meta = {__index = stmt}

function tran:prepare(sql, conn, sth)
	conn = check_conn(self, conn)

	--statement handle (deallocated automatically when connection closes)
	if not sth then
		sth = ffi.new'isc_stmt_handle[1]'
		self.call('isc_dsql_alloc_statement2', conn.dbh, sth)
	end

	--alloc an output XSQLDA for to 10 columns to avoid a second describe call. one xsqlvar is 152 bytes.
	local outx = XSQLDA(10)

	--prepare statement, which gets us the number of output columns.
	self.call('isc_dsql_prepare', self.trh, sth, #sql, sql, 3, outx)

	--see if outx is long enough to keep all columns, and if not, reallocate and re-describe.
	local alloc, used = outx.sqln, outx.sqld
	if alloc < used then
		outx = XSQLDA(used)
		self.call('isc_dsql_describe', sth, 1, outx)
	end

	--alloc an input XSQLDA for zero params.
	local inx = XSQLDA(0)
	self.call('isc_dsql_describe_bind', sth, 1, inx)

	--see if inx is long enough to keep all parameters, and if not, reallocate and re-describe.
	local alloc, used = inx.sqln, inx.sqld
	if alloc < used then
		inx = XSQLDA(used)
		self.call('isc_dsql_describe_bind', sth, 1, inx)
	end

	--alloc xsqlvar buffers
	local fields = alloc_xsqlvars(outx)
	local params = alloc_xsqlvars(inx)

	--statement object
	local st = setmetatable({}, stmt_meta)
	st.sth = sth
	st.call = self.call
	st.fields_xsqlda = outx
	st.params_xsqlda = inx
	st.fields = fields
	st.params = params

	--register statement to transaction and to connection objects
	conn.statements[st] = true
	self.statements[st] = true
	st.tran = self
	st.conn = conn

	return st
end

function stmt:exec()
	self.call('isc_dsql_execute', self.trh, self.sth, 1, self.params_xsqlda)
end

function stmt:set_cursor_name(fbapi, sv, sth, cursor_name) --call it on a prepared statement
	self.self.call('isc_dsql_set_cursor_name', self.sth, cursor_name, 0)
end

function stmt:exec_returning()
	self.call('isc_dsql_execute2', self.trh, self.sth, 1, self.fields_xsqlda, self.params_xsqlda)
end

function stmt:fetch() --note that only select statements return a cursor to fetch from
	local status = self.call('isc_dsql_fetch', self.sth, 1, self.fields_xsqlda)
	assert(status == 0 or status == 100)
	return status == 0
end

function stmt:free()
	self.call('isc_dsql_free_statement', self.sth, 2)
end

function stmt:unprepare() --unprepare statement without freeing its handle, so it can be reused
	self.call('isc_dsql_free_statement', self.sth, 4)
	return self.sth
end

function stmt:free_cursor() --frees a cursor created by dsql_set_cursor_name()
	self.call('isc_dsql_free_statement', self.sth, 1)
end




require'fbclient_errcodes'
local fb = M
local cn = fb.connect('localhost:x:/work/fbclient/lua/fbclient/gazolin.fdb', 'SYSDBA', 'masterkey')
pp(cn:version_info())
local tr1 = cn:start_transaction()
local tr2 = cn:start_transaction'SET TRANSACTION'
tr1:exec('select * from rdb$database')
local st = tr2:prepare('select * from rdb$database')
pp(st)
st:free()
cn:close()

--[[


function db_info(fbapi, sv, dbh, opts, info_buf_len)
	local info = require 'fbclient.db_info' --this is a runtime dependency so as to not bloat the library!
	local opts, max_len = info.encode(opts)
	info_buf_len = math.min(MAX_SHORT, info_buf_len or max_len)
	local info_buf = alien.buffer(info_buf_len)
	self.call('isc_database_info', dbh, #opts, opts, info_buf_len, info_buf)
	return info.decode(info_buf, info_buf_len, fbapi)
end

local fb_cancel_operation_enum = {
	fb_cancel_disable = 1, --disable any pending fb_cancel_raise
	fb_cancel_enable  = 2, --enable any pending fb_cancel_raise
	fb_cancel_raise   = 3, --cancel any request on db_handle ASAP (at the next rescheduling point), and return an error in the status_vector.
	fb_cancel_abort   = 4,
}

--ATTN: don't call this from the main thread (where the signal handler is registered)!
function db_cancel_operation(fbapi, sv, dbh, opt)
	asserts(type(sql)=='string', 'arg#1 string expected, got %s',type(sql))
	opts = asserts(fb_cancel_operation_enum[opts or 'fb_cancel_raise'], 'invalid option %s', opt)
	self.call('fb_cancel_operation', dbh, opts)
end

function tr_info(fbapi, sv, trh, opts, info_buf_len)
	local info = require 'fbclient.tr_info' --this is a runtime dependency so as to not bloat the library!
	local opts, max_len = info.encode(opts)
	info_buf_len = math.min(MAX_SHORT, info_buf_len or max_len)
	local info_buf = alien.buffer(info_buf_len)
	self.call('isc_transaction_info', trh, #opts, opts, info_buf_len, info_buf)
	return info.decode(info_buf, info_buf_len)
end

function dsql_info(fbapi, sv, sth, opts, info_buf_len)
	local info = require 'fbclient.sql_info' --this is a runtime dependency so as to not bloat the library!
	local opts, max_len = info.encode(opts)
	info_buf_len = math.min(MAX_SHORT, info_buf_len or max_len)
	local info_buf = alien.buffer(info_buf_len)
	self.call('isc_dsql_sql_info', sth, #opts, opts, info_buf_len, info_buf)
	return info.decode(info_buf, info_buf_len)
end
]]
