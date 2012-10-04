local ffi = require'ffi'
local nanojpeg = require'nanojpeg'
local glue = require'glue'

local function dir(d)
	local f = io.popen('ls -1 '..d)
	return glue.collect(f:lines())
end

local readfile=require'glue'.readfile
local pp=require'pp'.pp
for _,filename in ipairs(dir('media/jpeg/*.jpg')) do
	print(filename,'------------------------')
	if not filename:match'testimgari.jpg' --arithmetic coding not supported
		and not filename:match'testimgp.jpg' --progressive jpeg not supported
	then
		local s = readfile(filename)
		local cdata = ffi.new('unsigned char[?]', #s+1, s)

		pp(nanojpeg.load({cdata = cdata, size = #s}))
		pp(nanojpeg.load({string = s}))
		pp(nanojpeg.load({path = filename}))
	end
end
