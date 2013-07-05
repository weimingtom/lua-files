--bitmap conversions between different pixel formats, bitmap orientations, strides and bit depths.
--changing stride, row orientation and channel order of arbitrary 8bpc and 16bpc pixel formats.
--built-in conversions between 8bpc rgb, rgba, rgbx, g, ga, a, and cmyk pixel formats in any channel order.
--creating custom converters based on pixel kernels expressed as functions or compiled expressions.
--TODO: generic scaling between 8bpc and 16bpc for any pixel format.
--TODO: 16bpp? (565,4444,5551)? bw-1? alpha-1,4? linear-rgb? premultiplied-alpha? xyz? cie?
--TODO: create a thread pool and pipe up conversions to multiple threads, splitting the work on bitmap segments.

local ffi = require'ffi'
local bit = require'bit'

--bitmap converters based on custom row-level and pixel-level conversion kernels.

local ctypes = {
	[8]  = ffi.typeof('uint8_t*'),
	[16] = ffi.typeof('uint16_t*'),
}

local function wordstride(src) --return the stride in words, not bytes, and validate it
	local stride = src.stride / (src.bpc / 8)
	assert(math.floor(stride) == stride, 'invalid stride')
	return stride
end

local function prepare(src, dst)
	assert(src.w == dst.w)
	assert(src.h == dst.h)
	assert(#src.pixel > 0)
	assert(#dst.pixel > 0)
	local sstride = wordstride(src)
	local dstride = wordstride(dst)
	local src_data = ffi.cast(assert(ctypes[src.bpc], 'invalid bpc'), src.data)
	local dst_data = ffi.cast(assert(ctypes[dst.bpc], 'invalid bpc'), dst.data)
	local dj = 0
	if src.orientation ~= dst.orientation then
		dj = (src.h - 1) * dstride --first pixel of the last row
		dstride = -dstride --...and stepping backwards
	end
	return src_data, dst_data, sstride, dj, dstride
end

--bitmap converter based on a custom row converter function to be called as
--  convert_row(dst_pointer, dst_row_offest, src_pointer, src_row_offset, row_width, row_size).
local function eachrow(convert_row, src, dst)
	local src_data, dst_data, sstride, dj, dstride = prepare(src, dst)
	local rowsize = src.w * #src.pixel * (src.bpc / 8)
	for sj = 0, (src.h - 1) * sstride, sstride do
		convert_row(dst_data, dj, src_data, sj, rowsize)
		dj = dj + dstride
	end
end

--bitmap converter based on a custom pixel converter function to be called as
--  convert_pixel(dst_pointer, dst_pixel_offset, src_pointer, src_pixel_offset).
local function eachpixel(convert_pixel, src, dst)
	local src_data, dst_data, sstride, dj, dstride = prepare(src, dst)
	local spixelsize = #src.pixel
	local dpixelsize = #dst.pixel
	local mw = src.w-1
	for sj = 0, (src.h - 1) * sstride, sstride do
		for i = 0, mw do
			convert_pixel(dst_data, dj + i * dpixelsize, src_data, sj + i * spixelsize)
		end
		dj = dj + dstride
	end
end

--fast bitmap converter for when only strides and/or orientations differ between source and dest. bitmaps.
local function copy_row(d, i, s, j, rowsize)
	ffi.copy(d+i, s+j, rowsize)
end
local function copy_rows(src, dst, ...)
	assert(src.bpc == dst.bpc)
	assert(src.pixel == dst.pixel)
	eachrow(copy_row, src, dst, ...)
end

--pixel converter kernels based on expression templates, to be used with eachpixel().

--given a pixel format, return an iterator of its channels.
local function next_channel(fmt,i)
	i = i + 1
	if i > #fmt then return end
	return i, fmt:sub(i,i)
end
local function channels(fmt)
	return next_channel, fmt, 0
end

--given a pixel format and a channel letter, return its position in the pixel, eg. channel_pos('b', 'rgb') -> 3
local function channel_pos(c, fmt)
	return (fmt:find(c))
end

--check if two pixel formats have the same channels, possibly in different order.
local function same_channels(sfmt, dfmt)
	if #sfmt ~= #dfmt then return end
	if sfmt == dfmt then return true end
	for i,c in channels(sfmt) do --sfmt must not have repeated channels
		if channel_pos(c, sfmt) ~= i then return end
	end
	for i,c in channels(sfmt) do --all channels of sfmt must be found in dfmt
		if not channel_pos(c, dfmt) then return end
	end
	return true
end

--create a pixel conversion kernel given source and dest. pixel formats, an expression template
--and its return type, eg. expr_kernel('bgra', 'argb', 'r / 2, g / 2, b / 2, 0xff', 'rgba').
local function expr_kernel(sfmt, dfmt, template, tfmt)
	assert(tfmt:gsub('[a-zA-Z]', '') == '') --template channels must be letters for the parser to work.
	assert(same_channels(dfmt, tfmt)) --dest. format must have all the channels that the expression returns.
	local left = ''
	for i,c in channels(tfmt) do
		local pos = assert(channel_pos(c, dfmt), 'channel missing in destination format')
		left = left .. 'd[i' .. (pos == 1 and '' or '+' .. pos-1) .. ']' .. (i < #tfmt and ', ' or '')
	end
	local right = template
	for i,c in channels(sfmt) do
		right = right:gsub(c..'([^a-zA-Z])', 's[j' .. (i == 1 and '' or '+' .. i-1) .. ']%1')
	end
	--print(sfmt, dfmt, left .. ' = ' .. right) --go ahead, have a look
	return assert(loadstring(
		'return function(d, i, s, j) ' ..
			left .. ' = ' .. right ..
		' end'))
end

--built-in expression templates for converting between different 8bpc pixel formats.

local t8 = {rgb = {}, rgbx = {}, rgba = {}, g = {}, ga = {}, cmyk = {}}

t8.rgb.g     = '0.2126 * r + 0.7152 * g + 0.0722 * b'
t8.rgbx.g    = t8.rgb.g
t8.rgba.g    = t8.rgb.g
t8.rgb.ga    = t8.rgb.g .. ', 0xff'
t8.rgbx.ga   = t8.rgb.g .. ', 0xff'
t8.rgba.ga   = t8.rgb.g .. ', a'
t8.rgbx.rgb  = 'r, g, b'
t8.rgba.rgb  = 'r, g, b'
t8.rgb.rgbx  = 'r, g, b, 0xff'
t8.rgba.rgbx = 'r, g, b, 0xff'
t8.rgb.rgba  = 'r, g, b, 0xff'
t8.rgbx.rgba = 'r, g, b, 0xff'
t8.cmyk.rgb  = 'c * k / 0xff, m * k / 0xff, y * k / 0xff' --inverse cmyk actually
t8.cmyk.rgbx = t8.cmyk.rgb .. ', 0xff'
t8.cmyk.rgba = t8.cmyk.rgb .. ', 0xff'
t8.cmyk.g    = '0.2126 * c * k / 0xff, 0.7152 * m * k / 0xff, 0.0722 * y * k / 0xff' --inverse cmyk actually
t8.cmyk.ga   = t8.cmyk.g .. ', 0xff'
t8.g.ga      = 'g, 0xff'
t8.g.rgb     = 'g, g, g'
t8.g.rgbx    = 'g, g, g, 0xff'
t8.g.rgba    = 'g, g, g, 0xff'
t8.ga.g      = 'g'
t8.ga.rgb    = 'g, g, g'
t8.ga.rgbx   = 'g, g, g, 0xff'
t8.ga.rgba   = 'g, g, g, a'
t8.g.cmyk    = '0, 0, 0, 0xff - g' --inverse cmyk actually
t8.ga.cmyk   = 'g, g, g, 0xff - g' --inverse cmyk actually
t8.a.g       = '0xff'
t8.a.ga      = '0xff, a'
t8.a.rgb     = '0xff, 0xff, 0xff'
t8.a.rgbx    = '0xff, 0xff, 0xff, 0xff'
t8.a.rgba    = '0xff, 0xff, 0xff, a'
t8.a.cmyk    = '0, 0, 0, 0xff'
t8.g.a       = '0xff'
t8.ga.a      = 'a'
t8.rgb.a     = '0xff'
t8.rgbx.a    = '0xff'
t8.rgba.a    = 'a'
t8.cmyk.a    = '0xff'

--16bpc templates are the same, the only difference is that 0xff is now 0xffff

local t16 = {}

for sfmt,t in pairs(t8) do
	t16[sfmt] = {}
	for dfmt, template in pairs(t) do
		t16[sfmt][dfmt] = template:gsub('0xff', '0xffff')
	end
end

local builtin = {[8] = t8, [16] = t16}

--find a built-in pixel expression template to be used with expr_kernel().
local function builtin_template(sfmt, dfmt, bpc)
	local t = assert(builtin[bpc], 'invalid bpc')
	for stype, dtypes in pairs(t) do
		if same_channels(sfmt, stype) then
			for dtype, template in pairs(dtypes) do
				if same_channels(dfmt, dtype) then
					return template, dtype
				end
			end
			break
		end
	end
end

--expression template that lists the channels in order. eg. 'rgb' -> 'r, g, b'.
local function identity_template(fmt)
	local s = ''
	for i,c in channels(fmt) do
		s = s .. c .. (i < #fmt and ', ' or '')
	end
	return s
end

--expression template that scales the channels eg. ('rgb', 256) -> 'r * 256, g * 256, b * 256'.
local function scale_template(fmt, factor)
	local s = ''
	for i,c in channels(fmt) do
		s = s .. c .. ' * ' .. tostring(factor) .. (i < #fmt and ', ' or '')
	end
	return s
end

--finally, the frontend. decide how to convert the input and call a conversion function.

--[[
	if not kernel then
		local template, tfmt
		if same_channels(sfmt, dfmt) then --channel reordering of arbitrary, unknown pixel formats
			template, tfmt = identity_template(dfmt), dfmt
		else
			local template, tfmt = builtin_template(sfmt, dfmt)
			if not template then return end --we tried everything, give up
		end
		kernel = expr_kernel(sfmt, dfmt, template, tfmt)
	elseif type(kernel) == 'string' then --kernel is an expression template
		kernel = expr_kernel(sfmt, dfmt, kernel, ...)
	end
	return function(...)
		return eachpixel(kernel, ...)
	end
]]

local function convert(src, fmt, force_copy)

	--see if there's anything to convert. if not, return the source image.
	if src.pixel == fmt.pixel
		and src.stride == fmt.stride
		and src.orientation == fmt.orientation
		and src.bpc == fmt.bpc
		and not force_copy
	then
		return src
	end

	local dst = {}
	for k,v in pairs(src) do --all image info gets copied; TODO: deepcopy
		dst[k] = v
	end
	dst.pixel = fmt.pixel
	dst.stride = fmt.stride
	dst.orientation = fmt.orientation
	dst.bpc = fmt.bpc

	--check consistency of the input
	assert(src.size == src.h * src.stride)
	assert(src.stride >= src.w * #src.pixel)
	assert(fmt.stride >= src.w * #fmt.pixel)
	assert(src.orientation == 'top_down' or src.orientation == 'bottom_up')
	assert(fmt.orientation == 'top_down' or fmt.orientation == 'bottom_up')
	assert(conversion_supported(src.pixel, fmt.pixel))

	--see if there's a dest. buffer, or we can overwrite src. or we need to alloc. one
	if opt and opt.data then
		assert(opt.size >= src.h * fmt.stride)
		dst.size = opt.size
		dst.data = opt.data
	elseif force_copy
		or src.stride ~= fmt.stride --diff. buffer size
		or src.orientation ~= fmt.orientation --needs flippin'
		or #fmt.pixel > #src.pixel --bigger pixel, even if same row size
	then
		dst.size = src.h * fmt.stride
		dst.data = ffi.new('uint8_t[?]', dst.size)
	end

	--see if we need a pixel conversion or just flipping and/or changing stride
	local operation = src.pixel == fmt.pixel and copy_rows or matrix[src.pixel][fmt.pixel]

	--print(src.pixel, fmt.pixel, src.h, src.w * src.h * #src.pixel, ffi.sizeof(dst.data))
	operation(src, dst, 0, src.h - 1)

	return dst
end

--best format choosing based on an accept table.

local preferred = {} --{[source_pixel_format] = {dest_format1, ...}}

local function addpref(stype, ...)
	for n=1,select('#',...) do
		preferred[stype] = prefered[stype] or {}
		--preffered[stype][
	end
	return dt
end
addpref('g', ga, rgb, rgbx, rgba)
addpref('ga', 'ag', 'rgba', 'bgra', 'argb', 'abgr', 'g', 'rgb', 'bgr', 'rgbx', 'bgrx', 'xrgb', 'xbgr')
addpref('ag', 'ag', 'rgba', 'bgra', 'argb', 'abgr', 'g', 'rgb', 'bgr', 'rgbx', 'bgrx', 'xrgb', 'xbgr')
addpref('rgb', rgb, rgbx, rgba, g, ga)
addpref('bgr', rgb, rgbx, rgba, g, ga)
addpref('rgbx', rgbx, rgba, rgb, g, ga)
addpref('rgbx', rgbx, rgba, rgb, g, ga)
addpref('rgbx', rgbx, rgba, rgb, g, ga)
addpref('rgbx', rgbx, rgba, rgb, g, ga)
addpref('rgba', rgba, rgbx, rgb, ga, g)
addpref('bgra', rgba, rgbx, rgb, ga, g)
addpref('argb', rgba, rgbx, rgb, ga, g)
addpref('abgr', rgba, rgbx, rgb, ga, g)

--find the best destination format for a known pixel format based on the preference table above.
local function preferred_pixel(pixel, accept)
	if not preferred[pixel] then return end
	for _,dpixel in ipairs(preferred[pixel]) do
		if accept[dpixel] then
			return dpixel
		end
	end
end

--given source pixel format and an accept table, find out if the format is accepted, possibly
--with its channels in a different order.
local function permutation_pixel(pixel, accept)
	for k in pairs(accept) do
		if same_channels(pixel, k) then
			return k
		end
	end
end

--given source pixel format and an accept table, return the best accepted dest. format.
local function best_pixel(pixel, accept)
	return
		(not accept or accept[pixel] and pixel) --source pixel format accepted, keep it, even if unknown.
		or preferred_pixel(pixel, accept)       --an accepted pixel format is in preference table.
		or permutation_pixel(pixel, accept)     --an accepted pixel format is a channel permutation of the source format.
end

--increase stride to the next number divisible by 4.
local function pad_stride(stride)
	return bit.band(stride + 3, bit.bnot(3))
end

--given source stride and bpc and an accept table, chose the best accepted dest. stride.
local function best_stride(stride, bpc, accept)
	assert(stride, 'stride missing')
	assert(bpc, 'bpc missing')
	bpc = bpc / 8
	assert(bpc == math.floor(bpc), 'invalid bpc')
	if not accept or not accept.padded then return stride end
	return pad_stride(stride)
end

--given source orientation and an accept table, choose the best accepted dest. orientation.
local function best_orientation(orientation, accept)
	assert(orientation, 'orientation missing')
	assert(orientation == 'top_down' or orientation == 'bottom_up', 'invalid orientation')
	return
		(not accept or (accept.top_down == nil and accept.bottom_up == nil)) and orientation --no preference, keep it
		or accept[orientation] and orientation --same as source, keep it
		or accept.top_down and 'top_down'
		or accept.bottom_up and 'bottom_up'
		or error('invalid orientation')
end

--given a source image and an accept specification table, return the best dest. format for use with convert().
local function best_format(src, accept)
	local fmt = {}
	fmt.pixel = best_pixel(src.pixel, accept)
	if not fmt.pixel then return end
	fmt.stride = best_stride(src.w * #fmt.pixel, src.bpc, accept) --TODO: how to specify (multiple) bpc in accept table?
	fmt.orientation = best_orientation(src.orientation, accept)
	return fmt
end

local function convert_best(src, accept, force_copy)
	local fmt = best_format(src, accept)

	if not fmt then
		local t = {}; for k,v in pairs(accept) do t[#t+1] = v ~= false and k or nil end
		error(string.format('cannot convert from (%s, %s) to (%s)',
									src.pixel, src.orientation, table.concat(t, ', ')))
	end

	return convert(src, fmt, force_copy)
end

if not ... then require'bmpconv_demo' end

return {
	eachrow = eachrow,
	eachpixel = eachpixel,
	channels = channels,
	convert = convert,
	best_format = best_format,
	convert_best = convert_best,
}

