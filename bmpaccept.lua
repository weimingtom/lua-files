--bitmap format conversion: dest. format choosing based on an accept table.
local glue = require'glue' --extend

local pref = {}

local rgb8   = {'rgb8', 'bgr8'}
local rgb16  = {'rgb16', 'bgr16'}
local rgbx8  = {'rgbx8', 'xrgb8', 'bgrx8', 'xbgr8'}
local rgbx16 = {'rgbx16', 'xrgb16', 'bgrx16', 'xbgr16'}
local rgba8  = {'rgba8', 'argb8', 'bgra8', 'abgr8'}
local rgba16 = {'rgba16', 'argb16', 'bgra16', 'abgr16'}
local g8     = {'g8'}
local ga8    = {'ga8', 'ag8'}
local g16    = {'g16'}
local ga16   = {'ga16', 'ag16'}
local icmyk8 = {'icmyk8'}
local rgb16b = {'rgb565', 'rgb555', 'rgb444'}
local rgba16b= {'rgba4444', 'rgba5551'}
local g4     = {'g4'}
local g2     = {'g2'}
local g1     = {'g1'}

local rgba_gray = glue.extend({}, ga16, g16, ga8, g8, g4, g2, g1)
local rgb_gray  = glue.extend({}, g16, ga16, g8, ga8, g4, g2, g1)

pref.rgb8  = glue.extend({}, rgb8, rgbx8, rgba8, rgb16, rgba16, rgbx16, rgb16b, rgba16b, rgb_gray)
pref.bgr8  = pref.rgb8

pref.rgb16 = glue.extend({}, rgb16, rgbx16, rgba16, rgb8, rgba8, rgbx8, rgb16b, rgba16b, rgb_gray)
pref.bgr16 = pref.rgb16

pref.rgbx8 = glue.extend({}, rgbx8, rgba8, rgb8, rgb16, rgba16, rgbx16, rgb16b, rgba16b, rgb_gray)
pref.bgrx8 = pref.rgbx8
pref.xrgb8 = pref.rgbx8
pref.xbgr8 = pref.rgbx8

pref.rgbx16 = glue.extend({}, rgbx16, rgba16, rgb16, rgb8, rgbx8, rgba8, rgb16b, rgba16b, rgb_gray)
pref.bgrx16 = pref.rgbx16
pref.xrgb16 = pref.rgbx16
pref.xbgr16 = pref.rgbx16

pref.rgba8 = glue.extend({}, rgba8, rgba16, rgbx8, rgb8, rgb16, rgbx16, rgba16b, rgb16b, rgb_gray)
pref.bgra8 = pref.rgba8
pref.argb8 = pref.rgba8
pref.abgr8 = pref.rgba8

pref.rgba16 = glue.extend({}, rgba16, rgb16, rgbx16, rgba8, rgbx8, rgb8, rgba16b, rgb16b, rgb_gray)
pref.bgra16 = pref.rgba16
pref.argb16 = pref.rgba16
pref.abgr16 = pref.rgba16

pref.g8    = glue.extend({}, g8, g16, ga8, ga16, rgba8, rgba16, rgb8, rgbx8, rgb16, rgbx16, rgb16b, rgba16b, g4, g2, g1)
pref.ga8   = glue.extend({}, ga8, ga16, rgba8, rgba16, g8, g16, rgb8, rgbx8, rgb16, rgbx16, rgb16b, rgba16b, g4, g2, g1)
pref.ag8   = pref.ga8

pref.icmyk8   = glue.extend({}, rgbx16, rgba16, rgb8, rgbx8, rgba8, rgb16, rgb16b, rgba16b, g16, ga16, g8, ga8, g4, g2, g1)

local pref_rgb16b  = glue.extend({}, rgba8, rgba16, rgb8, rgbx8, rgb16, rgbx16, rgb16b, rgba16b, rgba_gray)
local pref_rgba16b = glue.extend({}, rgba8, rgba16, rgb8, rgbx8, rgb16, rgbx16, rgba16b, rgb16b, rgba_gray)

pref.rgb565   = pref_rgb16b
pref.rgba4444 = pref_rgba16b
pref.rgba5551 = pref_rgba16b
pref.rgb555   = pref_rgb16b
pref.rgb444   = pref_rgb16b
pref.g1 =
pref.g2 =
pref.g4 =

--given source pixel format and an accept table, return the best accepted dest. format.
local function best_format(format, accept)
	if not accept or accept[format] then --source format accepted or no preference
		return pixel
	end
	for _,dformat in ipairs(preferred[format]) do
		if accept[dformat] then
			return dformat
		end
	end
	error'invalid format'
end

--given source stride and bpc and an accept table, chose the best accepted dest. stride.
local function best_stride(stride, bpc, accept)
	stride = valid_stride(stride)
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
	fmt.stride = best_stride(fmt, accept) --TODO: how to specify (multiple) bpc in accept table?
	fmt.orientation = best_orientation(src.orientation, accept)
	return fmt
end


local function must_copy(src, format, orientation, stride, stride_aligned)
	orientation = orientation or 'top_down'
	local src_format = valid_format(src.format)
	local src_stride = image_stride(src)
	local dst_format = valid_format(format)
	local dst_stride = valid_stride(format, src.w, stride, stride_aligned)
	return
		or dst_stride ~= src_stride --dest. doesn't fit in source buffer or would waste memory
		or dst_format.bpp > src_format.bpp --dest. pixels would be written ahead of source pixels
		or orientation ~= src.orientation --dest. pixels would be written ahead of source pixels
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

