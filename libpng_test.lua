local glue = require'glue'
local ffi = require'ffi'
local pp = require'pp'.pp
local readfile = glue.readfile
require'unit'
local libpng = require'libpng'

for _,filename in ipairs(dir('media/png/pngsuite/*.png')) do
	print(filename,'----------------------------')
	local s = readfile(filename)
	local cdata = ffi.new('unsigned char[?]', #s+1, s)

	pp(libpng.load({path = filename}))
	pp(libpng.load({cdata = cdata, size = #s}))

	for _,row_format in ipairs{'top_down', 'bottom_up'} do
		for _,padded in ipairs{true, false} do
			for _,pixel_format in ipairs{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'argb', 'bgra', 'abgr'} do
				if true or pixel_format == 'g' and row_format == 'top_down' and not padded then
					print('>', pixel_format, row_format, padded)
					pp(libpng.load(
							{string = readfile(filename)},
							{accept = {[pixel_format] = true, [row_format] = true, padded = padded}}
					))
				end
			end
		end
	end
end
