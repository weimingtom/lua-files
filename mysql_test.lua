local mysql = require'mysql'
local glue = require'glue'
local pformat = require'pp'.pformat
local ffi = require'ffi'

local function assert_deepequal(t1, t2) --assert the equality of two values
	assert(type(t1) == type(t2), type(t1)..' ~= '..type(t2))
	if type(t1) == 'table' then
		for k,v in pairs(t1) do assert_deepequal(t2[k], v) end
		for k,v in pairs(t2) do assert_deepequal(t1[k], v) end
	else
		assert(t1 == t2, pformat(t1) .. ' ~= ' .. pformat(t2))
	end
end

local function fit(s,n)
	return #s > n and (s:sub(1,n-3) .. '...') or s
end

local function leftalign(s,n)
	s = tostring(s)
	s = s..(' '):rep(n - #s)
	return fit(s,n)
end

local function rightalign(s,n)
	s = tostring(s)
	s = (' '):rep(n - #s)..s
	return fit(s,n)
end

local function centeralign(s,n)
	s = tostring(s)
	local total = n - #s
	local left = math.floor(total / 2)
	local right = math.ceil(total / 2)
	s = (' '):rep(left)..s..(' '):rep(right)
	return fit(s,n)
end

local function print_table(fields, rows)
	local max_sizes = {}
	for i=1,#rows do
		for j=1,#fields do
			max_sizes[j] = math.max(max_sizes[j] or 0, #tostring(rows[i][j]))
		end
	end

	local totalsize = 0
	for j=1,#fields do
		max_sizes[j] = math.max(max_sizes[j] or 0, #fields[j])
		totalsize = totalsize + max_sizes[j] + 3
	end

	print()
	local s, ps = '', ''
	for j=1,#fields do
		s = s .. centeralign(fields[j], max_sizes[j]) .. ' | '
		ps = ps .. ('-'):rep(max_sizes[j]) .. ' + '
	end
	print(s)
	print(ps)

	for i=1,#rows do
		local s = ''
		for j=1,#fields do
			local val = rows[i][j]
			local align = type(rows[i][j]) == 'number' and rightalign or leftalign
			s = s .. align(val, max_sizes[j]) .. ' | '
		end
		print(s)
	end
	print()
end

local function invert_table(fields, rows)
	local ft, rt = {'field'}, {}
	for i=1,#rows do
		ft[i+1] = tostring(i)
	end
	for j=1,#fields do
		local row = {fields[j]}
		for i=1,#rows do
			row[i+1] = rows[i][j]
		end
		rt[j] = row
	end
	return ft, rt
end

local function print_result(res)
	local fields = {}
	for i,field in res:fields() do
		fields[i] = field.name
	end
	local rows = {}
	for i,row in res:rows'n' do
		rows[i] = row
	end
	print_table(fields, rows)
end

local function print_fields(fields_iter)
	local fields = {'name', 'type', 'type_flag', 'length', 'max_length', 'decimals', 'charsetnr',
							'org_name', 'table', 'org_table', 'db', 'catalog', 'def', 'extension'}
	local rows = {}
	for i,field in fields_iter do
		rows[i] = {}
		for j=1,#fields do
			rows[i][j] = field[fields[j]]
		end
	end
	print_table(fields, rows)
end

--client library

print('mysql.thread_safe()   ', '->', pformat(mysql.thread_safe()))
print('mysql.client_info()   ', '->', pformat(mysql.client_info()))
print('mysql.client_version()', '->', pformat(mysql.client_version()))

--connections

local t = {
	host = 'localhost',
	user = 'root',
	db = 'test',
	options = {
		MYSQL_SECURE_AUTH = true,
		MYSQL_OPT_READ_TIMEOUT = 1,
	},
	flags = {
		CLIENT_LONG_PASSWORD = true,
	},
}
local conn = mysql.connect(t)
print('mysql.connect         ', pformat(t, '   '), '->', conn)
print('conn:change_user(     ', pformat(t.user), ')', conn:change_user(t.user))
print('conn:select_db(       ', pformat(t.db), ')', conn:select_db(t.db))
print('conn:set_multiple_statements(', pformat(true), ')', conn:set_multiple_statements(true))
print('conn:set_charset(     ', pformat('utf8'), ')', conn:set_charset('utf8'))

--conn info

print('conn:charset_name()   ', '->', pformat(conn:charset())); assert(conn:charset() == 'utf8')
print('conn:charset_info()   ', '->', pformat(conn:charset_info(), '   '))
print('conn:ping()           ', '->', pformat(conn:ping()))
print('conn:thread_id()      ', '->', pformat(conn:thread_id()))
print('conn:stat()           ', '->', pformat(conn:stat()))
print('conn:server_info()    ', '->', pformat(conn:server_info()))
print('conn:host_info()      ', '->', pformat(conn:host_info()))
print('conn:server_version() ', '->', pformat(conn:server_version()))
print('conn:proto_info()     ', '->', pformat(conn:proto_info()))
print('conn:ssl_cipher()     ', '->', pformat(conn:ssl_cipher()))

--transactions

print('conn:commit()         ', conn:commit())
print('conn:rollback()       ', conn:rollback())
print('conn:set_autocommit() ', conn:set_autocommit(true))

--queries

local esc = "'escape me'"
print('conn:escape(          ', pformat(esc), ')', '->', pformat(conn:escape(esc)))
local q1 = 'drop table if exists binding_test'
print('conn:query(           ', pformat(q1), ')', conn:query(q1))

conn:query[[
create table binding_test (
	fdecimal decimal(8,2),
	fnumeric numeric(6,4),
	ftinyint tinyint,
	fsmallint smallint,
	finteger integer,
	ffloat float,
	fdouble double,
	freal real,
	fbigint bigint,
	fmediumint mediumint,
	fdate date,
	ftime time(0),
	ftime2 time(6),
	fdatetime datetime(0),
	fdatetime2 datetime(6),
	ftimestamp timestamp(0) null,
	ftimestamp2 timestamp(6) null,
	fyear year,
	fbit2 bit(2),
	fbit22 bit(22),
	fbit64 bit(64),
	fenum enum('yes', 'no'),
	fset set('e1', 'e2', 'e3'),
	ftinyblob tinyblob,
	fmediumblob mediumblob,
	flongblob longblob,
	ftext text,
	fblob blob,
	fvarchar varchar(200),
	fvarbinary varbinary(200),
	fchar char(200),
	fbinary binary(20),
	fnull integer
);

insert into binding_test set
	fdecimal = '42.12',
	fnumeric = 42.1234,
	ftinyint = '42',
	fsmallint = 42,
	finteger = '42',
	ffloat = 42.33,
	fdouble = '42.33',
	freal = 42.33,
	fbigint = '420',
	fmediumint = 440,
	fdate = '2013-10-05',
	ftime = '21:30:15',
	ftime2 = '21:30:16.123456',
	fdatetime = '2013-10-05 21:30:17',
	fdatetime2 = '2013-10-05 21:30:18.123456',
	ftimestamp = '2013-10-05 21:30:19',
	ftimestamp2 = '2013-10-05 21:30:20.123456',
	fyear = 2013,
	fbit2 = b'10',
	fbit22 = b'1000000010',
	fbit64 = b'0000001000000000000000000000000000000000000000000000001000000010',
	fenum = 'yes',
	fset = ('e3,e2'),
	ftinyblob = 'tiny tiny blob',
	fmediumblob = 'medium blob',
	flongblob = 'loong blob',
	ftext = 'just a text',
	fblob = 'bloob',
	fvarchar = 'just a varchar',
	fvarbinary = 'a varbinary',
	fchar = 'a char',
	fbinary = 'a binary char',
	fnull = null
;

insert into binding_test values ();

select * from binding_test;
]]

--query info

print('conn:field_count()    ', '->', pformat(conn:field_count()))
print('conn:affected_rows()  ', '->', pformat(conn:affected_rows()))
print('conn:insert_id()      ', '->', conn:insert_id())
print('conn:errno()          ', '->', pformat(conn:errno()))
print('conn:sqlstate()       ', '->', pformat(conn:sqlstate()))
print('conn:warning_count()  ', '->', pformat(conn:warning_count()))
print('conn:info()           ', '->', pformat(conn:info()))
for i=1,3 do
print('conn:more_results()   ', '->', pformat(conn:more_results())); assert(conn:more_results())
print('conn:next_result()    ', '->', pformat(conn:next_result()))
end
assert(not conn:more_results())

--query results

local res = conn:store_result() --TODO: local res = conn:use_result()
print('conn:store_result()   ', '->', res)
print('res:row_count()       ', '->', pformat(res:row_count())); assert(res:row_count() == 2)
print('res:field_count()     ', '->', pformat(res:field_count())); assert(res:field_count() == 33)
print('res:eof()             ', '->', pformat(res:eof())); assert(res:eof() == true)
print('res:fields()          ', '->') print_fields(res:fields())
print('res:field_info(1)     ', '->', pformat(res:field_info(1)))

local test_values = {
	fdecimal = '42.12',
	fnumeric = '42.1234',
	ftinyint = 42,
	fsmallint = 42,
	finteger = 42,
	ffloat = tonumber(ffi.cast('float', 42.33)),
	fdouble = 42.33,
	freal = 42.33,
	fbigint = 420LL,
	fmediumint = 440,
	fdate = {year = 2013, month = 10, day = 05},
	ftime = {hour = 21, min = 30, sec = 15, frac = 0},
	ftime2 = {hour = 21, min = 30, sec = 16, frac = 123456},
	fdatetime = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 17, frac = 0},
	fdatetime2 = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 18, frac = 123456},
	ftimestamp = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 19, frac = 0},
	ftimestamp2 = {year = 2013, month = 10, day = 05, hour = 21, min = 30, sec = 20, frac = 123456},
	fyear = 2013,
	fbit2 = 2,
	fbit22 = 2 * 2^8 + 2,
	fbit64 = 2ULL * 2^(64-8) + 2 * 2^8 + 2,
	fenum = 'yes',
	fset = 'e2,e3',
	ftinyblob = 'tiny tiny blob',
	fmediumblob = 'medium blob',
	flongblob = 'loong blob',
	ftext = 'just a text',
	fblob = 'bloob',
	fvarchar = 'just a varchar',
	fvarbinary = 'a varbinary',
	fchar = 'a char',
	fbinary = 'a binary char\0\0\0\0\0\0\0',
	fnull = nil,
}

--first row: fetch as array and test values
local row = assert(res:fetch'n')
print("res:fetch'n'          ", '->', pformat(row))
for i,field in res:fields() do
	assert_deepequal(row[i], test_values[field.name])
end

--first row again: fetch as assoc. array and test values
print('res:seek(1)           ', '->', res:seek(1))
local row = assert(res:fetch'a')
print("res:fetch'a'         ", '->', pformat(row))
for i,field in res:fields() do
	assert_deepequal(row[field.name], test_values[field.name])
end

--first row again: fetch unpacked and test values
print('res:seek(1)           ', '->', res:seek(1))
local function pack(_, ...)
	local t = {}
	for i=1,select('#', ...) do
		t[i] = select(i, ...)
	end
	return t
end
local row = pack(res:fetch())
print("res:fetch()           ", '-> packed: ', pformat(row))
for i,field in res:fields() do
	assert_deepequal(row[i], test_values[field.name])
end

--first row again: print its values parsed and unparsed for comparison
res:seek(1)
local row = assert(res:fetch'n')
res:seek(1)
local row_s = assert(res:fetch'ns')
print()
print(rightalign('', 4) .. '  ' .. leftalign('field', 20) .. leftalign('unparsed', 40) .. '  ' .. 'parsed')
print(('-'):rep(4 + 2 + 20 + 40 + 40))
for i,field in res:fields() do
	print(rightalign(i, 4) .. '  ' .. leftalign(field.name, 20) .. leftalign(pformat(row_s[i]), 40) .. '  ' .. pformat(row[i]))
end
print()

--second row: all nulls
local row = assert(res:fetch'n')
print("res:fetch'n'          ", '->', pformat(row))
assert(#row == 0)
for i=1,res:field_count() do
	assert(row[i] == nil)
end
assert(not res:fetch'n')

--all rows again: test iterator
res:seek(1)
local n = 0
for i,row in res:rows'nas' do
	n = n + 1
	assert(i == n)
end
print("for i,row in res:rows'nas' do <count-rows>", '->', n); assert(n == 2)

print('res:free()            ', res:free())

--reflection

print('res:list_dbs()        ', '->'); print_result(conn:list_dbs())
print('res:list_tables()     ', '->'); print_result(conn:list_tables())
print('res:list_processes()  ', '->'); print_result(conn:list_processes())

--prepared statements

local bind_defs = {
	{type = 'decimal', size = 20}, --TODO: truncation
	{type = 'numeric', size = 20},
	{type = 'tinyint'},
	{type = 'smallint'},
	{type = 'integer'},
	{type = 'float'},
	{type = 'double'},
	{type = 'real'},
	{type = 'bigint'},
	{type = 'mediumint'},
	{type = 'date'},
	{type = 'time'},
	{type = 'time'},
	{type = 'datetime'},
	{type = 'datetime'},
	{type = 'timestamp'},
	{type = 'timestamp'},
	{type = 'year'},
	{type = 'bit'},
	{type = 'bit'},
	{type = 'bit'},
	{type = 'enum', size = 200},
	{type = 'set', size = 200},
	{type = 'tinyblob', size = 200},
	{type = 'mediumblob', size = 200},
	{type = 'longblob', size = 200},
	{type = 'text', size = 200},
	{type = 'blob', size = 200},
	{type = 'varchar', size = 200},
	{type = 'varbinary', size = 200},
	{type = 'char', size = 200},
	{type = 'binary', size = 200},
	{type = 'integer'},
}

--preparation phase

local fields = {'fdecimal', 'fnumeric', 'ftinyint', 'fsmallint', 'finteger', 'ffloat', 'fdouble',
					'freal', 'fbigint', 'fmediumint', 'fdate', 'ftime', 'ftime2', 'fdatetime', 'fdatetime2',
					'ftimestamp', 'ftimestamp2', 'fyear', 'fbit2', 'fbit22', 'fbit64', 'fenum', 'fset',
					'ftinyblob', 'fmediumblob', 'flongblob', 'ftext', 'fblob', 'fvarchar', 'fvarbinary', 'fchar', 'fbinary',
					'fnull'}

local query = 'select '.. table.concat(fields, ', ')..' from binding_test'
local stmt = conn:prepare(query)

print('conn:prepare(         ', pformat(query), ')', '->', stmt)
print('stmt:field_count()    ', '->', pformat(stmt:field_count())); assert(stmt:field_count() == #bind_defs)
--we can get the fields and their types before execution so we can create create our bind structures.
--max. length is not computed though, but it will be computed after binding.
print('stmt:result_fields()  ', '->'); print_fields(stmt:result_fields())

--binding phase

local bind = stmt:bind_result(bind_defs)
print('stmt:bind_result(     ', pformat(bind_defs), ')', '->', pformat(bind))
--max. length is computed now, so we can allocate our buffers.
--this can only mean that by now the query already ran on the server even if we didn't yet call exec().
print('stmt:result_fields()  ', '->'); print_fields(stmt:result_fields())

--execution and loading

print('stmt:exec()           ', stmt:exec())
print('stmt:store_result()   ', stmt:store_result())

--result info

print('stmt:row_count()      ', '->', pformat(stmt:row_count()))
print('stmt:affected_rows()  ', '->', pformat(stmt:affected_rows()))
print('stmt:insert_id()      ', '->', pformat(stmt:insert_id()))
print('stmt:sqlstate()       ', '->', pformat(stmt:sqlstate()))

--result data (different API since we don't get a result object)

print('stmt:fetch()          ', stmt:fetch())
print('bind:is_truncated(1)  ', '->', pformat(bind:is_truncated(1))); assert(bind:is_truncated(1) == false)
print('bind:is_null(1)       ', '->', pformat(bind:is_null(1))); assert(bind:is_null(1) == false)
print('bind:get(1)           ', '->', pformat(bind:get(1))); assert(bind:get(1) == test_values.fdecimal)
print('bind:get_date(11)     ', '->', bind:get_date(11)); assert_deepequal({bind:get_date(11)}, {2013, 10, 5})
print('bind:get_date(12)     ', '->', bind:get_date(12)); assert_deepequal({bind:get_date(12)}, {nil, nil, nil, 21, 30, 15, 0})
print('bind:get_date(14)     ', '->', bind:get_date(14)); assert_deepequal({bind:get_date(14)}, {2013, 10, 5, 21, 30, 17, 0})
print('bind:get_date(16)     ', '->', bind:get_date(16)); assert_deepequal({bind:get_date(16)}, {2013, 10, 5, 21, 30, 19, 0})
print('bind:get_date(17)     ', '->', bind:get_date(17)); assert_deepequal({bind:get_date(17)}, {2013, 10, 5, 21, 30, 20, 123456})
print('for i=1,bind.field_count do bind:get(i)', '->')

print()
for i=1,bind.field_count do
	local v = bind:get(i)
	assert_deepequal(v, test_values[fields[i]])
	assert(bind:is_truncated(i) == false)
	assert(bind:is_null(i) == (fields[i] == 'fnull'))
	print(rightalign(i, 4) .. '  ' .. leftalign(fields[i], 20) .. pformat(v))
end
print()

print('stmt:free_result()    ', stmt:free_result())
local next_result = stmt:next_result()
print('stmt:next_result()    ', '->', pformat(next_result)); assert(next_result == false)

print('stmt:reset()          ', stmt:reset())
print('stmt:close()          ', stmt:close())

local test_values_bin = {
	fbit2 = '10',
	fbit22 = '1000000010',
	fbit64 = '0000001000000000000000000000000000000000000000000000001000000010',
}

--prepared statements with parameters
for i,fname in ipairs(fields) do
	local query = 'select * from binding_test where '..fname..' = ?'
	local stmt = conn:prepare(query)
	print('conn:prepare(         ', pformat(query), ')')
	local param_bind_def = {bind_defs[i]}

	local bind = stmt:bind_params(param_bind_def)
	print('stmt:bind_params      ', pformat(param_bind_def))

	local function exec()
		print('stmt:exec()           ', stmt:exec())
		print('stmt:store_result()   ', stmt:store_result())
		print('stmt:row_count()      ', '->', stmt:row_count()); assert(stmt:row_count() == 1)
	end

	if fname == 'fnull' then
		--how to test this? and why would we ever wanna have a null-only param?
	else
		local v = test_values[fname]
		print('bind:set(             ', 1, pformat(v), ')'); bind:set(1, v); exec()
		if fname:find'^fbit' then
			print('bind:set_bits(        ', 1, pformat(v), ')'); bind:set_bits(1, v); exec()
		end

		if fname:find'date' or fname:find'time' then
			print('bind:set_date(     ', 1, v.year, v.month, v.day, v.hour, v.min, v.sec, v.frac, ')')
			bind:set_date(1, v.year, v.month, v.day, v.hour, v.min, v.sec, v.frac); exec()
		end
	end

	print('stmt:close()          ', stmt:close())
end

local q = 'drop table binding_test'
print('conn:query(           ', pformat(q), ')', conn:query(q))
print('conn:commit()         ', conn:commit())
print('conn:close()          ', conn:close())

