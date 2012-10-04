--pixel format upsampling, resampling and downsampling in luajit.
--it supports all pixel layout conversions so you don't have to think which ones you need.
local ffi = require'ffi'
local bit = require'bit'

local bswap, brol, bror = bit.bswap, bit.rol, bit.ror
if ffi.abi'le' then brol,bror = bror,brol end --beware of how we interpret rolls!

local matrix = {
	g = {},
	ga = {},
	ag = {},
	rgb = {},
	bgr = {},
	rgba = {},
	bgra = {},
	argb = {},
	abgr = {},
}

-- 2 -> 2

local function invert2(data, sz) -- ga -> ag and back
	for i=0,sz-2,2 do
		data[i],data[i+1] = data[i+1],data[i]
	end
	return data, sz
end

matrix.ga.ag = invert2
matrix.ag.ga = invert2

-- 3 -> 3

local function invert3(data, sz) -- rgb -> bgr and back
	for i=0,sz-3,3 do
		data[i],data[i+2] = data[i+2],data[i]
	end
	return data, sz
end

matrix.rgb.bgr = invert3
matrix.bgr.rgb = invert3

-- 4 -> 4

local function invert4(data, sz) -- argb -> bgra and back
	local p, isz = ffi.cast('uint32_t*', data), sz/4
	assert(math.floor(isz) == isz)
	for i=0,isz-1 do
		p[i] = bswap(p[i])
	end
	return data, sz
end

matrix.rgba.abgr = invert4
matrix.bgra.argb = invert4
matrix.argb.bgra = invert4
matrix.abgr.rgba = invert4

local function a3to3a(data, sz) -- argb -> rgba on big-endian
	local p, isz = ffi.cast('uint32_t*', data), sz/4
	assert(math.floor(isz) == isz)
	for i=0,isz-1 do
		p[i] = brol(p[i], 8)
	end
	return data, sz
end

matrix.argb.rgba = a3to3a
matrix.abgr.bgra = a3to3a

local function _3atoa3(data, sz) -- rgba -> argb on big-endian
	local p, isz = ffi.cast('uint32_t*', data), sz/4
	assert(math.floor(isz) == isz)
	for i=0,isz-1 do
		p[i] = bror(p[i], 8)
	end
	return data, sz
end

matrix.rgba.argb = _3atoa3
matrix.bgra.abgr = _3atoa3

local function _3atoi3a(data, sz) -- rgba -> bgra on big-endian
	local p, isz = ffi.cast('uint32_t*', data), sz/4
	assert(math.floor(isz) == isz)
	for i=0,isz-1 do
		p[i] = bswap(bror(p[i], 8))
	end
	return data, sz
end

matrix.rgba.bgra = _3atoi3a
matrix.bgra.rgba = _3atoi3a

local function a3toai3(data, sz) -- argb -> abgr on big-endian
	local p, isz = ffi.cast('uint32_t*', data), sz/4
	assert(math.floor(sz) == sz)
	for i=0,isz-1 do
		p[i] = bswap(brol(p[i], 8))
	end
	return data, sz
end

matrix.argb.abgr = a3toai3
matrix.abgr.argb = a3toai3

-- 1 -> 2

local function _1toa1(data, sz) -- gray to ag
	local buf = ffi.new('uint8_t[?]', sz*2)
	for i=0,sz-1 do
		buf[i*2] = 0xff
		buf[i*2+1] = data[i]
	end
	return buf,sz*2
end

matrix.g.ag = _1toa1

local function _1to1a(data, sz) -- gray to ga
	local buf = ffi.new('uint8_t[?]', sz*2)
	for i=0,sz-1 do
		buf[i*2] = data[i]
		buf[i*2+1] = 0xff
	end
	return buf,sz*2
end

matrix.g.ga = _1to1a

-- 1 -> 3

local function _1to3(data, sz) -- gray to ggg
	local buf = ffi.new('uint8_t[?]', sz*3)
	for i=0,sz-1 do
		buf[i*3]   = data[i]
		buf[i*3+1] = data[i]
		buf[i*3+2] = data[i]
	end
	return buf, sz*3
end

matrix.g.rgb = _1to3
matrix.g.bgr = _1to3

-- 1 -> 4

local function _1toa3(data, sz) --gray to aggg on big-endian
	local buf = ffi.new('uint8_t[?]', sz*4)
	local p = ffi.cast('uint32_t*', buf)
	for i=0,sz-1 do
		p[i] = data[i] * 0x010101 + 0xff000000
	end
	return buf, sz*4
end

local function _1to3a(data, sz) --gray to ggga on big-endian
	local buf = ffi.new('uint8_t[?]', sz*4)
	local p = ffi.cast('uint32_t*', buf)
	for i=0,sz-1 do
		p[i] = data[i] * 0x01010100 + 0xff
	end
	return buf, sz*4
end

if ffi.abi'le' then _1to3a, _1toa3 = _1toa3, _1to3a end

matrix.g.rgba = _1to3a
matrix.g.bgra = _1to3a
matrix.g.argb = _1toa3
matrix.g.abgr = _1toa3

-- 2 -> 4

local function _1ato3a(data, sz) --ga to ggga
	sz = sz/2
	assert(math.floor(sz) == sz)
	local buf = ffi.new('uint8_t[?]', sz*4)
	for i=0,sz-1 do
		buf[i*4]   = data[sz*2]
		buf[i*4+1] = data[sz*2]
		buf[i*4+2] = data[sz*2]
		buf[i*4+3] = data[sz*2+1]
	end
	return buf, sz*4
end

matrix.ga.rgba = _1ato3a
matrix.ga.bgra = _1ato3a

local function _1atoa3(data, sz) --ga to aggg
	return invert4(_1ato3a(data, sz))
end

matrix.ga.argb = _1atoa3
matrix.ga.abgr = _1atoa3

-- 3 -> 4

local function _3toa3(data, sz)
	sz = sz/3
	assert(math.floor(sz) == sz)
	local buf = ffi.new('uint8_t[?]', sz*4)
	for i=0,sz-1 do
		buf[i*4]   = 0xff
		buf[i*4+1] = data[i*3]
		buf[i*4+2] = data[i*3+1]
		buf[i*4+3] = data[i*3+2]
	end
	return buf, sz*4
end

matrix.rgb.argb = _3toa3
matrix.bgr.abgr = _3toa3

local function _3to3a(data, sz)
	sz = sz/3
	assert(math.floor(sz) == sz)
	local buf = ffi.new('uint8_t[?]', sz*4)
	for i=0,sz-1 do
		buf[i*4]   = data[i*3]
		buf[i*4+1] = data[i*3+1]
		buf[i*4+2] = data[i*3+2]
		buf[i*4+3] = 0xff
	end
	return buf, sz*4
end

matrix.rgb.rgba = _3to3a
matrix.bgr.bgra = _3to3a

local function _3toai3(data, sz)
	return invert4(_3to3a(data, sz))
end

matrix.rgb.abgr = _3toai3
matrix.bgr.argb = _3toai3

local function _3toi3a(data, sz)
	return invert4(_3toa3(data, sz))
end

matrix.rgb.bgra = _3toi3a
matrix.bgr.rgba = _3toi3a

-- 3 -> 1

function matrix.rgb.g(data, sz) --Photometric/digital ITU-R
	sz = sz/3
	assert(math.floor(sz) == sz)
	local buf = ffi.new('uint8_t[?]', sz)
	for i=0,sz-1 do
		buf[i] = 0.2126 * data[i*3] + 0.7152 * data[i*3+1] + 0.0722 * data[i*3+2]
	end
end

function matrix.bgr.g(data, sz) --Photometric/digital ITU-R
	sz = sz/3
	assert(math.floor(sz) == sz)
	local buf = ffi.new('uint8_t[?]', sz)
	for i=0,sz-1 do
		buf[i] = 0.2126 * data[i*3+2] + 0.7152 * data[i*3+1] + 0.0722 * data[i*3]
	end
end

--TODO:
-- 4 -> 3 (remove alpha)
-- 4 -> 2 (remove color, preseve alpha)
-- 4 -> 1 (remove color and alpha)
-- 3 -> 2 (remove color, set 0xff alpha)
-- 2 -> 1 (remove alpha)
-- 2 -> 3 (remove alpha)

--frontend

local function copy(data, sz)
	local buf = ffi.new('uint8_t[?]', sz)
	ffi.copy(buf, data, sz)
	return buf, sz
end

local function copy_flipped(data, sz, rowsize)
	assert(rowsize, 'bmpconv: rowsize missing')
	local buf = ffi.new('uint8_t[?]', sz)
	local h = sz/rowsize
	assert(math.floor(h) == h)
	local pbuf, pdata = ffi.cast('uint8_t*', buf), ffi.cast('uint8_t*', data)
	for i=0,h-1 do
		ffi.copy(pbuf+(i*rowsize), pdata+((h-i-1)*rowsize), rowsize)
	end
	return buf, sz
end

local inplace_converters = {
	invert2 = true, invert3 = true, invert4 = true,
	a3to3a = true, _3atoa3 = true, _3atoi3a = true, a3toai3 = true,
}

local row_formats = {top_down = true, bottom_up = true}

local function convert(data, sz, source_format, dest_format, force_copy)
	assert(matrix[source_format.pixel], 'bmpconv: unsupported source.pixel format')
	assert(row_formats[source_format.rows], 'bmpconv: invalid source.rows format')
	assert(row_formats[dest_format.rows], 'bmpconv: invalid dest.rows format')
	if source_format.pixel == dest_format.pixel then
		if source_format.rows ~= dest_format.rows then
			data, sz = copy_flipped(data, sz, source_format.rowsize)
		elseif force_copy then
			data, sz = copy(data, sz)
		end
		return data, sz
	else
		local converter = assert(matrix[source_format.pixel][dest_format.pixel],
											'bmpconv: unsupported pixel format conversion')
		if source_format.rows ~= dest_format.rows then
			data, sz = copy_flipped(data, sz, source_format.rowsize)
		elseif force_copy and inplace_converters[converter] then
			data, sz = copy(data, sz)
		end
		return converter(data, sz)
	end
end

local conv_pref = {
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

local function best_format(source_format, accept)
	if not accept then return source_format end
	if accept[source_format.pixel] and accept[source_format.rows] then
		return source_format
	end
	local pixel_pref = assert(conv_pref[source_format.pixel], 'bmpconv: unsupported source.pixel format')
	for _,dest_pixel_format in ipairs(pixel_pref) do
		if accept[dest_pixel_format] and matrix[source_format.pixel][dest_pixel_format] then
			return {
				pixel = dest_pixel_format,
				rows = assert((accept[source_format.rows] and source_format.rows)
									or (accept.top_down and 'top_down')
									or (accept.bottom_up and 'bottom_up'),
									'bmpconv: accept.top_down or accept.bottom_up expected'),
			}
		end
	end
end

local function convert_best(data, sz, source_format, accept, force_copy)
	local dest_format = best_format(source_format, accept)
	local data, sz = convert(data, sz, source_format, dest_format, force_copy)
	return data, sz, dest_format
end

return {
	convert = convert,
	best_format = best_format,
	convert_best = convert_best,
}

