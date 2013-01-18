local glue = require'glue'
local ffi = require'ffi'
local bmpconv = require'bmpconv'
local pp = require'pp'.pp
local readfile = glue.readfile
require'unit'
local libjpeg = require'libjpeg'

for _,filename in ipairs(dir('media/jpeg/*.jpg')) do
	print(filename,'------------------------')
	local s = readfile(filename)
	local cdata = ffi.new('unsigned char[?]', #s+1, s)
	local function read_cdata() return cdata, #s end
	local function read_string() return s end

	pp(libjpeg.load({path = filename}))
	pp(libjpeg.load({cdata = cdata, size = #s}))
	pp(libjpeg.load({string = s}))
	pp(libjpeg.load({cdata_source = read_cdata}))
	pp(libjpeg.load({string_source = read_string}))

	local i = 0
	if filename:match'progressive' then
		pp(libjpeg.load({string_source = read_string}, {
			render_scan = function(img) print('render',img.scan) end,
			have_data = function() i=i+1; return i < 200 end
		}))
	end

	if true then
	for _,row_format in ipairs{'top_down', 'bottom_up'} do
		for _,padded in ipairs{true, false} do
			for _,pixel_format in ipairs{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'argb', 'bgra', 'abgr'} do
				print('>', pixel_format, row_format, padded)
				local t = libjpeg.load({path = filename},
						{multipass = true, accept = {[row_format] = true, [pixel_format] = true, padded = padded}})
				pp(t)
				assert(t.stride == padded and bmpconv.pad_stride(#t.pixel * t.w) or #t.pixel * t.w)
				assert(t.size == t.stride * t.h)
			end
		end
	end
	end
end
