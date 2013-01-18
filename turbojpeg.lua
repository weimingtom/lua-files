--turbojpeg binding
local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
local stdio = require'stdio'
local bmpconv = require'bmpconv'
require'turbojpeg_h'
local C = ffi.load'turbojpeg'

local function err()
	error(string.format('turbojpeg error: %s', ffi.string(C.tjGetErrorStr())), 3)
end

local function checkh(h) if h == nil then err() end; return h end
local function checkz(i) if i ~= 0 then err() end; end

--[[TODO:
local function compress(...)
	return glue.fcall(function(finally)
		local tj = checkh(C.tjInitCompress())
		assert(false, 'NYI')
		finally(function() checkz(C.tjDestroy(tj)) end)
	end)
end
]]

local function TJSCALED(d, factor)
	return math.floor((d * factor.num + factor.denom - 1) / factor.denom)
end

local function tjGetScalingFactors()
	local n = ffi.new'int32_t[1]'
	local factors = checkh(C.tjGetScalingFactors(n))
	assert(n[0] > 0)
	return factors, n[0]
end

local function getScalingFactor(num, denom)
	if not num then num, denom = 1,1 end
	local scalingFactors, scalingFactorsNum = tjGetScalingFactors()
	for i=0,scalingFactorsNum-1 do
		local scalingFactor = scalingFactors[i]
		if scalingFactor.num == num and scalingFactor.denom == denom then
			return scalingFactor
		end
	end
end

local tjPixelSize = {[0] = 3, 3, 4, 4, 4, 4, 1, 4, 4, 4, 4}

local TJPF = { --note that ga and ag are not supported
	rgb  = C.TJPF_RGB,
	bgr  = C.TJPF_BGR,
	rgbx = C.TJPF_RGBX,
	bgrx = C.TJPF_BGRX,
	xbgr = C.TJPF_XBGR,
	xrgb = C.TJPF_XRGB,
	g    = C.TJPF_GRAY,
	rgba = C.TJPF_RGBA,
	bgra = C.TJPF_BGRA,
	abgr = C.TJPF_ABGR,
	argb = C.TJPF_ARGB,
}

local TJSAMP = {
  [C.TJSAMP_444]  = '4:4:4',
  [C.TJSAMP_422]  = '4:2:2',
  [C.TJSAMP_420]  = '4:2:0',
  [C.TJSAMP_GRAY] = 'gray',
  [C.TJSAMP_440]  = '4:4:0',
}

local pixel_format_pref_list = {'rgba', 'bgra', 'abgr', 'argb', 'rgb', 'bgr',
											'rgbx', 'bgrx', 'xbgr', 'xrgb', 'g'} --renounce alpha first, then color

local function best_pixel_format(accept)
	if accept then
		for _,format in ipairs(pixel_format_pref_list) do
			if accept[format] then return format end
		end
	end
	return pixel_format_pref_list[1]
end

--[[
	opt = {
		accept = {
			[pixel_format] = true (rgba = true),
			[row_format] = true (top_down = true),
			padded = true | false (false),
		}
		fit_w = N (image's width),
		fit_h = N (image's height),
		scale_num = N (1),
		scale_denom = N (1),
		upsampling = 'fast' | 'smooth' ('smooth'),
		dct = 'accurate' | 'fast' (impl. specific default),
		force_mmx = true (false),
		force_sse = true (false),
		force_sse2 = true (false),
		force_sse3 = true (false),
	}
]]
local function decompress(data, size, opt)
	opt = opt or {}

	--look for the best accepted combination of pixel and row format
	local pixel_format = best_pixel_format(opt.accept)
	local bottom_up = opt.accept and opt.accept.bottom_up and not opt.accept.top_down
	local padded = opt.accept and opt.accept.padded or false

	return glue.fcall(function(finally)
		local tj = checkh(C.tjInitDecompress())
		finally(function() checkz(C.tjDestroy(tj)) end)

		local w = ffi.new'int32_t[1]'
		local h = ffi.new'int32_t[1]'
		local subsampling = ffi.new'int32_t[1]'
		checkz(C.tjDecompressHeader2(tj, data, size, w, h, subsampling))
		w, h, subsampling = w[0], h[0], TJSAMP[subsampling[0]]

		local pixelFormat = TJPF[pixel_format]
		local scalingFactor = getScalingFactor(opt.scale_num, opt.scale_denom)
		assert(scalingFactor, 'invalid scaling numerator and/or denominator')
		local scaledWidth = TJSCALED(w, scalingFactor)
		local scaledHeight = TJSCALED(h, scalingFactor)
		local stride = scaledWidth * tjPixelSize[pixelFormat]
		if padded then stride = bmpconv.pad_stride(stride) end

		local flags = bit.bor(
			bottom_up and C.TJFLAG_BOTTOMUP or 0,
			opt.upsampling == 'fast' and C.TJFLAG_FASTUPSAMPLE
				or opt.upsampling == 'smooth' and 0
				or (glue.assert(not opt.upsampling, 'invalid upsampling option %s', opt.upsampling) and 0),
			opt.dct == 'accurate' and C.TJFLAG_ACCURATEDCT
				or opt.dct == 'fast' and C.TJFLAG_FASTDCT
				or (glue.assert(not opt.dct, 'invalid dct option %s', opt.dct) and 0),
			opt.force_mmx and C.TJFLAG_FORCEMMX or 0,
			opt.force_sse and C.TJFLAG_FORCESSE or 0,
			opt.force_sse2 and C.TJFLAG_FORCESSE2 or 0,
			opt.force_sse3 and C.TJFLAG_FORCESSE3 or 0
		)

		local sz = stride * scaledHeight
		local buf = ffi.new('uint8_t[?]', sz)
		checkz(C.tjDecompress2(tj, data, size, buf, opt.fit_w or w, stride,
										opt.fit_h or h, pixelFormat, flags))

		local img = {
			data = buf,
			size = sz,
			pixel = pixel_format,
			stride = stride,
			orientation = bottom_up and 'bottom_up' or 'top_down',
			w = w,
			h = h,
			subsampling = subsampling,
		}
		return bmpconv.convert_best(img, opt.accept)
	end)
end

local function load(t, opt)
	if t.string then
		return decompress(t.string, #t.string, opt)
	elseif t.cdata then
		return decompress(t.cdata, t.size, opt)
	elseif t.path then
		local buf, sz = stdio.readfile(t.path)
		return decompress(buf, sz, opt)
	elseif t.stream then
		--TODO: read stream
		error'NYI'
	elseif t.cdata_source then
		--TODO: read entire cdata source
		error'NYI'
	elseif t.string_source then
		--TODO: read entire string_source
		error'NYI'
	else
		error'invalid data source (path, string, cdata/size, stream, cdata_source, string_source accepted)'
	end
end

if not ... then require'turbojpeg_test' end

return {
	load = load,
	C = C,
}

