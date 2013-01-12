local ffi = require'ffi'
local tj = require'turbojpeg'
local glue = require'glue'

local function dir(d)
	local f = io.popen('ls -1 '..d)
	return glue.collect(f:lines())
end

local readfile=require'glue'.readfile
local pp=require'pp'.pp
for _,filename in ipairs(dir('media/jpeg/*.jpg')) do
	print(filename,'------------------------')
	local s = readfile(filename)
	local sz = #s
	local cdata = ffi.new('uint8_t[?]', sz+1, s)

	--pp(nanojpeg2.load({cdata = cdata, size = #s}))
	--pp(nanojpeg2.load({string = s}))
	--pp(nanojpeg2.load({path = filename}))
	for _,row_format in ipairs{'top_down', 'bottom_up'} do
		for _,padded in ipairs{true, false} do
			for _,pixel_format in ipairs{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'argb', 'bgra', 'abgr'} do
				print('>', pixel_format, row_format, padded)
				pp(tj.decompress(cdata, sz,
					{accept = {[row_format] = true, [pixel_format] = true, padded = padded}}
				))
			end
		end
	end
end
