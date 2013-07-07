local ffi = require'ffi'
local bit = require'bit'
local bmpconv = require'bmpconv2'
local formats = bmpconv.formats
local converters = bmpconv.converters
local eachpixel = bmpconv.eachpixel

local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

local function alloc(img)
	--img.stride = pad_stride(math.ceil((formats[img.format].bpp / 8) * img.w))
	img.stride = img.w * formats[img.format].bpp / 8
	img.size = img.stride * img.h
	img.data = ffi.new('uint8_t[?]', img.size)
	return img
end

local function alloc_map(img)
	img.map = {rgba8 = {}}
	function img.map.rgba8.write(r, g, b, a)
		return 1
	end
	function img.map.rgba8.read(i)
		return 1, 2, 3, 4
	end
	return alloc(img)
end

local icmyk8   = alloc{w = 1921, h = 1081, format = 'icmyk8', orientation = 'top_down'}
local rgba4444 = alloc{w = 1921, h = 1081, format = 'rgba4444', orientation = 'top_down'}
local rgb565   = alloc{w = 1921, h = 1081, format = 'rgb565', orientation = 'top_down'}
local ag8      = alloc{w = 1921, h = 1081, format = 'ag8', orientation = 'top_down'}
local rgba8    = alloc{w = 1921, h = 1081, format = 'rgba8', orientation = 'top_down'}
local rgba8_2  = alloc{w = 1921, h = 1081, format = 'rgba8', orientation = 'top_down'}
local rgb8     = alloc{w = 1921, h = 1081, format = 'rgb8', orientation = 'top_down'}
local rgb8_2   = alloc{w = 1921, h = 1081, format = 'rgb8', orientation = 'top_down'}

local g1       = alloc{w = 1921, h = 1081, format = 'g1', orientation = 'top_down'}
local g2       = alloc{w = 1921, h = 1081, format = 'g2', orientation = 'top_down'}
local g4       = alloc{w = 1921, h = 1081, format = 'g4', orientation = 'top_down'}
local ga8      = alloc{w = 1921, h = 1081, format = 'ga8', orientation = 'top_down'}
local ga8_2    = alloc{w = 1921, h = 1081, format = 'ga8', orientation = 'top_down'}

local map8     = alloc_map{w = 1921, h = 1081, format = 'map8', orientation = 'top_down'}
local map8_2   = alloc_map{w = 1921, h = 1081, format = 'map8', orientation = 'top_down'}

local function icmyk8_ag8(c, m, y, k)
	return
		converters.ga16.ga8(
			converters.rgba16.ga16(
				converters.icmyk8.rgba16(c, m, y, k)))
end

require'unit'
local function convert(src, dst, conv)
	timediff()
	for i=1,1 do
		eachpixel(src, dst, conv)
	end
	print(timediff(),
		src.format .. '       ', dst.format,
		string.format('%4.2f', src.size / 1024 / 1024), 'MB',
		src.stride)
end

if true then
convert(rgb565, rgba8)
convert(rgba8, rgb565)
convert(rgba4444, rgba8)
convert(rgba8, rgba4444)
else
convert(rgba8, rgba8_2)
convert(g1, ga8)
convert(g2, ga8)
convert(g4, ga8)
convert(ga8, g4)
convert(g4, g2)
convert(g4, g1)
convert(g2, g4)
convert(ga8, ga8_2)
convert(rgb8, rgb8_2)
convert(icmyk8, ag8, icmyk8_ag8)
end
