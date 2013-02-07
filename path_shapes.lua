--conversion of 2d axes-aligned closed shapes to lines and curves

local M = {}

local kappa = 4 * ((math.sqrt(2) - 1) / 3) --http://www.whizkidtech.redprince.net/bezier/circle/

function M.ellipse(write, cx, cy, rx, ry)
	local lx = rx * kappa
	local ly = ry * kappa
	write('move',  cx, cy-ry)
	write('curve', cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
	write('curve', cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
	write('curve', cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
	write('curve', cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
	write('close')
end

function M.circle(write, cx, cy, r)
	M.ellipse(write, cx, cy, r, r)
end

function M.rect(write, x1, y1, w, h)
	local x2, y2 = x1 + w, y1 + h
	write('move', x1, y1)
	write('line', x2, y1)
	write('line', x2, y2)
	write('line', x1, y2)
	write('close')
end

function M.round_rect(write, x1, y1, w, h, rx)
	local ry = rx
	local x2, y2 = x1 + w, y1 + h
	local lx = rx * kappa
	local ly = ry * kappa
	local cx, cy = x2-rx, y1+ry
	write('move',  cx, y1)
	write('curve', cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
	write('line',  x2, y2-ry)
	cx, cy = x2-rx, y2-ry
	write('curve', cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
	write('line', x1+rx, y2)
	cx, cy = x1+rx, y2-ry
	write('curve', cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
	write('line', x1, y1+ry)
	cx, cy = x1+rx, y1+ry
	write('curve', cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
	write('close')
end

--a star has a center, two anchor points and a number of leafs
function M.star(write, cx, cy, x1, y1, x2, y2, n)
	error'NYI'
end

--a regular polygon has a center, a radius and a number of segments
function M.regular_poly(write, cx, cy, n, r)
	error'NYI'
end

return M
