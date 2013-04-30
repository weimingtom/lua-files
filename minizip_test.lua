local zip = require'minizip'
local glue = require'glue'
local pp = require'pp'.pp

local filename = 'test.zip'
local password = 'doh'
local hello = 'hello'
local hello_again = 'hello again'

local z = zip.open(filename, 'w')

z:add_file{filename = 'dir1/file1.txt', password = password, date = os.date'*t'}
z:write(hello)
z:close_file()

z:add_file{filename = 'dir1/file2.txt'}
z:write(hello_again)
z:close_file()

z:close('global comment')


local z = zip.open(filename)
pp(z:get_global_info())
for info in z:files() do
	pp(info)
end

z:first_file()
z:open_file(password)
assert(z:uncompress() == hello)
assert(z:eof())
assert(z:tell() == #hello)
z:close_file()

z:next_file()
z:open_file()
assert(z:uncompress() == hello_again)
assert(z:eof())
assert(z:tell() == #hello_again)
z:close_file()

z:close()

