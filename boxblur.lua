--box blur algorithm by Mario Klingemann http://incubator.quasimondo.com
--src and dst are two image objects per bmpconv
local ffi = require'ffi'

local function rgb(pix, i)
	local p = pix[i]
	return
		bit.rshift(bit.band(p, 0xff0000), 16),
		bit.rshift(bit.band(p, 0x00ff00), 8),
		bit.band(p, 0x0000ff)
end

local function irgb(r, g, b)
	return bit.bor(0xff000000, bit.lshift(r, 16), bit.lshift(g, 8), b)
end

local function boxblur(src, radius)
	if radius < 1 then return end
	local w, h = src.w, src.h
	local div = 2*radius+1
	local r = ffi.new('uint8_t[?]', w*h)
	local g = ffi.new('uint8_t[?]', w*h)
	local b = ffi.new('uint8_t[?]', w*h)
	local vmin = ffi.new('int32_t[?]', math.max(w, h))
	local vmax = ffi.new('int32_t[?]', math.max(w, h))
	local pix = ffi.cast('int32_t*', src.data)
	local dv = ffi.new('uint8_t[?]', 256*div)
	for i=0,256*div-1 do dv[i] = i/div end

	local yw, yi = 0, 0

	for x=0,w-1 do
		vmin[x] = math.min(x+radius+1, w-1)
		vmax[x] = math.max(x-radius, 0)
	end

	for y=0,h-1 do
		local rsum, gsum, bsum = 0, 0, 0
		for i=-radius,radius do
			local rr, gg, bb = rgb(pix, yi+math.min(w-1, math.max(i, 0)))
			rsum = rsum + rr
			gsum = gsum + gg
			bsum = bsum + bb
		end
		for x=0,w-1 do
			r[yi] = dv[rsum]
			g[yi] = dv[gsum]
			b[yi] = dv[bsum]
			local r1,g1,b1 = rgb(pix, yw+vmin[x])
			local r2,g2,b2 = rgb(pix, yw+vmax[x])
			rsum = rsum + r1-r2
			gsum = gsum + g1-g2
			bsum = bsum + b1-b2
			yi = yi + 1
		end
		yw = yw+w
	end

	for y=0,h-1 do
		vmin[y] = math.min(y+radius+1, h-1) * w
		vmax[y] = math.max(y-radius, 0) * w
	end

	for x=0,w-1 do
		local rsum, gsum, bsum = 0, 0, 0
		local yp = -radius * w
		for i=-radius,radius do
			yi = math.max(0, yp) + x
			rsum = rsum + r[yi]
			gsum = gsum + g[yi]
			bsum = bsum + b[yi]
			yp = yp + w
		end

		yi = x
		for y=0,h-1 do
			pix[yi] = irgb(dv[rsum], dv[gsum], dv[bsum])
			local p1 = x+vmin[y]
			local p2 = x+vmax[y]
			rsum = rsum + r[p1]-r[p2]
			gsum = gsum + g[p1]-g[p2]
			bsum = bsum + b[p1]-b[p2]
			yi = yi + w
		end
	end
end

if not ... then require'test' end

return boxblur
