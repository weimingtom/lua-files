local glue = require'glue'
local ffi = require'ffi'
local pp = require'pp'.pp
local readfile = glue.readfile
require'unit'
local giflib = require'giflib'

ffi.cdef'int _fileno(void*);'

for _,filename in ipairs(dir('media/gif/*.gif')) do
	print(filename,'----------------------------')
	local s = readfile(filename)
	local cdata = ffi.new('unsigned char[?]', #s+1, s)

	pp(assert(giflib.load({path = filename})))
	pp(assert(giflib.load{cdata = cdata, size = #s}))

	local f = assert(io.open(filename, 'rb'))
	local fn = ffi.C._fileno(f)
	--TODO: this crashes for some reason
	--assert(giflib.load{fileno = fn})
	f:close()

	for _,row_format in ipairs{'top_down', 'bottom_up'} do
		for _,padded in ipairs{true, false} do
			for _,pixel_format in ipairs{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'argb', 'bgra', 'abgr'} do
				print('>', pixel_format, row_format, padded)
				local t = assert(giflib.load{string = s},
							{accept = {[row_format] = true, [pixel_format] = true, padded = padded}})
				for _,t in ipairs(t.frames) do
					pp(t)
					assert(t.stride == padded and bmpconv.pad_stride(#t.pixel * t.w) or #t.pixel * t.w)
					assert(t.size == t.stride * t.h)
				end
			end
		end
	end
end
