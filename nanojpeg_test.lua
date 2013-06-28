local glue = require'glue'
local ffi = require'ffi'
local pp = require'pp'.pp
local readfile = glue.readfile
require'unit'
local nanojpeg = require'nanojpeg'

for _,filename in ipairs(dir('media/jpeg/*.jpg')) do
	print(filename,'------------------------')
	local s = readfile(filename)
	local cdata = ffi.new('unsigned char[?]', #s+1, s)

	if filename:match'testimgari.jpg' then
		print'arithmetic coding not supported'
	elseif filename:match'testimgp.jpg' or filename:match'progressive' then
		print'progressive jpeg not supported'
	else
		assert(nanojpeg.load({path = filename}))
		assert(nanojpeg.load({cdata = cdata, size = #s}))

		for _,row_format in ipairs{'top_down', 'bottom_up'} do
			for _,padded in ipairs{true, false} do
				for _,pixel_format in ipairs{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'argb', 'bgra', 'abgr'} do
					print('>', pixel_format, row_format, padded)
					local t = nanojpeg.load({string = s},
							{accept = {[row_format] = true, [pixel_format] = true, padded = padded}})
					pp(t)
					assert(t.stride == padded and bmpconv.pad_stride(#t.pixel * t.w) or #t.pixel * t.w)
					assert(t.size == t.stride * t.h)
				end
			end
		end
	end
end
