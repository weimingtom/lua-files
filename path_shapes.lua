--conversion of 2d axes-aligned closed shapes to lines and curves.

local elliptic_arc_segment = require'path_elliptic_arc'.segment
local elliptic_arc_endpoints = require'path_elliptic_arc'.endpoints
local circle_3p_to_circle = require'path_circle_3p'.to_circle

local max, min, abs, sin, cos, pi = math.max, math.min, math.abs, math.sin, math.cos, math.pi

local kappa = 4 / 3 * (math.sqrt(2) - 1)

local function ellipse_to_bezier3(write, cx, cy, rx, ry)
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

local function circle_to_bezier3(write, cx, cy, r)
	ellipse_to_bezier3(write, cx, cy, r, r)
end

local function circle_3p_to_bezier3(write, x1, y1, x2, y2, x3, y3)
	local cx, cy, r = circle_3p_to_circle(x1, y1, x2, y2, x3, y3)
	if not cx then return end
	circle_to_bezier3(write, cx, cy, r)
end

local function rectangle_to_lines(write, x1, y1, w, h)
	local x2, y2 = x1 + w, y1 + h
	write('move', x1, y1)
	write('line', x2, y1)
	write('line', x2, y2)
	write('line', x1, y2)
	write('close')
end

local function rectangle_to_straight_lines(write, x1, y1, w, h)
	local x2, y2 = x1 + w, y1 + h
	write('move',  x1, y1)
	write('hline', x2)
	write('vline', y2)
	write('hline', x1)
	write('close')
end

local function round_rectangle_to_bezier3(write, x1, y1, w, h, rx, ry)
	rx = min(abs(rx), abs(w/2), abs(h/2))
	ry = rx
	--rx = min(abs(rx), abs(w/2))
	--ry = min(abs(ry), abs(h/2))
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

--TODO: we don't have the elliptic_arc command yet, and so we don't know the params yet
local function round_rectangle_to_elliptic_arcs(write, x1, y1, w, h, rx, ry)
	rx = min(abs(rx), abs(w/2))
	ry = min(abs(ry), abs(h/2))
	local x2, y2 = x1 + w, y1 + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	local cx, cy = x2-rx, y1+ry
	write('move',  cx, y1)
	write('elliptic_arc', cx, cy, rx, ry, 0, pi/2) --q1
	cx, cy = x2-rx, y2-ry
	write('elliptic_arc', cx, cy, rx, ry, pi/2, pi) --q4
	cx, cy = x1+rx, y2-ry
	write('elliptic_arc', cx, cy, rx, ry, pi, 3*pi/2) --q3
	cx, cy = x1+rx, y1+ry
	write('elliptic_arc', cx, cy, rx, ry, 3*pi/2, 0) --q2
	write('close')
end

local function round_rectangle_to_arcs(write, x1, y1, w, h, r)
	r = min(abs(r), abs(w/2), abs(h/2))
	local x2, y2 = x1 + w, y1 + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	local cx, cy = x2-r, y1+r
	write('move',  cx, y1)
	write('arc', cx, cy, r, 0, pi/2) --q1
	cx, cy = x2-rx, y2-ry
	write('arc', cx, cy, r, pi/2, pi) --q4
	cx, cy = x1+rx, y2-ry
	write('arc', cx, cy, r, pi, 3*pi/2) --q3
	cx, cy = x1+rx, y1+ry
	write('arc', cx, cy, r, 3*pi/2, 0) --q2
	write('close')
end

local point_angle = require'path_point'.point_angle
local distance = require'path_point'.distance

--a regular polygon has a center, an anchor point and a number of segments
local function regular_polygon_to_lines(write, cx, cy, x1, y1, n)
	if n < 2 then return end
	local sweep_angle = 2*pi/n
	local start_angle = point_angle(x1, y1, cx, cy)
	local radius = distance(x1, y1, cx, cy)
	for i=start_angle, start_angle + 2*pi - sweep_angle/2, sweep_angle do
		local x = cx + cos(i) * radius
		local y = cy + sin(i) * radius
		write(i==start_angle and 'move' or 'line', x, y)
	end
	write('close')
end

--a star has a center, an anchor point, a secondary radius and a number of leafs
local function star_to_star_2p(cx, cy, x1, y1, r2, n)
	local a = point_angle(x1, y1, cx, cy) + 2*pi/n/2
	local x2, y2 =
		cx + cos(a) * r2,
		cy + sin(a) * r2
	return cx, cy, x1, y1, x2, y2, n
end

--a 2-anchor-point star has a center, two anchor points and a number of leafs
local function star_2p_to_lines(write, cx, cy, x1, y1, x2, y2, n)
	if n < 2 then return end
	local sweep_angle = 2*pi/n
	local start_angle = point_angle(x1, y1, cx, cy)
	local radius = distance(x1, y1, cx, cy)
	local sweep2  = point_angle(x2, y2, cx, cy) - start_angle
	local radius2 = distance(x2, y2, cx, cy)
	for i=start_angle, start_angle + 2*pi - sweep_angle/2, sweep_angle do
		local x = cx + cos(i) * radius
		local y = cy + sin(i) * radius
		write(i==start_angle and 'move' or 'line', x, y)
		local x = cx + cos(i + sweep2) * radius2
		local y = cy + sin(i + sweep2) * radius2
		write('line', x, y)
	end
	write('close')
end

local function star_to_lines(write, cx, cy, x1, y1, r2, n)
	star_2p_to_lines(write, star_to_star_2p(cx, cy, x1, y1, r2, n))
end

--TODO: swirl looks bad, it's badly parametrized, and should probably write out smooth curves instead!
local function swirl_to_bezier3(write, cx, cy, r, d, n)
	for i = 0, 2*pi*n - pi/4, pi/2 do
		if i == 0 then
			local x1, y1 = elliptic_arc_endpoints(cx, cy, r, r, i, pi/2)
			write('move', x1, y1)
		end
		write('curve', elliptic_arc_segment(cx, cy, r, r, i, pi/2))
		r = r - d
	end
end

--linearly interpolate a shape defined by a custom formula, and unite the points with lines.
local function formula_to_lines(write, formula, steps, ...)
	local step = 1/steps
	local x, y = formula(0, ...)
	write('move', x, y)
	local i = step
	while i < 1 do
		local x, y = formula(i, ...)
		write('line', x, y)
		i = i + step
	end
	local x, y = formula(1, ...)
	write('line', x, y)
	write('close')
end

--http://en.wikipedia.org/wiki/Superformula
local function superformula(t, cx, cy, size, a, b, m, n1, n2, n3)
	local f = t*2*pi
	local r = (abs(cos(m*f/4)/a)^n2 + abs(sin(m*f/4)/b)^n3)^(-1/n1)
	return
		cx + r * cos(f) * size,
		cy + r * sin(f) * size
end

local function superformula_to_lines(write, cx, cy, size, steps, a, b, m, n1, n2, n3)
	formula_to_lines(write, superformula, steps, cx, cy, size, a, b, m, n1, n2, n3)
end

if not ... then require'path_shapes_demo' end

return {
	ellipse = ellipse_to_bezier3,
	circle = circle_to_bezier3,
	circle_3p = circle_3p_to_bezier3,
	rectangle = rectangle_to_lines,
	round_rectangle = round_rectangle_to_bezier3,
	star_to_star_2p = star_to_star_2p,
	star_2p = star_2p_to_lines,
	star = star_to_lines,
	regular_polygon = regular_polygon_to_lines,
	swirl = swirl_to_bezier3,
	formula = formula_to_lines,
	superformula = superformula_to_lines,
}

