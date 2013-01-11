--turbojpeg binding
local ffi = require'ffi'
local bit = require'bit'
local glue = require'glue'
require'turbojpeg_h'
local C = ffi.load'turbojpeg'

local function err()
	error(string.format('TurboJPEG Error: %s',
			ffi.string(C.tjGetErrorStr())), 3)
end

local function checkh(h) if h == nil then err() end; return h end
local function checkz(i) if i ~= 0 then err() end; end

local function compress(...)
	return glue.fcall(function(finally)
		local tj = checkh(C.tjInitCompress())
		assert(false, 'NYI')
		finally(function() checkz(C.tjDestroy(tj)) end)
	end)
end

local function TJPAD(width)
	return bit.band(width+3, bit.bnot(3))
end

local function TJSCALED(d, factor)
	return (d * factor.num + factor.denom - 1) / factor.denom
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
local TJPF = {
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

--[[
	opt = {
		prefer = {
			pixel_format = one of TJPF keys above ('rgb'),
			top_down = true | false (true),
			bottom_up = true | false (false),
			padded = true | false (false),
		}
		fit_w = N (image's width),
		fit_h = N (image's height),
		scaling_numerator = N (1),
		scaling_denominator = N (1),
		upsample = 'fast' | 'smooth' ('smooth'),
		dct = 'accurate' | 'fast' (impl. specific default),
		force_mmx = true (false),
		force_sse = true (false),
		force_sse2 = true (false),
		force_sse3 = true (false),
	}
]]
local function decompress(data, size, opt)
	opt = opt or {}
	local prefer = opt.prefer or {}

	--look for a preferred pixel and row format
	local pixel_format = 'rgb'
	for format in pairs(prefer) do
		if TJPF[format] then
			pixel_format = format
			break
		end
	end
	local row_format = prefer.top_down and 'top_down'
								or prefer.bottom_up and 'bottom_up' or 'top_down'
	local padded = prefer.padded == true

	return glue.fcall(function(finally)
		local tj = checkh(C.tjInitDecompress())
		finally(function() checkz(C.tjDestroy(tj)) end)

		local w = ffi.new'int32_t[1]'
		local h = ffi.new'int32_t[1]'
		local subsample = ffi.new'int32_t[1]'
		checkz(C.tjDecompressHeader2(tj, data, size, w, h, subsample))
		w, h, subsample = w[0], h[0], subsample[0]

		local pixelFormat = TJPF[pixel_format]
		local scalingFactor = getScalingFactor(opt.scaling_numerator, opt.scaling_denominator)
		assert(scalingFactor, 'invalid scaling factor numerator and/or denominator')
		local scaledWidth = TJSCALED(w, scalingFactor)
		local scaledHeight = TJSCALED(h, scalingFactor)
		local pitch = scaledWidth * tjPixelSize[pixelFormat]
		if padded then pitch = TJPAD(pitch) end

		local flags = bit.bor(
			row_format == 'bottom_up' and C.TJFLAG_BOTTOMUP or 0,
			opt.upsample == 'fast' and C.TJFLAG_FASTUPSAMPLE
				or opt.upsample == 'smooth' and 0
				or (glue.assert(not opt.upsample, 'invalid upsample option %s', opt.upsample) and 0),
			opt.dct == 'accurate' and C.TJFLAG_ACCURATEDCT
				or opt.dct == 'fast' and C.TJFLAG_FASTDCT
				or (glue.assert(not opt.dct, 'invalid dct option %s', opt.dct) and 0),
			opt.force_mmx and C.TJFLAG_FORCEMMX or 0,
			opt.force_sse and C.TJFLAG_FORCESSE or 0,
			opt.force_sse2 and C.TJFLAG_FORCESSE2 or 0,
			opt.force_sse3 and C.TJFLAG_FORCESSE3 or 0
		)

		local sz = pitch * scaledHeight
		local buf = ffi.new('uint8_t[?]', sz)
		checkz(C.tjDecompress2(tj, data, size, buf, opt.fit_w or w, pitch, opt.fit_h or h, pixelFormat, flags))

		return {
			w = w, h = h,
			data = buf,
			size = sz,
			format = {
				pixel = pixel_format,
				rows = row_format,
				rowsize = pitch,
			},
		}
	end)
end

if not ... then require'turbojpeg_test' end

return {
	compress = compress,
	decompress = decompress,
}

