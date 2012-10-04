--conversion of axes-aligned 2d shapes to lines and curves

local kappa = 4 * ((math.sqrt(2) - 1) / 3) --http://www.whizkidtech.redprince.net/bezier/circle/

local function ellipse_to_curves(write, cx, cy, rx, ry)
	local lx = rx * kappa
	local ly = ry * kappa
	write('move', nil, nil, cx, cy-ry)
	write('curve', cx, cy-ry, cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
	write('curve', cx+rx, cy, cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
	write('curve', cx, cy+ry, cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
	write('curve', cx-rx, cy, cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-rx) --q2
	write('close', cx, cy-ry, cx, cy-ry)
end

local function circle_to_curves(write, cx, cy, r)
	ellipse_to_curves(write, cx, cy, r, r)
end

local function rect_to_lines(write, x1, y1, w, h)
	local x2, y2 = x1 + w, y1 + h
	write('move', nil, nil, x1, y1)
	write('line', x1, y1, x2, y1)
	write('line', x2, y1, x2, y2)
	write('line', x2, y2, x1, y2)
	write('close', x1, y2, x1, y1)
end

local function round_rect_to_arcs(write, x, y, w, h, r)
	local x2, y2 = x1 + w, y1 + h
	write('break')
	write('arc', x1+r, y1+r, r, -math.pi, -math.pi/2)
	write('arc', x2-r, y1+r, r, -math.pi/2, 0)
	write('arc', x2-r, y2-r, r, 0, math.pi/2)
	write('arc', x1+r, y2-r, r, math.pi/2, math.pi)
	write('close')
end

local function round_rect_to_lines_and_curves(write, x, y, w, h, r)
	--TODO
end

--a star has a center, two anchor points and a number of leafs
local function star_to_lines(write, cx, cy, x1, y1, x2, y2, n)
	--TODO
end

--a regular polygon has a center, a radius and a number of segments
local function regular_poly_to_lines(write, cx, cy, n, r)
	--TODO
end

return {
	ellipse_to_curves = ellipse_to_curves,
	circle_to_curves = circle_to_curves,
	rect_to_lines = rect_to_lines,
	round_rect_to_arcs = round_rect_to_arcs,
	round_rect_to_lines_and_curves = round_rect_to_lines_and_curves,
	star_to_lines = star_to_lines,
	regular_poly_to_lines = regular_poly_to_lines,
}

