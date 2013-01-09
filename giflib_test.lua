local ffi = require'ffi'
local giflib = require'giflib'
local glue = require'glue'

ffi.cdef'int _fileno(void*);'

local function dir(d)
	local f = io.popen('ls -1 '..d)
	return glue.collect(f:lines())
end

local pp=require'pp'.pp
local readfile=require'glue'.readfile
for _,filename in ipairs(dir('media/gif/*.gif')) do
	print(filename,'----------------------------')

	local s = assert(readfile(filename))
	local cdata = ffi.new('unsigned char[?]', #s+1, s)

	pp(assert(giflib.load({path = filename}, {accept = {top_down = true, argb = true}})))

	local f = assert(io.open(filename, 'rb'))
	local fn = ffi.C._fileno(f)
	--TODO: this crashes for some reason
	--assert(giflib.load{fileno = fn})
	f:close()

	pp(assert(giflib.load{cdata = cdata, size = #s}))
	pp(assert(giflib.load{string = s}))
end
