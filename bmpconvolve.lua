--bitmap convolution that calls a convolution kernel for each pixel of a bitmap.

local colortypes = {
	rgba8 = {channels = 4},
	rgba16 = {channels = 4},
	ga8 = {channels = 2},
	ga16 = {channels = 2},
	icmyk8 = {channels = 4},
}

local function convolve(filter, img)
	local data, pixelsize, stride, format = prepare(img)
	local function pixeladdress(x, y)
		return y * stride + x * pixelsize
	end
	for y = 0, (img.h-1) * stride, stride do
		for x = 0, (img.w-1) * pixelsize, pixelsize do
			filter(format.read, data, pixeladdress, x, y)
		end
	end
end

local function dither16to8_rgba8(read, data, pixeladdress, x, y)
	local r, g, b, a = read(data, pixeladdress(x, y))

	local oldpixel = getpixel(x, y, c)
	local newpixel = bit.band(oldpixel, 0xff00) --round by 256
	local quant_error = oldpixel - newpixel
	setpixel(x,   y,   c, newpixel)
	setpixel(x+1, y,   c, getpixel(x+1, y,   c) + 7/16 * quant_error)
	setpixel(x-1, y+1, c, getpixel(x-1, y+1, c) + 3/16 * quant_error)
	setpixel(x,   y+1, c, getpixel(x,   y+1, c) + 5/16 * quant_error)
	setpixel(x+1, y+1, c, getpixel(x+1, y+1, c) + 1/16 * quant_error)
end

--from http://en.wikipedia.org/wiki/Floyd%E2%80%93Steinberg_dithering
local function dither16to8(x, y, c, getpixel, setpixel)
	local oldpixel = getpixel(x, y, c)
	local newpixel = bit.band(oldpixel, 0xff00) --round by 256
	local quant_error = oldpixel - newpixel
	setpixel(x,   y,   c, newpixel)
	setpixel(x+1, y,   c, getpixel(x+1, y,   c) + 7/16 * quant_error)
	setpixel(x-1, y+1, c, getpixel(x-1, y+1, c) + 3/16 * quant_error)
	setpixel(x,   y+1, c, getpixel(x,   y+1, c) + 5/16 * quant_error)
	setpixel(x+1, y+1, c, getpixel(x+1, y+1, c) + 1/16 * quant_error)
end

