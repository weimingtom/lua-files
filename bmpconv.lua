--pixel format upsampling, resampling and downsampling in luajit.
--supports all conversions between 8bit gray and rgb pixel formats with or without an alpha channel.
--supports different input/output orientations, namely top-down and bottom-up, and different strides.
local ffi = require'ffi'
local bit = require'bit'

local matrix = {
	g = {},
	ga = {}, ag = {},
	rgb = {}, bgr = {},
	rgba = {}, bgra = {}, argb = {}, abgr = {},
}

local function sign(x) return x >= 0 and 1 or -1 end

local function normalize_strides(sz, stride, dstride)
	local dj = 0
	local flip = sign(stride) ~= sign(dstride)
	stride = math.abs(stride)
	dstride = math.abs(dstride)
	if flip then
		dj = (sz/stride - 1) * dstride --first pixel of the last row
		dstride = -dstride --...and stepping backwards
	end
	return dj, stride, dstride
end

local function eachrow(convert)
	return function(src, sz, stride, dst, dstride)
		local dj, stride, dstride = normalize_strides(sz, stride, dstride)
		for sj=0,sz-1,stride do
			convert(dst, dj, src, sj, stride)
			dj = dj+dstride
		end
	end
end

local copy_rows = eachrow(function(d, i, s, j, stride) ffi.copy(d+i, s+j, stride) end)

local function eachpixel(pixelsize, dpixelsize, convert)
	return function(src, sz, stride, dst, dstride)
		local dj, stride, dstride = normalize_strides(sz, stride, dstride)
		for sj=0,sz-1,stride do
			local di = dj
			for si=0,stride-pixelsize,pixelsize do
				--print(sj,sj+si,'',sz,stride,pixelsize)
				convert(dst, di, src, sj+si)
				di = di+dpixelsize
			end
			dj = dj+dstride
		end
	end
end

matrix.ga.ag = eachpixel(2, 2, function(d, i, s, j) d[i], d[i+1] = s[j+1], s[j] end)
matrix.ag.ga = matrix.ga.ag

matrix.bgr.rgb = eachpixel(3, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j+2], s[j+1], s[j] end)
matrix.rgb.bgr = matrix.bgr.rgb

matrix.rgba.abgr = eachpixel(4, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+3], s[j+2], s[j+1], s[j+0] end)
matrix.bgra.argb = matrix.rgba.abgr
matrix.argb.bgra = matrix.rgba.abgr
matrix.abgr.rgba = matrix.rgba.abgr
matrix.argb.rgba = eachpixel(4, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+1], s[j+2], s[j+3], s[j+0] end)
matrix.abgr.bgra = matrix.argb.rgba
matrix.rgba.argb = eachpixel(4, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+3], s[j+0], s[j+1], s[j+2] end)
matrix.bgra.abgr = matrix.rgba.argb
matrix.rgba.bgra = eachpixel(4, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+2], s[j+1], s[j+0], s[j+3] end)
matrix.bgra.rgba = matrix.rgba.bgra
matrix.argb.abgr = eachpixel(4, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+0], s[j+3], s[j+2], s[j+1] end)
matrix.abgr.argb = matrix.argb.abgr

matrix.g.ag = eachpixel(1, 2, function(d, i, s, j) d[i+1], d[i+0] = s[j], 0xff end)
matrix.g.ga = eachpixel(1, 2, function(d, i, s, j) d[i+0], d[i+1] = s[j], 0xff end)

matrix.g.rgb = eachpixel(1, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j], s[j], s[j] end)
matrix.g.bgr = matrix.g.rgb

matrix.g.argb = eachpixel(1, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = 0xff, s[j], s[j], s[j] end)
matrix.g.abgr = matrix.g.argb
matrix.g.rgba = eachpixel(1, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j], s[j], s[j], 0xff end)
matrix.g.bgra = matrix.g.rgba

matrix.ga.rgba = eachpixel(2, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+0], s[j+0], s[j+0], s[j+1] end)
matrix.ga.bgra = matrix.ga.rgba
matrix.ga.argb = eachpixel(2, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+1], s[j+0], s[j+0], s[j+0] end)
matrix.ga.abgr = matrix.ga.argb
matrix.ag.rgba = eachpixel(2, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+1], s[j+1], s[j+1], s[j+0] end)
matrix.ag.bgra = matrix.ag.rgba
matrix.ag.argb = eachpixel(2, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+0], s[j+1], s[j+1], s[j+1] end)
matrix.ag.abgr = matrix.ag.argb

matrix.rgb.argb = eachpixel(3, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = 0xff, s[j], s[j+1], s[j+2] end)
matrix.bgr.abgr = matrix.rgb.argb
matrix.rgb.rgba = eachpixel(3, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j], s[j+1], s[j+2], 0xff end)
matrix.bgr.bgra = matrix.rgb.rgba
matrix.rgb.abgr = eachpixel(3, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = 0xff, s[j+2], s[j+1], s[j] end)
matrix.bgr.argb = matrix.rgb.abgr
matrix.rgb.bgra = eachpixel(3, 4, function(d, i, s, j) d[i], d[i+1], d[i+2], d[i+3] = s[j+2], s[j+1], s[j], 0xff end)
matrix.bgr.rgba = matrix.rgb.bgra

local function rgb2g(r,g,b) return 0.2126 * r + 0.7152 * g + 0.0722 * b end --photometric/digital ITU-R formula

matrix.rgb.g = eachpixel(3, 1, function(d, i, s, j) d[i] = rgb2g(s[j+0], s[j+1], s[j+2]) end)
matrix.bgr.g = eachpixel(3, 1, function(d, i, s, j) d[i] = rgb2g(s[j+2], s[j+1], s[j+0]) end)

matrix.rgba.rgb = eachpixel(4, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j+0], s[j+1], s[j+2] end)
matrix.bgra.bgr = matrix.rgba.rgb
matrix.argb.rgb = eachpixel(4, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j+1], s[j+2], s[j+3] end)
matrix.abgr.bgr = matrix.argb.rgb
matrix.rgba.bgr = eachpixel(4, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j+2], s[j+1], s[j+0] end)
matrix.bgra.rgb = matrix.rgba.bgr
matrix.argb.bgr = eachpixel(4, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j+3], s[j+2], s[j+1] end)
matrix.abgr.rgb = matrix.argb.bgr

matrix.rgba.ga = eachpixel(4, 2, function(d, i, s, j) d[i+0], d[i+1] = rgb2g(s[j+0], s[j+1], s[j+2]), s[j+3] end)
matrix.rgba.ag = eachpixel(4, 2, function(d, i, s, j) d[i+1], d[i+0] = rgb2g(s[j+0], s[j+1], s[j+2]), s[j+3] end)
matrix.bgra.ga = eachpixel(4, 2, function(d, i, s, j) d[i+0], d[i+1] = rgb2g(s[j+2], s[j+1], s[j+0]), s[j+3] end)
matrix.bgra.ag = eachpixel(4, 2, function(d, i, s, j) d[i+1], d[i+0] = rgb2g(s[j+2], s[j+1], s[j+0]), s[j+3] end)
matrix.argb.ga = eachpixel(4, 2, function(d, i, s, j) d[i+0], d[i+1] = rgb2g(s[j+1], s[j+2], s[j+3]), s[j+0] end)
matrix.argb.ag = eachpixel(4, 2, function(d, i, s, j) d[i+1], d[i+0] = rgb2g(s[j+1], s[j+2], s[j+3]), s[j+0] end)
matrix.abgr.ga = eachpixel(4, 2, function(d, i, s, j) d[i+0], d[i+1] = rgb2g(s[j+3], s[j+2], s[j+1]), s[j+0] end)
matrix.abgr.ag = eachpixel(4, 2, function(d, i, s, j) d[i+1], d[i+0] = rgb2g(s[j+3], s[j+2], s[j+1]), s[j+0] end)

matrix.rgba.g = eachpixel(4, 1, function(d, i, s, j) d[i] = rgb2g(s[j+0], s[j+1], s[j+2]) end)
matrix.bgra.g = eachpixel(4, 1, function(d, i, s, j) d[i] = rgb2g(s[j+2], s[j+1], s[j+0]) end)
matrix.argb.g = eachpixel(4, 1, function(d, i, s, j) d[i] = rgb2g(s[j+1], s[j+2], s[j+3]) end)
matrix.abgr.g = eachpixel(4, 1, function(d, i, s, j) d[i] = rgb2g(s[j+3], s[j+2], s[j+1]) end)

matrix.rgb.ga = eachpixel(3, 2, function(d, i, s, j) d[i+0], d[i+1] = rgb2g(s[j+0], s[j+1], s[j+2]), 0xff end)
matrix.rgb.ag = eachpixel(3, 2, function(d, i, s, j) d[i+1], d[i+0] = rgb2g(s[j+0], s[j+1], s[j+2]), 0xff end)
matrix.bgr.ga = eachpixel(3, 2, function(d, i, s, j) d[i+0], d[i+1] = rgb2g(s[j+2], s[j+1], s[j+0]), 0xff end)
matrix.bgr.ag = eachpixel(3, 2, function(d, i, s, j) d[i+1], d[i+0] = rgb2g(s[j+2], s[j+1], s[j+0]), 0xff end)

matrix.ga.g = eachpixel(2, 1, function(d, i, s, j) d[i] = s[j+0] end)
matrix.ag.g = eachpixel(2, 1, function(d, i, s, j) d[i] = s[j+1] end)

matrix.ga.rgb = eachpixel(2, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j+0], s[j+0], s[j+0] end)
matrix.ga.bgr = matrix.ga.rgb
matrix.ag.rgb = eachpixel(2, 3, function(d, i, s, j) d[i], d[i+1], d[i+2] = s[j+1], s[j+1], s[j+1] end)
matrix.ag.bgr = matrix.ag.rgb

--frontend

local function pad_stride(stride) --increase stride to the next number divisible by 4
	return sign(stride) * bit.band(math.abs(stride) + 3, bit.bnot(3))
end

local function convert(data, size, source_format, dest_format, force_copy)
	if source_format.pixel == dest_format.pixel and source_format.stride == dest_format.stride then
		return data, size
	end
	local new_buffer = force_copy
						or source_format.stride ~= dest_format.stride --diff. row size or needs flippin'
						or #dest_format.pixel > #source_format.pixel --bigger pixel, even if same row size
	local operation
	if source_format.pixel == dest_format.pixel then --we can copy rows of unknown pixel formats as long as they match
		operation = copy_rows
	else
		operation = matrix[source_format.pixel] and matrix[source_format.pixel][dest_format.pixel]
		assert(operation, string.format('cannot convert from %s to %s', source_format.pixel, dest_format.pixel))
	end
	local sz = size/math.abs(source_format.stride) * math.abs(dest_format.stride)
	local buf = new_buffer and ffi.new('uint8_t[?]', sz) or data
	operation(data, size, source_format.stride, buf, dest_format.stride)
	return buf, sz
end

local preferred_formats = {
	g = {'ga', 'ag', 'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr'},
	ga = {'ag', 'rgba', 'bgra', 'argb', 'abgr', 'rgb', 'bgr', 'g'},
	ag = {'ga', 'rgba', 'bgra', 'argb', 'abgr', 'rgb', 'bgr', 'g'},
	rgb = {'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'g', 'ga', 'ag'},
	bgr = {'rgb', 'rgba', 'bgra', 'argb', 'abgr', 'g', 'ga', 'ag'},
	rgba = {'bgra', 'argb', 'abgr', 'rgb', 'bgr', 'ga', 'ag', 'g'},
	bgra = {'rgba', 'argb', 'abgr', 'rgb', 'bgr', 'ga', 'ag', 'g'},
	argb = {'rgba', 'bgra', 'abgr', 'rgb', 'bgr', 'ga', 'ag', 'g'},
	abgr = {'rgba', 'bgra', 'argb', 'rgb', 'bgr', 'ga', 'ag', 'g'},
}

local function accept_orientation(stride, accept)
	return (accept.top_down == nil and accept.bottom_up == nil) --no preference
				or (accept.top_down and stride >= 0) or (accept.bottom_up and stride < 0) --right stride
end

local function accept_padding(stride, accept)
	return not accept.padded or stride % 4 == 0
end

local function accept_source_format(source_format, accept)
	return not accept
				or accept[source_format.pixel]
				and accept_orientation(source_format.stride, accept)
				and accept_padding(source_format.stride, accept)
end

local function best_format(source_format, accept)
	if not accept or accept_source_format(source_format, accept) then
		return source_format
	end

	local pref_formats = preferred_formats[source_format.pixel]
	if not pref_formats then return end

	local stride = source_format.stride
	if accept.top_down or accept.bottom_up then
		if accept.top_down then
			stride = math.abs(stride)
		elseif accept.bottom_up then
			stride = -math.abs(stride)
		end
	end
	if accept.padded then
		stride = pad_stride(stride)
	end
	for _,pixel_format in ipairs(pref_formats) do
		if accept[pixel_format] and matrix[source_format.pixel][pixel_format] then
			return {
				pixel = pixel_format,
				stride = stride,
			}
		end
	end
end

local function convert_best(data, sz, source_format, accept, force_copy)
	local dest_format = best_format(source_format, accept)

	if not dest_format then
		local t = {}; for k in pairs(accept) do t[#t+1] = k end
		error(string.format('cannot convert from (%s, stride=%d) to (%s)',
									source_format.pixel, source_format.stride, table.concat(t, ', ')))
	end

	local data, sz = convert(data, sz, source_format, dest_format, force_copy)
	return data, sz, dest_format
end

if not ... then require'bmpconv_test' end

return {
	pad_stride = pad_stride,
	convert = convert,
	best_format = best_format,
	convert_best = convert_best,
	converters = matrix,
	preferred_formats = preferred_formats,
}

