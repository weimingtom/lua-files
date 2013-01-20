local ffi = require'ffi'
local bmpconv = require'bmpconv'
local glue = require'glue'
local pp = require'pp'.pp
local unit = require'unit'

--test that all pixel format combinations are implemented

local pixel_formats = glue.index{'g', 'ga', 'ag', 'rgb', 'bgr', 'rgba', 'bgra', 'argb', 'abgr', 'cmyk'}

local function test_nyi()
	for src in pairs(pixel_formats) do
		for dst in pairs(pixel_formats) do
			if not bmpconv.supported(src, dst) then
				print('not implemented', src, dst)
			end
		end
	end
end

--test pixel format conversions, including flipping and diff. output stride

local function test_pix(s1, s2, pix1, pix2, stride1, stride2, w, h, flip)
	local data, sz = ffi.new('uint8_t[?]', #s1+1, s1), #s1
	local dst = bmpconv.convert(
		{pixel = pix1, stride = stride1, orientation = 'top_down', w = w, h = h, data = data, size = sz},
		{pixel = pix2, stride = stride2, orientation = flip and 'bottom_up' or 'top_down'})
	local s = ffi.string(dst.data, dst.size)
	--we test row by row so we can ignore the garbage bytes between rowsize and the end of the stride
	local rowsize = w*#pix2
	for i=0,h*stride2-1,stride2 do
		test(s:sub(i,i+rowsize), s2:sub(i,i+rowsize))
	end
end

local function shift_chars(s,x) --'aa1122' -> 'bb2233'; 'dog' -> 'eph'
	local t = {}
	for i=1,#s do t[i] = string.char(s:byte(i) == 255 and 255 or s:byte(i)+x) end
	return table.concat(t)
end

local function test_conv(s1, s2, pix1, pix2)
	local stride1, stride2 = #s1, #s2
	local width = #s1/#pix1
	assert(width == 1)
	pp(s1, s2, stride1, stride2)
	test_pix(s1, s2, pix1, pix2, stride1, stride2, width, 1)

	local p1 = '\0\0\0' --3 bytes padding
	local p2 = '\0\0\0\0' --4 bytes padding
	local s1 = s1..p1..shift_chars(s1,1)..p1 --two s1 rows using stride1+2
	local s3 = shift_chars(s2,1)..p2..s2..p2 --two s2 flipped rows using stride2+4
	local s2 = s2..p2..shift_chars(s2,1)..p2 --two s2 rows using stride2+4
	stride1 = stride1 + #p1
	stride2 = stride2 + #p2
	pp(s1, s2, pix1, stride1, pix2, stride2)
	test_pix(s1, s2, pix1, pix2, stride1, stride2, width, 2) --convert 2 rows
	pp(s1, s3, stride1, stride2)
	test_pix(s1, s3, pix1, pix2, stride1, stride2, width, 2, true) --flip two rows
end

local function test_conversions()
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
end

--performance test

local function benchmark()
	local w, h = 1000, 1000
	local src = ffi.new('uint8_t[?]', w * h * 4)
	local dst = ffi.new('uint8_t[?]', w * h * 4)

	timediff()
	print('#', 'src', 'dst', 'flip', 'time')
	local t = {}
	for spix in pairs(pixel_formats) do
		for dpix in pairs(pixel_formats) do
			for orientation in pairs{top_down = true, bottom_up = true} do
				t[#t+1] = {spix, dpix, orientation}
			end
		end
	end

	local from = 1

	for i=1,#t do
		local spix, dpix, orientation = unpack(t[i])
		if i >= from and bmpconv.supported(spix, dpix) then
			for i=1,100 do --convert a 4Mbytes 1000x1000 rgba picture 100 times (jit on: 1-2s; jit off: 87s; CPU: E5200)
				bmpconv.convert(
					{pixel = spix, w = w, h = h, stride = w * 4, data = src, size = w * h * 4, orientation = orientation},
					{pixel = dpix, w = w, h = h, stride = w * 4, data = dst, size = w * h * 4, orientation = 'bottom_up'},
					{force_copy = true, threads = 2}
				)
			end
			print(i, spix, dpix, orientation == 'top_down', timediff())
		end
	end
end

--test_nyi()
--test_conversions()
benchmark()

