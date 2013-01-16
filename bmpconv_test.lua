local ffi = require'ffi'
local bmpconv = require'bmpconv'
local glue = require'glue'
local pp = require'pp'.pp
local unit = require'unit'

--test that all pixel format combinations are implemented

local pixel_formats = glue.index{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr'}

for src in pairs(pixel_formats) do
	for dst in pairs(pixel_formats) do
		if src ~= dst and not bmpconv.converters[src][dst] then
			print('not implemented', src, dst)
		end
		if src ~= dst and not glue.index(bmpconv.preferred_formats[src])[dst] then
			print('not preferred', src, dst)
		end
	end
end

--test pixel format conversions, including flipping and diff. output stride

local function test_pix(s1, s2, pix1, pix2, stride1, stride2)
	local data, sz = ffi.new('uint8_t[?]', #s1+1, s1), #s1
	local data, sz = bmpconv.convert(data, sz,
										{pixel = pix1, stride = stride1},
										{pixel = pix2, stride = stride2})
	local s = ffi.string(data, sz)
	test(s, s2)
end

local function shift_chars(s,x) --'aa1122' -> 'bb2233'; 'dog' -> 'eph'
	local t = {}
	for i=1,#s do t[i] = string.char(s:byte(i) == 255 and 255 or s:byte(i)+x) end
	return table.concat(t)
end

local function test_conv(s1, s2, pix1, pix2)
	local stride1, stride2 = #s1, #s2
	pp(s1, s2, stride1, stride2)
	test_pix(s1, s2, pix1, pix2, stride1, stride2)

	local s1  = s1..shift_chars(s1,1) --two s1 rows using stride1
	local p   = '\0\0\0\0' --4 bytes padding
	local s3  = shift_chars(s2,1)..p..s2..p --two s2 flipped rows using stride2+4
	local s2  = s2..p..shift_chars(s2,1)..p --two s2 rows using stride2+4
	stride1 = stride1
	stride2 = stride2 + 4
	pp(s1, s2, stride1, stride2)
	test_pix(s1, s2, pix1, pix2, stride1, stride2)  --convert 2 rows
	pp(s1, s3, stride1, stride2)
	test_pix(s1, s3, pix1, pix2, stride1, -stride2) --flip two rows
end

test_conv('ag', 'ga', 'ag', 'ga')
test_conv('ga', 'ag', 'ga', 'ag')

test_conv('rgb', 'bgr', 'rgb', 'bgr')
test_conv('bgr', 'rgb', 'bgr', 'rgb')

test_conv('rgba', 'abgr', 'rgba', 'abgr')
test_conv('bgra', 'argb', 'bgra', 'argb')
test_conv('argb', 'bgra', 'argb', 'bgra')
test_conv('abgr', 'rgba', 'abgr', 'rgba')
test_conv('argb', 'rgba', 'argb', 'rgba')
test_conv('abgr', 'bgra', 'abgr', 'bgra')
test_conv('rgba', 'argb', 'rgba', 'argb')
test_conv('bgra', 'abgr', 'bgra', 'abgr')
test_conv('rgba', 'bgra', 'rgba', 'bgra')
test_conv('bgra', 'rgba', 'bgra', 'rgba')
test_conv('argb', 'abgr', 'argb', 'abgr')
test_conv('abgr', 'argb', 'abgr', 'argb')

test_conv('g', 'g\255', 'g', 'ga')
test_conv('g', '\255g', 'g', 'ag')

test_conv('g', 'ggg', 'g', 'rgb')
test_conv('g', 'ggg', 'g', 'bgr')

test_conv('g', '\255ggg', 'g', 'argb')
test_conv('g', '\255ggg', 'g', 'abgr')
test_conv('g', 'ggg\255', 'g', 'rgba')
test_conv('g', 'ggg\255', 'g', 'bgra')

test_conv('ga', 'ggga', 'ga', 'rgba')
test_conv('ga', 'ggga', 'ga', 'bgra')
test_conv('ga', 'aggg', 'ga', 'argb')
test_conv('ga', 'aggg', 'ga', 'abgr')
test_conv('ag', 'ggga', 'ag', 'rgba')
test_conv('ag', 'ggga', 'ag', 'bgra')
test_conv('ag', 'aggg', 'ag', 'argb')
test_conv('ag', 'aggg', 'ag', 'abgr')

test_conv('rgb', '\255rgb', 'rgb', 'argb')
test_conv('bgr', '\255bgr', 'bgr', 'abgr')
test_conv('rgb', 'rgb\255', 'rgb', 'rgba')
test_conv('bgr', 'bgr\255', 'bgr', 'bgra')
test_conv('rgb', '\255bgr', 'rgb', 'abgr')
test_conv('bgr', '\255rgb', 'bgr', 'argb')
test_conv('rgb', 'bgr\255', 'rgb', 'bgra')
test_conv('bgr', 'rgb\255', 'bgr', 'rgba')

test_conv('rgb', 'h', 'rgb', 'g', 3, 1) --yes, it's 'h'
test_conv('bgr', 'h', 'bgr', 'g')

test_conv('rgba', 'rgb', 'rgba', 'rgb')
test_conv('bgra', 'bgr', 'bgra', 'bgr')
test_conv('argb', 'rgb', 'argb', 'rgb')
test_conv('abgr', 'bgr', 'abgr', 'bgr')
test_conv('rgba', 'bgr', 'rgba', 'bgr')
test_conv('bgra', 'rgb', 'bgra', 'rgb')
test_conv('argb', 'bgr', 'argb', 'bgr')
test_conv('abgr', 'rgb', 'abgr', 'rgb')

test_conv('rgba', 'ha', 'rgba', 'ga')
test_conv('rgba', 'ah', 'rgba', 'ag')
test_conv('bgra', 'ha', 'bgra', 'ga')
test_conv('bgra', 'ah', 'bgra', 'ag')
test_conv('argb', 'ha', 'argb', 'ga')
test_conv('argb', 'ah', 'argb', 'ag')
test_conv('abgr', 'ha', 'abgr', 'ga')
test_conv('abgr', 'ah', 'abgr', 'ag')

test_conv('rgba', 'h', 'rgba', 'g')
test_conv('bgra', 'h', 'bgra', 'g')
test_conv('argb', 'h', 'argb', 'g')
test_conv('abgr', 'h', 'abgr', 'g')

test_conv('rgb', 'h\255', 'rgb', 'ga')
test_conv('rgb', '\255h', 'rgb', 'ag')
test_conv('bgr', 'h\255', 'bgr', 'ga')
test_conv('bgr', '\255h', 'bgr', 'ag')

test_conv('ga', 'g', 'ga', 'g')
test_conv('ag', 'g', 'ag', 'g')

test_conv('ga', 'ggg', 'ga', 'rgb')
test_conv('ga', 'ggg', 'ga', 'bgr')
test_conv('ag', 'ggg', 'ag', 'rgb')
test_conv('ag', 'ggg', 'ag', 'bgr')
