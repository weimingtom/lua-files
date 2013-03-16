--2d svg-style elliptical arc to bezier conversion. adapted from agg/src/agg_bezier_arc.cpp.

local glue = require'glue'
local elliptic_arc_to_bezier3 = require'path_elliptic_arc'.to_bezier3
local matrix = require'trans_affine2d'

local sin, cos, pi, abs, sqrt, acos =
	math.sin, math.cos, math.pi, math.abs, math.sqrt, math.acos

local function svgarc_to_elliptic_arc(x0, y0, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2)
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
		rx = sqrt(radii_check) * rx
		ry = sqrt(radii_check) * ry
		prx = rx * rx
		pry = ry * ry
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

	return cx, cy, rx, ry, start_angle, sweep_angle
end

local function transform_writer(write, mt)
	return function(s,...)
		if s == 'line' then
			write('line', mt:transform_point(...))
		elseif s == 'curve' then
			write('curve',
				mt:transform_point(...),
				mt:transform_point(select(3,...)),
				mt:transform_point(select(5,...)))
		end
	end
end

local function delayed_writer(write)
	local lasts, x2, y2, x3, y3, x4, y4
	return function(s,...)

	end
end

local function svgarc_to_bezier3(write, x1, y1, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2)
	local cx, cy, rx, ry, start_angle, sweep_angle =
		svgarc_to_elliptic_arc(x1, y1, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2)

	-- Build and save the resulting arc segments
	local command, points = nil, {}
	local function collect(s,...)
		command = s
		glue.append(points,...)
	end
	elliptic_arc_to_bezier3(collect, 0, 0, rx, ry, start_angle, sweep_angle)

	-- Transform all the points
	local mt = matrix():translate(cx, cy):rotate(angle)
	for i=1,#points,2 do
		points[i], points[i+1] = mt:transform_point(points[i], points[i+1])
	end

	-- Override the end point for exact matching with the given one
	points[#points-1] = x2
	points[#points-0] = y2

	-- Write the segments out
	local n = command == 'line' and 2 or 6 --we can only have 'line' or 'curve'
	for i=1,#points,n do
		write(command, unpack(points, i, i+n-1))
	end
end

--TODO: split & hit API for svgarcs
local function svgarc_split(t, x0, y0, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2)
	local cx, cy, rx, ry, start_angle, sweep_angle =
		svgarc_to_elliptic_arc(x0, y0, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2)
end

if not ... then require'path_arc_demo' end

return {
	to_elliptic_arc = svgarc_to_elliptic_arc,
	to_bezier3 = svgarc_to_bezier3,
}

