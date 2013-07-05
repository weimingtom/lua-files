--go@ bin/luajit.exe *
--NEW: struct-based bitmap converters

local ffi = require'ffi'
local bit = require'bit'

--given a pixel format, return an iterator of its channels.
local function next_channel(fmt,i)
	i = i + 1
	if i > #fmt then return end
	return i, fmt:sub(i,i)
end
local function channels(fmt)
	return next_channel, fmt, 0
end

local function pixelstruct(img)
	local elem_type = ffi.typeof(string.format('uint%d_t', img.bpc))
	local s = 'struct { $ '
	for i,c in channels(img.pixel) do
		s = s .. c .. (i == #img.pixel and '; } *' or ', ')
	end
	--print(s)
	local ptype = ffi.typeof(s, elem_type)
	local pdata = ffi.cast(ptype, img.data)
	return pdata, ptype
end

--bitmap converter based on a custom pixel converter function to be called as
--  convert_pixel(dst_pointer, dst_pixel_offset, src_pointer, src_pixel_offset).
local uint8_t = ffi.typeof'uint8_t*'
local cast = ffi.cast
local function eachpixel(convert_pixel, src, dst)
	local src_data, src_type = pixelstruct(src)
	local dst_data, dst_type = pixelstruct(dst)
	local w = src.w
	local sstride, dstride = src.stride, dst.stride
	for j = 0, src.h do
		for i = 0, w - 1 do
			convert_pixel(dst_data, src_data, i)
		end
		src_data = cast(src_type, cast(uint8_t, src_data) + sstride)
		dst_data = cast(dst_type, cast(uint8_t, dst_data) + dstride)
		--src_data = src_data + w
		--dst_data = dst_data + w
	end
end

local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

local function alloc(img)
	img.stride = img.w * #img.pixel * (img.bpc / 8)
	--if img.padded then img.stride = pad_stride(img.stride) end
	img.size = img.stride * img.h
	img.data = ffi.new('uint8_t[?]', img.size)
	return img
end

local src = alloc{w = 1000, h = 1000, bpc = 8, pixel = 'rgb', padded = true}
local dst = alloc{w = 1000, h = 1000, bpc = 16, pixel = 'abgr'}

for i=1,1 do
	eachpixel(function(d, s, i)
		d.r = s.b
		d.g = s.g
		d.b = s.r
	end, src, dst)
end

