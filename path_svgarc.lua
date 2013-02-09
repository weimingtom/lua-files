--2d svg-style elliptical arc to bezier conversion. adapted from agg/src/agg_bezier_arc.cpp.
--gotdamn never-wrote-a-line-of-code-but-look-how-good-i-am-at-math people.
local arc = require'path_arc'.arc
local matrix = require'trans_affine2d'

local sin, cos, pi, abs, sqrt, acos = math.sin, math.cos, math.pi, math.abs, math.sqrt, math.acos

local function svgarc(write, x0, y0, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2)
	if x0 == x2 and y0 == y2 then return x0, y0 end
	if rx == 0 or ry == 0 then return x0, y0 end
	rx, ry = abs(rx), abs(ry)

	-- Calculate the middle point between the current and the final points
	local dx2 = (x0 - x2) / 2
	local dy2 = (y0 - y2) / 2

	local cos_a = cos(angle)
	local sin_a = sin(angle)

	-- Calculate (x1, y1)
	local x1 =  cos_a * dx2 + sin_a * dy2
	local y1 = -sin_a * dx2 + cos_a * dy2

	-- Ensure radii are large enough
	local prx = rx * rx
	local pry = ry * ry
	local px1 = x1 * x1
	local py1 = y1 * y1

	-- Check that radii are large enough
	local radii_check = px1/prx + py1/pry
	if radii_check > 1 then
		--print(radii_check)
		rx = sqrt(radii_check) * rx
		ry = sqrt(radii_check) * ry
		prx = rx * rx
		pry = ry * ry
		if radii_check > 10 then
			print'invalid radii'
			return x0, y0 end
	end

	-- Calculate (cx1, cy1)
	local sign = large_arc_flag == sweep_flag and -1 or 1
	local sq   = (prx*pry - prx*py1 - pry*px1) / (prx*py1 + pry*px1)
	local coef = sign * sqrt(sq < 0 and 0 or sq)
	local cx1  = coef *  ((rx * y1) / ry)
	local cy1  = coef * -((ry * x1) / rx)

	-- Calculate (cx, cy) from (cx1, cy1)
	local sx2 = (x0 + x2) / 2
	local sy2 = (y0 + y2) / 2
	local cx = sx2 + (cos_a * cx1 - sin_a * cy1)
	local cy = sy2 + (sin_a * cx1 + cos_a * cy1)

	-- Calculate the start_angle (angle1) and the sweep_angle (dangle)
	local ux =  (x1 - cx1) / rx
	local uy =  (y1 - cy1) / ry
	local vx = (-x1 - cx1) / rx
	local vy = (-y1 - cy1) / ry
	local p, n

	-- Calculate the angle start
	n = sqrt(ux*ux + uy*uy)
	p = ux -- (1 * ux) + (0 * uy)
	sign = uy < 0 and -1 or 1
	local v = p / n
	if v < -1 then v = -1 end
	if v >  1 then v =  1 end
	local start_angle = sign * acos(v)

	-- Calculate the sweep angle
	n = sqrt((ux*ux + uy*uy) * (vx*vx + vy*vy))
	p = ux * vx + uy * vy
	sign = ux * vy - uy * vx < 0 and -1 or 1
	v = p / n
	if v < -1 then v = -1 end
	if v >  1 then v =  1 end
	local sweep_angle = sign * acos(v)

	if sweep_flag == 0 and sweep_angle > 0 then
		sweep_angle = sweep_angle - pi * 2
	elseif sweep_flag == 1 and sweep_angle < 0 then
		sweep_angle = sweep_angle + pi * 2
	end

	-- We can now build and transform the resulting arc
	local mt = matrix:new()
	mt:translate(cx, cy)
	mt:rotate(angle)
	local function twrite(cmd, ...)
		if cmd == 'line' or cmd == 'move' then
			write(cmd, mt:transform_point(...))
		elseif cmd == 'curve' then
			local x2,y2 = mt:transform_point(...)
			local x3,y3 = mt:transform_point(select(3,...))
			local x4,y4 = mt:transform_point(select(5,...))
			write(cmd, x2, y2, x3, y3, x4, y4)
		elseif cmd == 'close' then
			write(cmd)
		end
	end
	local cpx, cpy, bx, by = arc(twrite, 0, 0, rx, ry, start_angle, sweep_angle, nil, true)
	cpx, cpy = mt:transform_point(cpx, cpy)
	bx, by = mt:transform_point(bx, by)
	return cpx, cpy, bx, by
end

if not ... then require'path_arc_demo' end

return svgarc
