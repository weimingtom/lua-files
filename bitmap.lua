--go @ bin/luajit.exe -e io.stdout:setvbuf'no' -jv *
--bitmap conversions between different pixel formats, bitmap orientations, strides and bit depths.
local ffi = require'ffi'
local bit = require'bit'

--bitmap formats

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
formats.cmyk8 = format(32, 'uint8_t', 'cmyk8', formats.rgba8.read, formats.rgba8.write)

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

--8bpc YCC and YCCK
formats.ycc8 = format(24, 'uint8_t', 'ycc8', formats.rgb8.read, formats.rgb8.write)
formats.ycck8 = format(32, 'uint8_t', 'ycck8', formats.rgba8.read, formats.rgba8.write)

--converters between different colortypes

local conv = {rgba8 = {}, rgba16 = {}, ga8 = {}, ga16 = {}, cmyk8 = {}, ycc8 = {}, ycck8 = {}}

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

--note: we want to round the result but math.floor(x+0.5) is expensive, so we just add 0.5 and clamp
--the result instead, and let the ffi truncate the value when it writes to an integer pointer.
local function round8(x, max)
	return math.min(math.max(x + 0.5, 0), 0xff)
end

local function round16(x, max)
	return math.min(math.max(x + 0.5, 0), 0xffff)
end

--note: needs no clamping as long as the r, g, b values are within range.
local function rgb2g(r, g, b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

function conv.rgba8.ga8(r, g, b, a)
	return round8(rgb2g(r, g, b)), a
end

function conv.rgba16.ga16(r, g, b, a)
	return round16(rgb2g(r, g, b)), a
end

function conv.ga8.rgba8(g, a)
	return g, g, g, a
end

conv.ga16.rgba16 = conv.ga8.rgba8

function conv.cmyk8.rgba16(c, m, y, k)
	return c * k, m * k, y * k, 0xffff
end

function conv.ycc8.rgba8(y, cb, cr) --see http://en.wikipedia.org/wiki/YCbCr#JPEG_conversion
	return
		round8(y                        + 1.402   * (cr - 128)),
		round8(y - 0.34414 * (cb - 128) - 0.71414 * (cr - 128)),
      round8(y + 1.772   * (cb - 128)),
		0xff
end

function conv.ycck8.cmyk8(y, cb, cr, k)
	local r, g, b = conv.ycc8.rgba8(y, cb, cr)
	return 255 - r, 255 - g, 255 - b, k
end

--composite converters

function conv.ga16.rgba8(g, a) return conv.rgba16.rgba8(conv.ga16.rgba16(g, a)) end
function conv.ga8.rgba16(g, a) return conv.ga16.rgba16(conv.ga8.ga16(g, a)) end
function conv.rgba16.ga8(r, g, b, a) return conv.ga16.ga8(conv.rgba16.ga16(r, g, b, a)) end
function conv.rgba8.ga16(r, g, b, a) return conv.rgba16.ga16(conv.rgba8.rgba16(r, g, b, a)) end

function conv.cmyk8.rgba8(c, m, y, k) return conv.rgba16.rgba8(conv.cmyk8.rgba16(c, m, y, k)) end
function conv.cmyk8.ga16(c, m, y, k) return conv.rgba16.ga16(conv.cmyk8.rgba16(c, m, y, k)) end
function conv.cmyk8.ga8(c, m, y, k) return conv.ga16.ga8(conv.rgba16.ga16(conv.cmyk8.rgba16(c, m, y, k))) end

function conv.ycc8.rgba16(y, cb, cr) return conv.rgba8.rgba16(conv.ycc8.rgba8(y, cb, cr)) end
function conv.ycc8.ga16(y, cb, cr) return conv.rgba16.ga16(conv.rgba8.rgba16(conv.ycc8.rgba8(y, cb, cr))) end
function conv.ycc8.ga8(y, cb, cr) return conv.rgba8.ga8(conv.ycc8.rgba8(y, cb, cr)) end

function conv.ycck8.rgba16(y, cb, cr, k) return conv.cmyk8.rgba16(conv.ycck8.cmyk8(y, cb, cr, k)) end
function conv.ycck8.rgba8(y, cb, cr, k) return conv.cmyk8.rgba8(conv.ycck8.cmyk8(y, cb, cr, k)) end
function conv.ycck8.ga16(y, cb, cr, k)
	return conv.rgba16.ga16(conv.cmyk8.rgba16(conv.ycck8.cmyk8(y, cb, cr, k)))
end
function conv.ycck8.ga8(y, cb, cr, k) return
	conv.ga16.ga8(conv.rgba16.ga16(conv.cmyk8.rgba16(conv.ycck8.cmyk8(y, cb, cr, k))))
end

--bitmap objects

local function valid_format(format)
	return type(format) == 'string'
				and assert(formats[format], 'invalid format') --standard format
				or assert(format, 'format missing') --custom format
end

local function aligned_stride(stride) --smallest stride that is a multiple of 4 bytes
	return bit.band(math.ceil(stride) + 3, bit.bnot(3))
end

local function min_stride(format, w) --minimum stride for a specific format
	return w * valid_format(format).bpp / 8 --stride is fractional for < 8bpp formats, that's ok.
end

local function valid_stride(format, w, stride, aligned) --validate stride against min. stride or min. stride
	local min_stride = min_stride(format, w)
	stride = stride or min_stride
	stride = aligned and aligned_stride(stride) or stride
	assert(stride >= min_stride, 'invalid stride')
	return stride
end

local function bitmap_stride(bmp)
	return valid_stride(bmp.format, bmp.w, bmp.stride)
end

local function bitmap_row_size(bmp) --can be fractional
	return min_stride(bmp.format, bmp.w)
end

local function bitmap_format(bmp)
	return valid_format(bmp.format)
end

local function new(w, h, format, bottom_up, stride_aligned, stride)
	stride = valid_stride(format, w, stride, stride_aligned)
	local size = math.ceil(stride * h)
	local data = ffi.new('uint8_t[?]', size)
	return {w = w, h = h, format = format, bottom_up = bottom_up or nil, stride = stride, data = data, size = size}
end

--low-level bitmap interface for random access to pixels

local function data_interface(bmp)
	local format = bitmap_format(bmp)
	local data = ffi.cast(ffi.typeof('$ *', format.ctype), bmp.data)
	local stride = valid_stride(bmp.format, bmp.w, bmp.stride)
	local stride = stride / ffi.sizeof(format.ctype) --stride is now in units of ctype, not bytes!
	local pixelsize = format.bpp / 8 / ffi.sizeof(format.ctype) --pixelsize is fractional for < 8bpp formats, that's ok.
	return format, data, stride, pixelsize
end

--hi-level bitmap interface for random access to pixels

local function pixel_interface(bmp)
	local format, data, stride, pixelsize = data_interface(bmp)
	local function getpixel(x, y)
		return format.read(data, y * stride + x * pixelsize)
	end
	local function setpixel(x, y, ...)
		format.write(data, y * stride + x * pixelsize, ...)
	end
	return getpixel, setpixel
end

--bitmap converter

local function convert(src, dst, convert_pixel)
	assert(src.h == dst.h)
	assert(src.w == dst.w)
	local src_format, src_data, src_stride, src_pixelsize = data_interface(src)
	local dst_format, dst_data, dst_stride, dst_pixelsize = data_interface(dst)

	--try to copy the bitmap whole
	if src_format == dst_format
		and not convert_pixel
		and src_stride == dst_stride
		and not src.bottom_up == not dst.bottom_up
	then
		if src.data ~= dst.data then
			assert(src.size == dst.size)
			ffi.copy(dst.data, src.data, dst.size)
		end
		return dst
	end

	--check that dest. pixels would not be written ahead of source pixels
	assert(src.data ~= dst.data or (
		dst_format.bpp <= src_format.bpp
		and dst_stride <= src_stride
		and not src.bottom_up == not dst.bottom_up))

	--dest. starting index and step, depending on whether the orientation is different.
	local dj = 0
	if not src.bottom_up ~= not dst.bottom_up then
		dj = (src.h - 1) * dst_stride --first pixel of the last row
		dst_stride = -dst_stride --...and stepping backwards
	end

	--try to copy the bitmap row-by-row
	local src_rowsize = bitmap_row_size(src)
	if
		src_format == dst_format
		and not convert_pixel
		and src_stride == math.floor(src_stride) --we can't copy from fractional offsets
		and dst_stride == math.floor(dst_stride) --we can't copy from fractional offsets
		and src_rowsize == math.floor(src_rowsize) --we can't copy fractional row sizes
	then
		for sj = 0, (src.h - 1) * src_stride, src_stride do
			ffi.copy(dst.data + dj, src.data + sj, src_rowsize)
			dj = dj + dst_stride
		end
		return dst
	end

	--convert the bitmap pixel-by-pixel
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

--bitmap copy

local function copy(src, format, bottom_up, stride_aligned, stride)
	if not format then
		format = src.format
		if bottom_up == nil then bottom_up = src.bottom_up end
		stride = stride or src.stride
	end
	return convert(src, new(src.w, src.h, format, bottom_up, stride_aligned, stride))
end

--bitmap converter reflection/reporting

local function conversions(src_format)
	src_format = valid_format(src_format)
	return coroutine.wrap(function()
		for dname, dst_format in pairs(formats) do
			if dst_format.colortype == src_format.colortype then
				coroutine.yield(dname, dst_format)
			end
		end
		for dst_colortype in pairs(conv[src_format.colortype]) do
			for dname, dst_format in pairs(formats) do
				if dst_format.colortype == dst_colortype then
					coroutine.yield(dname, dst_format)
				end
			end
		end
	end)
end

local function dumpinfo()
	local glue = require'glue'
	local function enumkeys(t)
		t = glue.keys(t)
		table.sort(t)
		return table.concat(t, ', ')
	end
	print'formats:	bpp	ctype			colortype	conversions'
	for s,t in glue.sortedpairs(formats) do
		local ct = {}; for d in conversions(s) do ct[#ct+1] = d; end; table.sort(ct)
		print('  '..s..'     ', t.bpp, t.ctype, t.colortype, '', table.concat(ct, ', '))
	end
	print'converters:'
	for s,t in glue.sortedpairs(conv) do
		print('  '..s..'     ', '->', enumkeys(t))
	end
end

--dithering algorithms (only 4 channel colortypes for now)

local dither = {}

--floyd-steinberg dithering

local function fs_dither_4c(x, maxval, r1, g1, b1, a1, r0, g0, b0, a0)
	return
		math.min(r0 + bit.rshift(x * r1, 4), maxval),
		math.min(g0 + bit.rshift(x * g1, 4), maxval),
		math.min(b0 + bit.rshift(x * b1, 4), maxval),
		math.min(a0 + bit.rshift(x * a1, 4), maxval)
end

local fs_maxbits = {rgba8 = 8, rgba16 = 16, cmyk8 = 8}

function dither.fs(src, rbits, gbits, bbits, abits)
	local maxbits = assert(fs_maxbits[valid_format(src.format).colortype], 'invalid colortype')
	local getpixel, setpixel = pixel_interface(src)
	local maxval = 2^maxbits-1
	local rmask = 2^(maxbits-rbits)-1
	local gmask = 2^(maxbits-gbits)-1
	local bmask = 2^(maxbits-bbits)-1
	local amask = 2^(maxbits-abits)-1
	for y = 0, src.h-1 do
		for x = 0, src.w-1 do
			local r0, g0, b0, a0 = getpixel(x, y)
			local r1 = bit.band(r0, rmask)
			local g1 = bit.band(g0, gmask)
			local b1 = bit.band(b0, bmask)
			local a1 = bit.band(a0, amask)
			setpixel(x, y,
				bit.band(r0, maxval-rmask),
				bit.band(g0, maxval-gmask),
				bit.band(b0, maxval-bmask),
				bit.band(a0, maxval-amask))
			if x < src.w-1 then
				setpixel(x+1, y, fs_dither_4c(7, maxval, r1, g1, b1, a1, getpixel(x+1, y)))
			end
			if y < src.h-1 and x > 0 then
				setpixel(x-1, y+1, fs_dither_4c(3, maxval, r1, g1, b1, a1, getpixel(x-1, y+1)))
			end
			if y < src.h-1 then
				setpixel(x, y+1, fs_dither_4c(5, maxval, r1, g1, b1, a1, getpixel(x, y+1)))
			end
			if y < src.h-1 and x < src.w-1 then
				setpixel(x+1, y+1, fs_dither_4c(1, maxval, r1, g1, b1, a1, getpixel(x+1, y+1)))
			end
		end
	end
end

--ordered dithering

local tmap = {[2] = {}, [3] = {}, [4] = {}, [8] = {}} --threshold maps from wikipedia

tmap[2] = {[0] =
	{[0] = 1, 3},
	{[0] = 4, 2}}

tmap[3] = {[0] =
	{[0] = 3, 7, 4},
	{[0] = 6, 1, 9},
	{[0] = 2, 8, 5}}

tmap[4] = {[0] =
	{[0] =  1,  9,  3, 11},
	{[0] = 13,  5, 15,  7},
	{[0] =  4, 12,  2, 10},
	{[0] = 16,  8, 14, 6}}

tmap[8] = {[0] =
	{[0] =  1, 49, 13, 61,  4, 52, 16, 64},
	{[0] = 33, 17, 45, 29, 36, 20, 48, 32},
	{[0] =  9, 57,  5, 53, 12, 60,  8, 56},
	{[0] = 41, 25, 37, 21, 44, 28, 40, 24},
	{[0] =  3, 51, 15, 63,  2, 50, 14, 62},
	{[0] = 35, 19, 47, 31, 34, 18, 46, 30},
	{[0] = 11, 59,  7, 55, 10, 58,  6, 54},
	{[0] = 43, 27, 39, 23, 42, 26, 38, 22}}

--note: actual clipping of the low bits is not done here, it will be done naturally
--when converting the bitmap to lower bpc.
local function od_4c(t, maxval, r, g, b, a)
	return
		math.min(r + t, maxval),
		math.min(g + t, maxval),
		math.min(b + t, maxval),
		math.min(a + t, maxval)
end

local function od_2c(t, maxval, g, a)
	return
		math.min(g + t, maxval),
		math.min(a + t, maxval)
end

local ordered_maxval = {rgba8 = 0xff, rgba16 = 0xffff, cmyk8 = 0xff, ga8 = 0xff, ga16 = 0xffff}
local ordered_kernel = {rgba8 = od_4c, rgba16 = od_4c, cmyk8 = od_4c, ga8 = od_2c, ga16 = od_2c}

function dither.ordered(src, map)
	local colortype = valid_format(src.format).colortype
	local maxval = assert(ordered_maxval[colortype], 'invalid colortype')
	local kernel = ordered_kernel[colortype]
	local getpixel, setpixel = pixel_interface(src)
	local tmap = assert(tmap[map], 'invalid map size')
	for y = 0, src.h-1 do
		local tmap = tmap[bit.band(y, map-1)]
		for x = 0, src.w-1 do
			local t = tmap[bit.band(x, map-1)]
			setpixel(x, y, kernel(t, maxval, getpixel(x, y)))
		end
	end
end

if not ... then require'bitmap_demo' end

return {
	--format/stride API
	valid_format = valid_format,
	aligned_stride = aligned_stride,
	min_stride = min_stride,
	valid_stride = valid_stride,
	--bitmap API
	format = bitmap_format,
	stride = bitmap_stride,
	row_size = bitmap_row_size,
	new = new,
	data_interface = data_interface,
	pixel_interface = pixel_interface,
	convert = convert,
	copy = copy,
	dither = dither,
	--inspection API
	formats = formats,
	converters = conv,
	conversions = conversions,
	dumpinfo = dumpinfo,
}

