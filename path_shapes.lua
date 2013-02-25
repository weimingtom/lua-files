--conversion of 2d axes-aligned closed shapes to lines and curves

local max, min, abs = math.max, math.min, math.abs

local kappa = 4 * ((math.sqrt(2) - 1) / 3) --http://www.whizkidtech.redprince.net/bezier/circle/

local function ellipse(write, cx, cy, rx, ry)
	rx, ry = abs(rx), abs(ry)
	local lx = rx * kappa
	local ly = ry * kappa
	write('move',  cx, cy-ry)
	write('curve', cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
	write('curve', cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
	write('curve', cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
	write('curve', cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
	write('close')
end

local function circle(write, cx, cy, r)
	ellipse(write, cx, cy, r, r)
end

local function rectangle(write, x1, y1, w, h)
	local x2, y2 = x1 + w, y1 + h
	write('move', x1, y1)
	write('line', x2, y1)
	write('line', x2, y2)
	write('line', x1, y2)
	write('close')
end

local function round_rectangle(write, x1, y1, w, h, rx)
	rx = min(abs(rx), abs(w/2), abs(h/2))
	local ry = rx
	local x2, y2 = x1 + w, y1 + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	local lx = rx * kappa
	local ly = ry * kappa
	local cx, cy = x2-rx, y1+ry
	write('move',  cx, y1)
	write('curve', cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
	write('line',  x2, y2-ry)
	cx, cy = x2-rx, y2-ry
	write('curve', cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
	write('line',  x1+rx, y2)
	cx, cy = x1+rx, y2-ry
	write('curve', cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
	write('line',  x1, y1+ry)
	cx, cy = x1+rx, y1+ry
	write('curve', cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
	write('close')
end

--a star has a center, two anchor points and a number of leafs
local function star(write, cx, cy, x1, y1, x2, y2, n)
	error'NYI'
end

--a regular polygon has a center, a radius and a number of segments
local function regular_polygon(write, cx, cy, n, r)
	error'NYI'
end

return {
	ellipse = ellipse,
	circle = circle,
	rectangle = rectangle,
	round_rectangle = round_rectangle,
	star = star,
	regular_polygon = regular_polygon,
}
