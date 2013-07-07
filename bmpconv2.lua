--go @ bin/luajit.exe -jdump *
--bitmap conversions between different pixel formats, bitmap orientations, strides and bit depths.
--TODO: separate plane formats?
--TODO: alpha premultiply/unpremultiply converters
--TODO: reading and writing from/to different palette formats instead of using user-supplied callbacks
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

local function format(bpp, ctype, colortype, read, write)
	return {bpp = bpp, ctype = ffi.typeof(ctype), colortype = colortype, read = read, write = write}
end

local formats = {}

--8bpc RGB, BGR
formats.rgb8 = format(24, 'uint8_t', 'rgba8',
	function(s,i) return s[i], s[i+1], s[i+2], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2] = r,g,b end)

formats.bgr8 = format(24, 'uint8_t', 'rgba8',
	function(s,i) return s[i+2], s[i+1], s[i], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2] = b,g,r end)

--16bpc RGB, BGR
formats.rgb16 = format(48, 'uint16_t', 'rgba16',
	function(s,i) return s[i], s[i+1], s[i+2], 0xffff end,
	formats.rgb8.write)
formats.bgr16 = format(48, 'uint16_t', 'rgba16',
	function(s,i) return s[i+2], s[i+1], s[i], 0xffff end,
	formats.bgr8.write)

--8bpc RGBX, BGRX, XRGB, XBGR
formats.rgbx8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i], s[i+1], s[i+2], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,0xff end)

formats.bgrx8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+2], s[i+1], s[i], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,0xff end)

formats.xrgb8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+1], s[i+2], s[i+3], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xff,r,g,b end)

formats.xbgr8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+3], s[i+2], s[i+1], 0xff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xff,b,g,r end)

--16bpc RGBX, BGRX, XRGB, XBGR
formats.rgbx16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i], s[i+1], s[i+2], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,0xffff end)

formats.bgrx16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i+2], s[i+1], s[i], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,0xffff end)

formats.xrgb16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i+1], s[i+2], s[i+3], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xffff,r,g,b end)

formats.xbgr16 = format(64, 'uint16_t', 'rgba16',
	function(s,i) return s[i+3], s[i+2], s[i+1], 0xffff end,
	function(d,i,r,g,b) d[i], d[i+1], d[i+2], d[i+3] = 0xffff,b,g,r end)

--8bpc RGBA, BGRA, ARGB, ARGB
formats.rgba8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i], s[i+1], s[i+2], s[i+3] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = r,g,b,a end)

formats.bgra8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+2], s[i+1], s[i], s[i+3] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = b,g,r,a end)

formats.argb8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+1], s[i+2], s[i+3], s[i] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = a,r,g,b end)

formats.abgr8 = format(32, 'uint8_t', 'rgba8',
	function(s,i) return s[i+3], s[i+2], s[i+1], s[i] end,
	function(d,i,r,g,b,a) d[i], d[i+1], d[i+2], d[i+3] = a,b,g,r end)

--16bpc RGBA, BGRA, ARGB, ABGR
formats.rgba16 = format(64, 'uint16_t', 'rgba16', formats.rgba8.read, formats.rgba8.write)
formats.bgra16 = format(64, 'uint16_t', 'rgba16', formats.bgra8.read, formats.bgra8.write)
formats.argb16 = format(64, 'uint16_t', 'rgba16', formats.argb8.read, formats.argb8.write)
formats.abgr16 = format(64, 'uint16_t', 'rgba16', formats.abgr8.read, formats.abgr8.write)

--8bpc GRAY and GRAY+APLHA
formats.g8  = format( 8, 'uint8_t', 'ga8',
	function(s,i)  return s[i], 0xff end,
	function(d,i,r,g,a) d[i] = g end)

formats.ga8 = format(16, 'uint8_t', 'ga8',
	function(s,i) return s[i], s[i+1] end,
	function(d,i,g,a) d[i], d[i+1] = g,a end)

formats.ag8 = format(16, 'uint8_t', 'ga8',
	function(s,i) return s[i+1], s[i] end,
	function(d,i,g,a) d[i], d[i+1] = a,g end)

--16bpc GRAY and GRAY+ALPHA
formats.g16  = format(16, 'uint16_t', 'ga16',
	function(s,i) return s[i], 0xffff end,
	formats.g8.write)

formats.ga16 = format(32, 'uint16_t', 'ga16', formats.ga8.read, formats.ga8.write)
formats.ag16 = format(32, 'uint16_t', 'ga16', formats.ag8.read, formats.ag8.write)

--8bpc INVERSE CMYK
formats.icmyk8 = format(32, 'uint8_t', 'icmyk8', formats.rgba8.read, formats.rgba8.write)

--make a RGBA format from a 16bpp or 32bpp R.G.B.A.X specification.
local function rgbax_format(bpp, r, g, b, a, x)
	assert(bpp == 16 or bpp == 32)
	assert(r + g + b + a + x == bpp)
	assert(r <= 8 and g <= 8 and b <= 8 and a <= 8)

	local maxr = (2^r-1)
	local maxg = (2^g-1)
	local maxb = (2^b-1)
	local maxa = (2^a-1)
	local rfactor = 255 / maxr
	local gfactor = 255 / maxg
	local bfactor = 255 / maxb
	local afactor = 255 / maxa
	local function read(s,i)
		return
			         bit.rshift(s[i], g+b+a+x)        * rfactor,
			bit.band(bit.rshift(s[i],   b+a+x), maxg) * gfactor,
			bit.band(bit.rshift(s[i],     a+x), maxb) * bfactor,
			a > 0 and
			bit.band(bit.rshift(s[i],       x), maxa) * afactor or 0xff
	end

	local function write(d,i,r1,g1,b1,a1)
		d[i] = bit.bor(bit.lshift(bit.rshift(r1, 8-r), g+b+a+x),
							bit.lshift(bit.rshift(g1, 8-g),   b+a+x),
							bit.lshift(bit.rshift(b1, 8-b),     a+x),
							a > 0 and
							bit.lshift(bit.rshift(a1, 8-a),       x) or 0)
	end

	return format(bpp, (bpp == 16 and 'uint16_t' or 'uint32_t'), 'rgba8', read, write)
end

--16bpp RGB and RGBA
formats.rgb565   = rgbax_format(16, 5, 6, 5, 0, 0)
formats.rgba4444 = rgbax_format(16, 4, 4, 4, 4, 0)
formats.rgba5551 = rgbax_format(16, 5, 5, 5, 1, 0)
formats.rgb555   = rgbax_format(16, 5, 5, 5, 0, 1)
formats.rgb444   = rgbax_format(16, 4, 4, 4, 0, 4)

--sub-byte (< 8bpp) formats
formats.g1  = format(1, 'uint8_t', 'ga8')
formats.g2  = format(2, 'uint8_t', 'ga8')
formats.g4  = format(4, 'uint8_t', 'ga8')

function formats.g1.read(s,i)
	local sbit = bit.band(i * 8, 7) --i is fractional, that's why this works.
	return bit.band(bit.rshift(s[i], 7-sbit), 1) * 255, 0xff
end

function formats.g2.read(s,i)
	local sbit = bit.band(i * 8, 7) --0,2,4,6
	return bit.band(bit.rshift(s[i], 6-sbit), 3) * (255 / 3), 0xff
end

function formats.g4.read(s,i)
	local sbit = bit.band(i * 8, 7) --0,4
	return bit.band(bit.rshift(s[i], 4-sbit), 15) * (255 / 15), 0xff
end

function formats.g1.write(d,i,g,a)
	local dbit = bit.band(i * 8, 7) --0-7
	bit.bor(
		bit.band(d[i], bit.rshift(0xffff-0x80, dbit), --clear the bit
		bit.rshift(bit.band(g, 0x80), dbit))) --set the bit
end

function formats.g2.write(d,i,g,a)
	local dbit = bit.band(i * 8, 7) --0,2,4,6
	d[i] = bit.bor(
		bit.band(d[i], bit.rshift(0xffff-0xC0, dbit), --clear the bits
		bit.rshift(bit.band(g, 0xC0), dbit))) --set the bits
end

function formats.g4.write(d,i,g,a)
	local dbit = bit.band(i * 8, 7) --0,4
	d[i] = bit.bor(
		bit.band(d[i], bit.rshift(0xffff-0xf0, dbit), --clear the bits
		bit.rshift(bit.band(g, 0xf0), dbit))) --set the bits
end

--palette formats
formats.map1  = format( 1, 'uint8_t',  'map')
formats.map2  = format( 2, 'uint8_t',  'map')
formats.map4  = format( 4, 'uint8_t',  'map')
formats.map8  = format( 8, 'uint8_t',  'map')
formats.map16 = format(16, 'uint16_t', 'map')

function formats.map8.read(s, i, src) return src.map.read(s[i]) end
function formats.map8.write(d, i, dst, g, a) d[i] = dst.map.write(g, a) end

--converters between the different color types returned by readers and accepted by writers

local converters = autotable{}

function converters.rgba8.rgba16(r, g, b, a)
	return
		r * (65535 / 255),
		g * (65535 / 255),
		b * (65535 / 255),
		a * (65535 / 255)
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
		g * (65535 / 255),
		a * (65535 / 255)
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

function converters.ga8.rgba8(g, a)
	return g, g, g, a
end

converters.ga16.rgba16 = converters.ga8.rgba8

function converters.icmyk8.rgba16(c, m, y, k)
	return c * k, m * k, y * k, 0xffff
end

--the bitmap sweeper that calls the pixel converter for each pixel the two bitmaps

local function prepare(img)
	local format = type(img.format) == 'string'
						and assert(formats[img.format], 'unknown format') --standard format
						or img.format --custom format
	local ctype = ffi.typeof('$ *', format.ctype)
	local data = ffi.cast(ctype, img.data)
	local min_stride = img.w * format.bpp / 8 --stride is fractional for < 8bpp formats, that's ok, we need it like that.
	assert(not img.stride or img.stride >= min_stride)
	local stride = (img.stride or min_stride) / ffi.sizeof(format.ctype) --stride is now in units of ctype, not bytes!
	assert(img.orientation == 'top_down' or img.orientation == 'bottom_up')
	local pixelsize = format.bpp / 8 / ffi.sizeof(format.ctype) --pixelsize is fractional for < 8bpp formats, that's ok.
	return data, stride, pixelsize, format
end

local function eachpixel(src, dst, convert)
	assert(src.h == dst.h)
	assert(src.w == dst.w)
	local src_data, src_stride, src_pixelsize, src_format = prepare(src)
	local dst_data, dst_stride, dst_pixelsize, dst_format = prepare(dst)
	local dj = 0
	if src.orientation ~= dst.orientation then
		dj = (src.h - 1) * dst_stride --first pixel of the last row
		dst_stride = -dst_stride --...and stepping backwards
	end
	local read = src_format.read
	local write = dst_format.write
	for sj = 0, (src.h - 1) * src_stride, src_stride do
		for i = 0, src.w-1 do
			if convert then
				write(dst_data, dj + i * dst_pixelsize, convert(read(src_data, sj + i * src_pixelsize)))
			else
				write(dst_data, dj + i * dst_pixelsize, read(src_data, sj + i * src_pixelsize))
			end
		end
		dj = dj + dst_stride
	end
end

--local matrix = {}

local function mkconverter(src, dst)
	--
end

--bitmap convolution driver

local function convolve(filter, img)
	local data, pixelsize, stride, format = prepare(img)
	local function pixeladdress(x, y)
		return y * stride + x * pixelsize
	end
	for y = 0, (img.h-1) * stride, stride do
		for x = 0, (img.w-1) * pixelsize, pixelsize do
			filter(data, x, y, pixeladdress)
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



if not ... then
local glue = require'glue'
function enumkeys(t)
	t = glue.keys(t)
	table.sort(t)
	return table.concat(t, ', ')
end
print'formats:	bpp	ctype			colortype'
for s,t in glue.sortedpairs(formats) do
	print('  '..s..'     ', t.bpp, t.ctype, t.colortype)
end
print'converters:'
for s,t in glue.sortedpairs(converters) do
	print('  '..s..'     ', enumkeys(t))
end

require'bmpconv2_test'

end

return {
	eachpixel = eachpixel,
	formats = formats,
	converters = converters,
}

