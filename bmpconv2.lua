--go @ bin/luajit.exe -jdump *
--bitmap conversions between different pixel formats, bitmap orientations, strides and bit depths.
local ffi = require'ffi'
local bit = require'bit'
io.stdout:setvbuf'no'

local function create_table(t, k)
	if k == nil then return end
	t[k] = {}
	return t[k]
end
local function autotable(t)
	return setmetatable(t, {__index = create_table})
end

local formats = {}

formats.rgb565   = {bpp = 16, ctype = ffi.typeof'uint16_t'}
formats.rgba4444 = {bpp = 16, ctype = ffi.typeof'uint16_t'}
formats.rgba5551 = {bpp = 16, ctype = ffi.typeof'uint16_t'}

formats.rgb24    = {bpp = 24, ctype = ffi.typeof'uint8_t'}
formats.bgr24    = formats.rgb24

formats.rgba32   = {bpp = 32, ctype = ffi.typeof'uint8_t'}
formats.bgra32   = formats.rgba32
formats.argb32   = formats.rgba32
formats.abgr32   = formats.rgba32

formats.rgbx32   = formats.rgba32
formats.bgrx32   = formats.rgba32
formats.xrgb32   = formats.rgba32
formats.xbgr32   = formats.rgba32

formats.rgba64   = {bpp = 64, ctype = ffi.typeof'uint16_t'}
formats.bgra64   = formats.rgba64
formats.argb64   = formats.rgba64
formats.abgr64   = formats.rgba64

formats.g8       = {bpp =  8, ctype = ffi.typeof'uint8_t'}
formats.ga8      = {bpp = 16, ctype = ffi.typeof'uint8_t'}
formats.ag8      = formats.ga8

formats.g16      = {bpp = 16, ctype = ffi.typeof'uint16_t'}
formats.ga16     = {bpp = 32, ctype = ffi.typeof'uint16_t'}
formats.ag16     = formats.ga16

formats.g1       = {bpp =  1, ctype = ffi.typeof'uint8_t'}

formats.icmyk32  = {bpp = 32, ctype = ffi.typeof'uint8_t'} --inverse cmyk

local readers = autotable{}

function readers.rgb565.rgba8(s,i)
	return
		bit.lshift(bit.rshift(s[i], 5+6), 8-5),
		bit.lshift(bit.band(bit.rshift(s[i], 5), 2^6-1), 8-6),
		bit.lshift(bit.band(s[i], 2^5-1), 8-5),
		0xff
end

function readers.rgba4444.rgba8(s,i)
	return
		bit.lshift(bit.rshift(s[i], 4+4+4), 8-4),
		bit.lshift(bit.band(bit.rshift(s[i], 4+4), 2^4-1), 8-4),
		bit.lshift(bit.band(bit.rshift(s[i], 4), 2^4-1), 8-4),
		bit.lshift(bit.band(s[i], 2^4-1), 8-4)
end

function readers.rgba5551.rgba8(s,i)
	return
		bit.lshift(bit.rshift(s[i], 5+5+1), 8-5),
		bit.lshift(bit.band(bit.rshift(s[i], 5+1), 2^5-1), 8-5),
		bit.lshift(bit.band(bit.rshift(s[i], 1), 2^5-1), 8-5),
		bit.lshift(bit.band(s[i], 1), 8-1)
end

function readers.rgb24.rgba8(s,i) return s[i], s[i+1], s[i+2], 0xff end
function readers.bgr24.rgba8(s,i) return s[i+2], s[i+1], s[i], 0xff end

function readers.rgba32.rgba8(s,i) return s[i], s[i+1], s[i+2], s[i+3] end
function readers.bgra32.rgba8(s,i) return s[i+2], s[i+1], s[i], s[i+3] end
function readers.argb32.rgba8(s,i) return s[i+1], s[i+2], s[i+3], s[i] end
function readers.abgr32.rgba8(s,i) return s[i+3], s[i+2], s[i+1], s[i] end

readers.rgba64.rgba16 = readers.rgba32.rgba8
readers.bgra64.rgba16 = readers.bgra32.rgba8
readers.argb64.rgba16 = readers.argb32.rgba8
readers.abgr64.rgba16 = readers.abgr32.rgba8

function readers.rgbx32.rgba8(s,i) return s[i], s[i+1], s[i+2], 0xff end
function readers.bgrx32.rgba8(s,i) return s[i+2], s[i+1], s[i], 0xff end
function readers.xrgb32.rgba8(s,i) return s[i+1], s[i+2], s[i+3], 0xff end
function readers.xbgr32.rgba8(s,i) return s[i+3], s[i+2], s[i+1], 0xff end

function readers.g8.rgba8(s,i)  return s[i], s[i], s[i], 0xff end
function readers.ga8.rgba8(s,i) return s[i], s[i], s[i], s[i+1] end
function readers.ag8.rgba8(s,i) return s[i+1], s[i+1], s[i+1], s[i] end

readers.icmyk32.icmyk8 = readers.rgba32.rgba8

local converters = autotable{}

function converters.rgba8.rgba16(r, g, b, a)
	return
		bit.lshift(r, 8),
		bit.lshift(g, 8),
		bit.lshift(b, 8),
		bit.lshift(a, 8)
end

function converters.rgba16.rgba8(r, g, b, a)
	return
		bit.rshift(r, 8),
		bit.rshift(g, 8),
		bit.rshift(b, 8),
		bit.rshift(a, 8)
end

function converters.ga8.ga16(g, a)
	return
		bit.lshift(g, 8),
		bit.lshift(a, 8)
end

function converters.ga16.ga8(g, a)
	return
		bit.rshift(g, 8),
		bit.rshift(a, 8)
end

local function rgb2g(r, g, b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

function converters.rgba8.ga8(r, g, b, a)
	return bit.band(rgb2g(r, g, b), 0xff), a
end

function converters.rgba16.ga16(r, g, b, a)
	return bit.band(rgb2g(r, g, b), 0xffff), a
end

function converters.icmyk8.rgba16(c, m, y, k)
	return c * k, m * k, y * k, 0xffff
end

local filters = {}

--function filters.

local writers = autotable{}

function writers.rgba8.rgb565(d,i,r,g,b,a)
	d[i] = bit.bor(bit.lshift(bit.rshift(b, 8-5), 5+6),
						bit.lshift(bit.rshift(g, 8-6), 5),
									  bit.rshift(b, 8-5))
end

function writers.rgba8.rgba4444(d,i,r,g,b,a)
	d[i] = bit.bor(bit.lshift(bit.rshift(r, 8-4), 4+4+4),
						bit.lshift(bit.rshift(g, 8-4), 4+4),
						bit.lshift(bit.rshift(b, 8-4), 4),
									  bit.rshift(a, 8-4))
end

function writers.rgba8.rgba5551(d,i,r,g,b,a)
	d[i] = bit.bor(bit.lshift(bit.rshift(r, 8-5), 5+5+1),
						bit.lshift(bit.rshift(g, 8-5), 5+1),
						bit.lshift(bit.rshift(b, 8-5), 1),
						  bit.band(bit.rshift(a, 8-1), 1))
end

function writers.rgba8.rgb24(d,i,r,g,b,a) d[i], d[i+1], d[i+2] = r,g,b end
function writers.rgba8.bgr24(d,i,r,g,b,a) d[i], d[i+1], d[i+2] = b,g,r end

function writers.rgba8.rgba32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,a end
function writers.rgba8.bgra32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,a end
function writers.rgba8.argb32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = a,r,g,b end
function writers.rgba8.abgr32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = a,b,g,r end

writers.rgba16.rgba64 = writers.rgba8.rgba32
writers.rgba16.bgra64 = writers.rgba8.bgra32
writers.rgba16.argb64 = writers.rgba8.argb32
writers.rgba16.abgr64 = writers.rgba8.abgr32

function writers.rgba8.rgbx32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,0xff end
function writers.rgba8.bgrx32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,0xff end
function writers.rgba8.xrgb32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = 0xff,r,g,b end
function writers.rgba8.xbgr32(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = 0xff,b,g,r end

function writers.ga8.g8(d,i,r,g,a) d[i] = g end
function writers.ga8.ga8(d,i,g,a) d[i], d[i+1] = g,a end
function writers.ga8.ag8(d,i,g,a) d[i], d[i+1] = a,g end

writers.ga16.g16 = writers.ga8.g8
writers.ga16.ga16 = writers.ga8.ga8
writers.ga16.ag16 = writers.ga8.ag8

writers.icmyk8.icmyk32 = writers.rgba8.rgba32

local function prepare(img)
	local format = assert(formats[img.format])
	local ctype = ffi.typeof('$ *', format.ctype)
	local bpp = format.bpp / 8 --no precision loss
	local data = ffi.cast(ctype, img.data)
	local min_stride = math.ceil(img.w * bpp)
	assert(not img.stride or img.stride >= min_stride)
	local stride = (img.stride or min_stride) / ffi.sizeof(format.ctype)
	assert(stride == math.floor(stride)) --stride must be a multiple of format's ctype size
	assert(img.orientation == 'top_down' or img.orientation == 'bottom_up')
	return data, bpp, stride
end

local function eachpixel(convert_pixel, src, dst)
	assert(src.h == dst.h)
	assert(src.w == dst.w)
	local src_data, src_bpp, src_stride = prepare(src)
	local dst_data, dst_bpp, dst_stride = prepare(dst)
	local dj = 0
	if src.orientation ~= dst.orientation then
		dj = (src.h - 1) * dst_stride --first pixel of the last row
		dst_stride = -dst_stride --...and stepping backwards
	end
	local mw = src.w-1
	for sj = 0, (src.h - 1) * src_stride, src_stride do
		--from the entire module, this is really the only loop that needs a good jit trace.
		--luajit inlines nested function calls and keeps math in integer if it can.
		for i = 0, mw do
			convert_pixel(
				dst_data, dj + i * dst_bpp,
				src_data, sj + i * src_bpp)
		end
		dj = dj + dst_stride
	end
end

local function convolve(filter, img)
	local data, bpp, stride = prepare(img)
	local ii, jj
	local function getpixel(x, y, c)
		return src_data[y * stride + x * bpp + c]
	end
	local function setrgba8(x, y, r, g, b, a)
		--write(data, y * stride + x * bpp,
	end
	for j = 0, (src.h-1) * stride, stride do
		for i = 0, (src.w-1) * bpp, bpp do
			for c = 0, bpp-1 do
				filter(src_data, getpixel, setpixel)
			end
		end
	end
end

--from http://en.wikipedia.org/wiki/Floyd%E2%80%93Steinberg_dithering
local function dither16to8(x, y, c, getpixel, setpixel)
	local oldpixel = getpixel(x, y, c)
	local newpixel = bit.band(oldpixel, 0xff00) --round by 256
	local quant_error = oldpixel - newpixel
	setpixel(x,   y,   c, newpixel)
	setpixel(x+1, y,   c, getpixel(x+1, y,   c) + 7/16 * quant_error)
	setpixel(x-1, y+1, c, getpixel(x-1, y+1, c) + 3/16 * quant_error)
	setpixel(x,   y+1, c, getpixel(x,   y+1, c) + 5/16 * quant_error)
	setpixel(x+1, y+1, c, getpixel(x+1, y+1, c) + 1/16 * quant_error)
end



if false and not ... then
local glue = require'glue'

print'formats:'
for s,t in glue.sortedpairs(formats) do
	print('', s..'      ', t.size, t.ctype)
end

function printt(s, t)
	print(s)
	for s,t in glue.sortedpairs(t) do
		for d in glue.sortedpairs(t) do
			print('', s..'      ', '->', d)
		end
	end
end
printt('readers:', readers)
printt('writers:', writers)
printt('converters:', converters)

end


local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

local function alloc(img)
	img.stride = pad_stride(formats[img.format].bpp * 8 * img.w)
	img.size = img.stride * img.h
	img.data = ffi.new('uint8_t[?]', img.size)
	return img
end

local src = alloc{w = 1921, h = 1081, format = 'icmyk32', orientation = 'top_down'}
local dst = alloc{w = 1921, h = 1081, format = 'ag8', orientation = 'bottom_up'}

local function convert_pixel(d, i, s, j)
	writers.ga8.ag8(d, i,
		converters.ga16.ga8(
			converters.rgba16.ga16(
				converters.icmyk8.rgba16(
					readers.icmyk32.icmyk8(s, j)))))
end

require'unit'

timediff()
for i=1,60 do
	eachpixel(convert_pixel, src, dst)
end
print(timediff())

