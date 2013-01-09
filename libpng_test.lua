local glue = require'glue'
local ffi = require'ffi'
local libpng = require'libpng'
require'stdio'

local function dir(d)
	local f = io.popen('ls -1 '..d)
	return glue.collect(f:lines())
end

local function save(data, size, name)
	local f = io.open(name or 'tmp.raw', 'wb')
	f:write(ffi.string(data, size))
	f:close()
end

local pp=require'pp'.pp
local readfile=require'glue'.readfile

for _,filename in ipairs(dir('media/png/pngsuite/*.png')) do
	print(filename,'----------------------------')
	local s = readfile(filename)
	local cdata = ffi.new('unsigned char[?]', #s+1, s)

	pp(libpng.load({path = filename}, {accept = {bgra = true, bottom_up = true}}))
	pp(libpng.load({cdata = cdata, size = #s}, {accept = {abgr = true, top_down = true}}))
	pp(libpng.load({string = readfile(filename)}))
end
