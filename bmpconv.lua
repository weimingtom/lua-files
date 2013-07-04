--bitmap conversions between different pixel formats, bitmap orientations, strides and bit depths.
--changing stride, row orientation and channel order of arbitrary 8bpc and 16bpc pixel formats.
--built-in conversions between 8bpc and 16bpc rgb, rgba, rgbx, g, ga, and cmyk pixel formats in any channel order.
--creating expression-based and pixel-level and row-level function-based custom converters.
--TODO: generic scaling between 8bpc and 16bpc for any pixel format.
--TODO: 16bpp? (565,4444,5551)? bw-1? alpha-1,4,8? linear-rgb? premultiplied-alpha? xyz? cie?
--TODO: create a thread pool and pipe up conversions to multiple threads, splitting the work on bitmap segments.

local ffi = require'ffi'
local bit = require'bit'

--bitmap converters based on custom row-level and pixel-level conversion kernels.

--check if the dest. image has enough space and compatible attributes to do a conversion.
local function validate(src, dst, h1, h2)
	--TODO
end

local function dstride(src, dst)
	local dj, dstride = 0, dst.stride
	if src.orientation ~= dst.orientation then
		dj = (src.h - 1) * dstride --first pixel of the last row
		dstride = -dstride --...and stepping backwards
	end
	return dj, dstride
end

local ctypes = {
	[8]  = ffi.typeof('uint8_t*'),
	[16] = ffi.typeof('uint16_t*'),
}

--bitmap converter based on a custom row converter function to be called as
--  convert_row(dst_pointer, dst_row_offest, src_pointer, src_row_offset).
local function eachrow(convert_row, src, dst, h1, h2)
	validate(src, dst, h1, h2)
	local dj, dstride = dstride(src, dst)
	local rowsize = src.w * #src.pixel * (src.bpc / 8)
	local src_data = ffi.cast(ctypes[src.bpc], src.data)
	local dst_data = ffi.cast(ctypes[dst.bpc], dst.data)
	for sj = h1 * src.stride, h2 * src.stride, src.stride do
		convert_row(dst_data, dj, src_data, sj, rowsize)
		dj = dj + dstride
	end
end

--fast bitmap converter for when only strides and/or orientations differ between source and dest. bitmaps.
local function copy_row(d, i, s, j, rowsize)
	ffi.copy(d+i, s+j, rowsize)
end
local function copy_rows(...)
	eachrow(copy_row, ...)
end

--bitmap converter based on a custom pixel converter function to be called as
--  convert_pixel(dst_pointer, dst_pixel_offset, src_pointer, src_pixel_offset).
local function eachpixel(convert_pixel, src, dst, h1, h2)
	validate(src, dst, h1, h2)
	local dj, dstride = dstride(src, dst)
	local spixelsize = #src.pixel
	local dpixelsize = #dst.pixel
	local src_data = ffi.cast(ctypes[src.bpc], src.data)
	local dst_data = ffi.cast(ctypes[dst.bpc], dst.data)
	for sj = h1 * src.stride, h2 * src.stride, src.stride do
		for i = 0, src.w - 1 do
			convert_pixel(dst_data, dj + i * dpixelsize, src_data, sj + i * spixelsize)
		end
		dj = dj + dstride
	end
end

--pixel converter kernels based on expression templates. to be used with eachpixel().

--given a pixel format, return an iterator of its channels.
local function channels(fmt)
	return function(fmt,i)
		i = i + 1
		if i > #fmt then return end
		return i, fmt:sub(i,i)
	end, fmt, 0
end

--given a pixel format and a channel letter, return its position in the pixel, eg. channel_pos('b', 'rgb') -> 3
local function channel_pos(c, fmt)
	return (fmt:find(c))
end

--create a pixel conversion kernel given source and dest. pixel formats, an expression template
--and its return type, eg. expr_kernel('bgra', 'argb', 'r / 2, g / 2, b / 2, 0xff', 'rgba').
--NOTE: sfmt and dfmt must have all the channels that tfmt has in whatever order.
local function expr_kernel(sfmt, dfmt, template, tfmt)
	local left = ''
	for i,c in channels(tfmt) do
		local pos = assert(channel_pos(c, dfmt), 'channel missing in destination format')
		left = left .. 'd[i' .. (pos == 1 and '' or '+' .. pos-1) .. ']' .. (i < #tfmt and ', ' or '')
	end
	local right = template
	for i,c in channels(sfmt) do
		right = (' '..right..' '):gsub('([^a-z])('..c..')([^a-z])', '%1s[j' .. (i == 1 and '' or '+' .. i-1) .. ']%3')
	end
	right = right:gsub('^%s+', ''):gsub('%s+$', '') --trim
	print(sfmt, dfmt, left .. ' = ' .. right) --go ahead, have a look
	return assert(loadstring(
		'return function(d, i, s, j) ' ..
			left .. ' = ' .. right ..
		' end'))
end

--built-in expression templates for converting between different color types.

local template = {rgb = {}, rgbx = {}, rgba = {}, g = {}, ga = {}, cmyk = {}}

template.rgb.g     = '0.2126 * r + 0.7152 * g + 0.0722 * b'
template.rgbx.g    = template.rgb.g
template.rgba.g    = template.rgb.g
template.rgb.ga    = template.rgb.g .. ', 0xff'
template.rgbx.ga   = template.rgb.g .. ', 0xff'
template.rgba.ga   = template.rgb.g .. ', a'
template.rgbx.rgb  = 'r, g, b'
template.rgba.rgb  = 'r, g, b'
template.rgb.rgbx  = 'r, g, b, 0xff'
template.rgba.rgbx = 'r, g, b, 0xff'
template.rgb.rgba  = 'r, g, b, 0xff'
template.rgbx.rgba = 'r, g, b, 0xff'
template.cmyk.rgb  = 'c * k / 0xff, m * k / 0xff, y * k / 0xff' --inverse cmyk actually
template.cmyk.rgbx = template.cmyk.rgb .. ', 0xff'
template.cmyk.rgba = template.cmyk.rgb .. ', 0xff'
template.cmyk.g    = '0.2126 * c * k / 0xff, 0.7152 * m * k / 0xff, 0.0722 * y * k / 0xff' --inverse cmyk actually
template.cmyk.ga   = template.cmyk.g .. ', 0xff'
template.g.ga      = 'g, 0xff'
template.g.rgb     = 'g, g, g'
template.g.rgbx    = 'g, g, g, 0xff'
template.g.rgba    = 'g, g, g, 0xff'
template.ga.g      = 'g'
template.ga.rgb    = 'g, g, g'
template.ga.rgbx   = 'g, g, g, 0xff'
template.ga.rgba   = 'g, g, g, a'
template.g.cmyk    = '0, 0, 0, 0xff - g' --inverse cmyk actually
template.ga.cmyk   = 'g, g, g, 0xff - g' --inverse cmyk actually

--pixel formats and their color type (pixel formats are variants of a color type with different channel order)

local colortype = {} --{[pixel_format] = color_type}
local function addcolors(ctype, ...)
	for i=1,select('#',...) do
		colortype[select(i,...)] = ctype
	end
end
addcolors('rgb',  'rgb', 'bgr')
addcolors('rgba', 'rgba', 'bgra', 'argb', 'abgr')
addcolors('rgbx', 'rgbx', 'bgrx', 'xrgb', 'xbgr')
addcolors('g',    'g')
addcolors('ga',   'ga', 'ag')
addcolors('cmyk', 'cmyk')

--given a pixel format, return an expression template that lists the channels in order. eg. 'rgb' -> 'r, g, b'.
local function identity_template(fmt)
	local s = ''
	for i,c in channels(fmt) do
		s = s .. c .. (i < #fmt and ', ' or '')
	end
	return s
end

--return a built-in pixel expression template and its return pixel format to be used with expr_kernel().
local function builtin_template(sfmt, dfmt)
	local stype = colortype[sfmt]
	local dtype = colortype[dfmt]
	if not stype or not dtype then return end
	if stype == dtype then --same color type, so it's just channel reordering
		return identity_template(dtype), dtype
	elseif template[stype] then
		return template[stype][dtype], dtype
	end
end

--create a bitmap converter given source and dest. pixel formats and either:
--  a pixel kernel function, eg. pixel_converter('bgra', 'abgr', function(d, i, s, j) ... end).
--  an expression template/return type, eg. pixel_converter('bgra', 'argb', 'r / 2, g / 2, b / 2, 0xff', 'rgba').
--  nothing, in which case the converter will do:
--    row copying, if source and dest. pixel formats are the same, eg. pixel_converter('rgb', 'rgb').
--    built-in default conversion, if any is found, eg. pixel_converter('ga', 'rgb').
--    channel reordering conversion, eg. pixel_converter('abc', 'bac')
local function pixel_converter(sfmt, dfmt, kernel, ...)
	if not kernel then
		if sfmt == dfmt then
			return copy_rows
		else
			local template, tfmt = builtin_template(sfmt, dfmt)
			if not template then --couldn't find a built-in template, *assume* channel reordering
				template, tfmt = identity_template(dfmt), dfmt
			end
			kernel = expr_kernel(sfmt, dfmt, template, tfmt)
		end
	elseif type(kernel) == 'string' then --kernel is an expression template
		kernel = expr_kernel(sfmt, dfmt, kernel, ...)
	end
	return function(...)
		return eachpixel(kernel, ...)
	end
end

--the matrix of default pixel conversion functions.

local matrix = {} --{[src_format][dst_format] = function(d, i, s, j) d[i+N] = s[j+M] end}

for sfmt, stype in pairs(colortype) do
	matrix[sfmt] = {}
	for dfmt, dtype in pairs(colortype) do
		matrix[sfmt][dfmt] = pixel_converter(sfmt, dfmt)
	end
end

--finally, the frontend. decide how to convert the input and call a conversion function.

local function conversion_supported(src, dst)
	return src == dst or (matrix[src] and matrix[src][dst] and true or false)
end

local function convert(src, fmt, opt)

	--see if there's anything to convert. if not, return the source image.
	if src.pixel == fmt.pixel
		and src.stride == fmt.stride
		and src.orientation == fmt.orientation
		and src.bpc == fmt.bpc
		and not (opt and opt.force_copy)
	then
		return src
	end

	local dst = {}
	for k,v in pairs(src) do dst[k] = v end --all image info gets copied; TODO: deepcopy
	dst.pixel = fmt.pixel
	dst.stride = fmt.stride
	dst.orientation = fmt.orientation
	dst.bpc = fmt.bpc

	--check consistency of the input
	--NOTE: we support unknown pixel formats as long as #pixel == pixel size in bytes
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
	elseif (opt and opt.force_copy)
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

	--end
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
		if accept[dpixel] and matrix[pixel][dpixel] then --accepted and we have an implementation for it
			return dpixel
		end
	end
end

local function permutation_pixel(pixel, accept)
	--TODO
	return
end

--given source pixel format and an accept table, return the best accepted dest. format.
local function best_pixel(pixel, accept)
	return
		(not accept or accept[pixel] and pixel) --source pixel format accepted, keep it, even if unknown!
		or preferred_pixel(pixel, accept) --an accepted pixel format is in conversion preference table.
		or permutation_pixel(pixel, accept) --an accepted pixel format is a channel permutation of the source format.
end

--increase stride to the next number divisible by 4. stride is in bytes here!
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
	return pad_stride(stride * bpc) / bpc
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

local function convert_best(src, accept, opt)
	local fmt = best_format(src, accept)

	if not fmt then
		local t = {}; for k,v in pairs(accept) do t[#t+1] = v ~= false and k or nil end
		error(string.format('cannot convert from (%s, %s) to (%s)',
									src.pixel, src.orientation, table.concat(t, ', ')))
	end

	return convert(src, fmt, opt)
end

if not ... then require'bmpconv_demo' end

return {
	eachrow = eachrow,
	eachpixel = eachpixel,
	channels = channels,
	pixel_converter = pixel_converter,
	convert = convert,
	best_format = best_format,
	convert_best = convert_best,
}

