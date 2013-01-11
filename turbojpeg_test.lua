local ffi = require'ffi'
local tj = require'turbojpeg'
local glue = require'glue'
require'stdio'

local function readfile(file)
	local f = ffi.C.fopen(file, 'rb')
	ffi.C.fseek(f, 0, ffi.C.SEEK_END)
	local sz = ffi.C.ftell(f)
	ffi.C.fseek(f, 0, ffi.C.SEEK_SET)
	local buf = ffi.new('uint8_t[?]', sz)
	ffi.C.fread(buf, 1, sz, f)
	ffi.C.fclose(f)
	return buf, sz
end

local data, sz = readfile'media/jpeg/testimggray.jpg'
for i=1,1000 do
	tj.decompress(data, sz)
end
