--go @ bin/luajit.exe -e io.stdout:setvbuf'no' -jdump *
--bitmap conversions between different pixel formats, bitmap orientations, strides and bit depths.
--formats: rgb8 rgb16 rgbx8 rgbx16 rgba8 rgba16 rgb565 rgba4444 rgba5551 rgb555 rgb444 icmyk8 g8 g16 ga8 ga16 g4 g2 g1.
local ffi = require'ffi'
local bit = require'bit'

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
	function(d,i,g,a) d[i] = g end)

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

--16bpp RGB and RGBA
formats.rgb565 = format(16, 'uint16_t', 'rgba8')

function formats.rgb565.read(s,i)
	return
					bit.rshift(s[i], 11)      * (255 / 31),
		bit.band(bit.rshift(s[i],  5), 63) * (255 / 63),
		bit.band(           s[i],      31) * (255 / 31), 0xff
end

function formats.rgb565.write(d,i,r,g,b)
	d[i] = bit.bor(bit.lshift(bit.rshift(r, 3), 11),
						bit.lshift(bit.rshift(g, 2),  5),
						           bit.rshift(b, 3))
end

formats.rgba4444 = format(16, 'uint16_t', 'rgba8')

function formats.rgba4444.read(s,i)
	return
					bit.rshift(s[i], 12)      * (255 / 15),
		bit.band(bit.rshift(s[i],  8), 15) * (255 / 15),
		bit.band(bit.rshift(s[i],  4), 15) * (255 / 15),
		bit.band(           s[i],      15) * (255 / 15)
end

function formats.rgba4444.write(d,i,r,g,b,a)
	d[i] = bit.bor(bit.lshift(bit.rshift(r, 4), 12),
						bit.lshift(bit.rshift(g, 4),  8),
						bit.lshift(bit.rshift(b, 4),  4),
						           bit.rshift(a, 4))
end

formats.rgba5551 = format(16, 'uint16_t', 'rgba8')

function formats.rgba5551.read(s,i)
	return
					bit.rshift(s[i], 11)      * (255 / 31),
		bit.band(bit.rshift(s[i],  6), 31) * (255 / 31),
		bit.band(bit.rshift(s[i],  1), 31) * (255 / 31),
		bit.band(           s[i],       1) *  255
end

function formats.rgba5551.write(d,i,r,g,b,a)
	d[i] = bit.bor(bit.lshift(bit.rshift(r, 3), 11),
						bit.lshift(bit.rshift(g, 3),  6),
						bit.lshift(bit.rshift(b, 3),  1),
						           bit.rshift(a, 7))
end

formats.rgb555 = format(16, 'uint16_t', 'rgba8')

function formats.rgb555.read(s,i)
	return
					bit.rshift(s[i], 11)      * (255 / 31),
		bit.band(bit.rshift(s[i],  6), 31) * (255 / 31),
		bit.band(bit.rshift(s[i],  1), 31) * (255 / 31), 0xff
end

function formats.rgb555.write(d,i,r,g,b)
	d[i] = bit.bor(bit.lshift(bit.rshift(r, 3), 11),
						bit.lshift(bit.rshift(g, 3),  6),
						bit.lshift(bit.rshift(b, 3),  1))
end

formats.rgb444 = format(16, 'uint16_t', 'rgba8')

function formats.rgb444.read(s,i)
	return
					bit.rshift(s[i], 12)      * (255 / 15),
		bit.band(bit.rshift(s[i],  8), 15) * (255 / 15),
		bit.band(bit.rshift(s[i],  4), 15) * (255 / 15), 0xff
end

function formats.rgb444.write(d,i,r,g,b)
	d[i] = bit.bor(bit.lshift(bit.rshift(r, 4), 12),
						bit.lshift(bit.rshift(g, 4),  8),
						bit.lshift(bit.rshift(b, 4),  4))
end

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
	d[i] = bit.bor(
				bit.band(d[i], bit.rshift(0xffff-0x80, dbit)), --clear the bit
				bit.rshift(bit.band(g, 0x80), dbit)) --set the bit
end

function formats.g2.write(d,i,g,a)
	local dbit = bit.band(i * 8, 7) --0,2,4,6
	d[i] = bit.bor(
				bit.band(d[i], bit.rshift(0xffff-0xC0, dbit)), --clear the bits
				bit.rshift(bit.band(g, 0xC0), dbit)) --set the bits
end

function formats.g4.write(d,i,g,a)
	local dbit = bit.band(i * 8, 7) --0,4
	d[i] = bit.bor(
				bit.band(d[i], bit.rshift(0xffff-0xf0, dbit)), --clear the bits
				bit.rshift(bit.band(g, 0xf0), dbit)) --set the bits
end

--converters between the different color types returned by readers and accepted by writers

local conv = autotable{}

function conv.rgba8.rgba16(r, g, b, a)
	return
		r * (65535 / 255),
		g * (65535 / 255),
		b * (65535 / 255),
		a * (65535 / 255)
end

function conv.rgba16.rgba8(r, g, b, a)
	return
		bit.rshift(r, 8),
		bit.rshift(g, 8),
		bit.rshift(b, 8),
		bit.rshift(a, 8)
end

function conv.ga8.ga16(g, a)
	return
		g * (65535 / 255),
		a * (65535 / 255)
end

function conv.ga16.ga8(g, a)
	return
		bit.rshift(g, 8),
		bit.rshift(a, 8)
end

local function rgb2g(r, g, b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

function conv.rgba8.ga8(r, g, b, a)
	return bit.band(rgb2g(r, g, b), 0xff), a
end

function conv.rgba16.ga16(r, g, b, a)
	return bit.band(rgb2g(r, g, b), 0xffff), a
end

function conv.ga8.rgba8(g, a)
	return g, g, g, a
end

conv.ga16.rgba16 = conv.ga8.rgba8

function conv.icmyk8.rgba16(c, m, y, k)
	return c * k, m * k, y * k, 0xffff
end

--composite converters

function conv.ga16.rgba8(g, a) return conv.rgba16.rgba8(conv.ga16.rgba16(g, a)) end
function conv.ga8.rgba16(g, a) return conv.ga16.rgba16(conv.ga8.ga16(g, a)) end
function conv.icmyk8.rgba8(c, m, y, k) return conv.rgba16.rgba8(conv.icmyk8.rgba16(c, m, y, k)) end
function conv.icmyk8.ga16(c, m, y, k) return conv.rgba16.ga16(conv.icmyk8.rgba16(c, m, y, k)) end
function conv.icmyk8.ga8(c, m, y, k) return conv.ga16.ga8(conv.rgba16.ga16(conv.icmyk8.rgba16(c, m, y, k))) end
function conv.rgba16.ga8(r, g, b, a) return conv.ga16.ga8(conv.rgba16.ga16(r, g, b, a)) end
function conv.rgba8.ga16(r, g, b, a) return conv.ga8.ga16(conv.rgba8.ga8(r, g, b, a)) end

--format helpers

local function valid_format(format)
	return type(format) == 'string'
				and assert(formats[format], 'invalid format') --standard format
				or assert(format, 'format missing') --custom format
end

local function aligned_stride(stride) --smallest stride that is a multiple of 4 bytes
	return bit.band(math.ceil(stride) + 3, bit.bnot(3))
end

local function min_stride(format, w, aligned) --minimum stride (dword aligned or not) for a specific format
	local stride = w * valid_format(format).bpp / 8 --stride is fractional for < 8bpp formats, that's ok.
	return aligned and aligned_stride(stride) or stride
end

local function valid_stride(format, w, stride, aligned) --validate stride against min. stride or min. stride
	local min_stride = min_stride(format, w, aligned)
	local stride = stride or min_stride
	assert(stride >= min_stride, 'invalid stride')
	return stride
end

local function image_stride(img) --get/validate image stride
	return valid_stride(img.format, img.w, img.stride)
end

local function alloc(img, stride_aligned) --allocate or reallocate an image's buffer
	img.stride = valid_stride(img.format, img.w, img.stride, stride_aligned)
	img.size = math.ceil(img.stride * img.h)
	img.data = ffi.new('uint8_t[?]', img.size)
	return img
end

--bitmap converter between two bitmaps of same size but different formats.

local function prepare(img)
	local format = valid_format(img.format)
	local data = ffi.cast(ffi.typeof('$ *', format.ctype), img.data)
	local stride = image_stride(img) / ffi.sizeof(format.ctype) --stride is now in units of ctype, not bytes!
	local pixelsize = format.bpp / 8 / ffi.sizeof(format.ctype) --pixelsize is fractional for < 8bpp formats, that's ok.
	assert(img.orientation == 'top_down' or img.orientation == 'bottom_up')
	return data, stride, pixelsize, format
end

local function convert(src, dst, convert_pixel)
	assert(src.h == dst.h)
	assert(src.w == dst.w)
	local src_data, src_stride, src_pixelsize, src_format = prepare(src)
	local dst_data, dst_stride, dst_pixelsize, dst_format = prepare(dst)
	local dj = 0
	if src.orientation ~= dst.orientation then
		dj = (src.h - 1) * dst_stride --first pixel of the last row
		dst_stride = -dst_stride --...and stepping backwards
	end
	if not convert_pixel and src_format.colortype ~= dst_format.colortype then
		convert_pixel = assert(conv[src_format.colortype][dst_format.colortype], 'invalid conversion')
	end
	for sj = 0, (src.h - 1) * src_stride, src_stride do
		for i = 0, src.w-1 do
			if convert_pixel then
				dst_format.write(dst_data, dj + i * dst_pixelsize, convert_pixel(
					src_format.read(src_data, sj + i * src_pixelsize)))
			else
				dst_format.write(dst_data, dj + i * dst_pixelsize,
					src_format.read(src_data, sj + i * src_pixelsize))
			end
		end
		dj = dj + dst_stride
	end
	return dst
end

--reflection/reporting

local function dumpinfo()
	local glue = require'glue'
	local function enumkeys(t)
		t = glue.keys(t)
		table.sort(t)
		return table.concat(t, ', ')
	end
	print'formats:	bpp	ctype			colortype'
	for s,t in glue.sortedpairs(formats) do
		print('  '..s..'     ', t.bpp, t.ctype, t.colortype)
	end
	print'converters:'
	for s,t in glue.sortedpairs(conv) do
		print('  '..s..'     ', '->', enumkeys(t))
	end
end

if not ... then require'bmpconv_test' end

return {
	formats = formats,
	converters = conv,
	alloc = alloc,
	convert = convert,
	dumpinfo = dumpinfo,
}

