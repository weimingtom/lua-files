local mysql = require'mysql'
local glue = require'glue'
local pformat = require'pp'.pformat
local ffi = require'ffi'

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
print('conn:autocommit()     ', conn:autocommit(true))

--queries

local esc = "'escape me'"
print('conn:escape(          ', pformat(esc), ')', '->', pformat(conn:escape(esc)))
local q1 = 'drop table if exists binding_test'
print('conn:query(           ', pformat(q1), ')', conn:query(q1))
--TODO: spatial fields
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
	fbinary binary(20)
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
	fbit22 = b'10',
	fbit64 = b'10',
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
	fbinary = 'a binary char'
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
print('res:field_count()     ', '->', pformat(res:field_count())); assert(res:field_count() == 32)
print('res:eof()             ', '->', pformat(res:eof())); assert(res:eof() == true)
print('res:fields()          ', '->')

print()
local function pad(s,n) s = tostring(s); return s..(' '):rep(n - #s) end
local info_keys = {'name', 'type', 'type_flag', 'length', 'max_length', 'decimals', 'charsetnr',
							'org_name', 'table', 'org_table', 'db', 'catalog', 'def', 'extension'}
local t = {}
for i,k in ipairs(info_keys) do
	t[i] = pad(k,  20)
end
print('    '..table.concat(t))
print(('-'):rep(4 + #info_keys * 20))
for n,field in res:fields() do
	local t = {}
	for i,k in ipairs(info_keys) do
		t[i] = pad(field[k],  20)
	end
	print(pad(n, 4)..table.concat(t))
end

print()
print('res:field_info(       ', 1, ')', '->', pformat(res:field_info(1), '   '))

print()
local function fetch_row()
	print('res:fetch_row()       ', '->')
	local row = assert(res:fetch_row())
	for i,field in res:fields() do
		local v = row[i]
		print('   '..pad(field.name, 20)..(type(row[i]) == 'cdata' and tostring(v) or pformat(v)))
	end
	return row
end

local test_values = {
	fdecimal = '42.12',
	fnumeric = '42.1234',
	ftinyint = 42,
	fsmallint = 42,
	finteger = 42,
	ffloat = ffi.cast('float', 42.33),
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
	fbit22 = 2,
	fbit64 = 2ULL,
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
	fbinary = 'a binary char\0\0\0\0\0\0\0'
}

--first row: test values
local row = fetch_row()
require'unit'
for i,field in res:fields() do
	test(row[i], test_values[field.name])
end

--second row: all nulls
local row = assert(res:fetch_row())
assert(#row == 0)
for i in res:fields() do
	assert(row[i] == nil)
end
assert(not res:fetch_row())

print('res:free()            ', res:free())

--reflection

local function print_res(res)
	local n = res:field_count()
	local r = res:row_count()
	for row in res:rows() do
		local t = {}
		for i=1,n do
			t[#t+1] = pad(tostring(row[i]), 20)
		end
		print('   '..table.concat(t))
	end
end
print('res:list_dbs()        '); print_res(conn:list_dbs())
print('res:list_tables()     '); print_res(conn:list_tables())
print('res:list_processes()  '); print_res(conn:list_processes())

--prepared statements

local fields = {'fdecimal', 'fnumeric', 'ftinyint', 'fsmallint', 'finteger', 'ffloat', 'fdouble',
					'freal', 'fbigint', 'fmediumint', 'fdate', 'ftime', 'ftime2', 'fdatetime', 'fdatetime2',
					'ftimestamp', 'ftimestamp2', 'fyear', 'fbit2', 'fbit22', 'fbit64', 'fenum', 'fset',
					'ftinyblob', 'fmediumblob', 'flongblob', 'ftext', 'fblob', 'fvarchar', 'fvarbinary', 'fchar', 'fbinary'}
local query = 'select '.. table.concat(fields, ', ')..' from binding_test'

local stmt = conn:prepare(query)

local bind_fields = {
	fdecimal = {type = 'decimal', size = 20}, --TODO: truncation
	fnumeric = {type = 'numeric', size = 20},
	ftinyint = {type = 'tinyint'},
	fsmallint = {type = 'smallint'},
	finteger = {type = 'integer'},
	ffloat = {type = 'float'},
	fdouble = {type = 'double'},
	freal = {type = 'real'},
	fbigint = {type = 'bigint'},
	fmediumint = {type = 'mediumint'},
	fdate = {type = 'date'},
	ftime = {type = 'time'},
	ftime2 = {type = 'time'},
	fdatetime = {type = 'datetime'},
	fdatetime2 = {type = 'datetime'},
	ftimestamp = {type = 'timestamp'},
	ftimestamp2 = {type ='timestamp'},
	fyear = {type = 'year'},
	fbit2 = {type = 'bit'},
	fbit22 = {type = 'bit'},
	fbit64 = {type = 'bit'},
	fenum = {type = 'enum', size = 200},
	fset = {type = 'set', size = 200},
	ftinyblob = {type = 'tinyblob', size = 200},
	fmediumblob = {type = 'mediumblob', size = 200},
	flongblob = {type = 'longblob', size = 200},
	ftext = {type = 'text', size = 200},
	fblob = {type = 'blob', size = 200},
	fvarchar = {type = 'varchar', size = 200},
	fvarbinary = {type = 'varbinary', size = 200},
	fchar = {type = 'char', size = 200},
	fbinary = {type = 'binary', size = 200},
}
local bind_fields_t = {}
for i,name in ipairs(fields) do
	table.insert(bind_fields_t, assert(bind_fields[name]))
end
local bind = stmt:bind_fields(bind_fields_t)
print('stmt:bind_fields      ', pformat(bind_fields_t, '   '), '->', pformat(bind, '   '))

print('conn:prepare(         ', pformat(query), ')', '->', stmt)
print('stmt:exec()           ', stmt:exec())
print('stmt:store_result()   ', stmt:store_result())
print('stmt:fetch_row()      ', stmt:fetch_row())
print('bind:is_truncated(    ', 1, ')', '->', bind:is_truncated(1)); assert(bind:is_truncated(1) == false)

for i=1,bind.field_count do
	local v = bind:get(i)
	test(v, test_values[fields[i]])
	v = type(v) == 'cdata' and tostring(v) or pformat(v)
	print(pad(i, 4) .. pad(fields[i], 20) .. v)
end

print('stmt:free_result()    ', stmt:free_result())
local next_result = stmt:next_result()
print('stmt:next_result()    ', '->', next_result); assert(next_result == false)

print('stmt:reset()          ', stmt:reset())
print('stmt:close()          ', stmt:close())

print('conn:close()          ', conn:close())

