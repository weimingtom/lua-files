local zip = require'minizip'
local zlib = require'zlib'
local glue = require'glue'

local filename = 'test.zip'
local password = 'doh'
local hello = 'hello'
local hello_again = 'hello again'


local z = zip.open(filename, 'w')

z:add_file{filename = 'file1.txt', password = password, crc = zlib.crc32b(hello)}
z:write(hello)
z:close_file()

z:add_file('file2.txt')
z:write(hello_again)
z:close_file()

z:close()


local z = zip.open(filename)

z:first()
z:open_file(password)
assert(table.concat(glue.collect(z:bytes())) == hello)
assert(z:eof())
assert(z:tell() == #hello)
z:close_file()

z:next()
z:open_file()
assert(table.concat(glue.collect(z:bytes())) == hello_again)
assert(z:eof())
assert(z:tell() == #hello_again)
z:close_file()

z:close()

