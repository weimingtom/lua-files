--go @ bin/luajit.exe -jv *
local ffi = require'ffi'
local bit = require'bit'
local bmpconv = require'bmpconv'

local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

local function alloc(img)
	--img.stride = pad_stride(math.ceil((formats[img.format].bpp / 8) * img.w))
	img.stride = img.w * bmpconv.formats[img.format].bpp / 8
	img.size = img.stride * img.h
	img.data = ffi.new('uint8_t[?]', img.size)
	return img
end

local cmyk8    = alloc{w = 1921, h = 1081, format = 'cmyk8', orientation = 'top_down'}
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

local rgba16   = alloc{w = 1921, h = 1081, format = 'rgba16', orientation = 'top_down'}
local ga16     = alloc{w = 1921, h = 1081, format = 'ga16', orientation = 'top_down'}

require'unit'
local function convert(src, dst, conv)
	timediff()
	for i=1,60 do
		bmpconv.convert(src, dst, conv)
	end
	print(timediff(),
		src.format .. '       ', dst.format,
		string.format('%4.2f', src.size / 1024 / 1024), 'MB',
		src.stride)
end

bmpconv.dumpinfo()

convert(rgb8, ga8)
convert(rgba16, ga16)
convert(cmyk8, ag8)

convert(rgba4444, rgba8)
convert(rgba8, rgba4444)
convert(rgba8, rgb565)
convert(rgb565, rgba8)

convert(rgb8, rgb8_2)
convert(rgba8, rgba8_2)
convert(g1, ga8)
convert(g2, ga8)
convert(g4, ga8)
convert(ga8, g4)
convert(ga8, g2)
convert(ga8, g1)
convert(g4, g2)
convert(g4, g1)
convert(g2, g4)
convert(ga8, ga8_2)
