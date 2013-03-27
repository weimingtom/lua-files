--math for 2d svg-style elliptical arcs defined as:
--  (x1, y1, radius_x, radius_y, rotation, large_arc_flag, sweep_flag, x2, y2, [matrix], [segment_max_sweep])
--conversion to elliptic arcs adapted from antigrain library @ agg/src/agg_bezier_arc.cpp by Cosmin Apreutesei.

local glue = require'glue'
local elliptic_arc_to_bezier3 = require'path_elliptic_arc'.to_bezier3
local elliptic_arc_hit = require'path_elliptic_arc'.hit
local matrix = require'trans_affine2d'

local sin, cos, abs, sqrt, acos, radians, degrees, pi =
	math.sin, math.cos, math.abs, math.sqrt, math.acos, math.rad, math.deg, math.pi

local function to_elliptic_arc(x0, y0, rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2, ...)
	rx, ry = abs(rx), abs(ry)

	-- Calculate the middle point between the current and the final points
	local dx2 = (x0 - x2) / 2
	local dy2 = (y0 - y2) / 2

	local a = radians(rotation)
	local cos_a = cos(a)
	local sin_a = sin(a)

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
		sweep_angle = sweep_angle - 2*pi
	elseif sweep_flag == 1 and sweep_angle < 0 then
		sweep_angle = sweep_angle + 2*pi
	end

	return cx, cy, rx, ry, degrees(start_angle), degrees(sweep_angle), rotation, ...
end

local function to_bezier3(write, ...)
	elliptic_arc_to_bezier3(write, to_elliptic_arc(...))
end

local function hit(x0, y0, ...)
	elliptic_arc_hit(x0, y0, to_elliptic_arc(...))
end

local function split(t, ...)
	local
		cx, cy, rx, ry, start_angle, sweep1, rotation
		cx, cy, rx, ry, split_angle, sweep2, rotation, x2, y2 =
		elliptic_arc_split(t, to_elliptic_arc(...))
	--TODO: elliptic arc to svgarc conversion
	error'NYI'
end

if not ... then require'path_arc_demo' end

return {
	to_elliptic_arc = to_elliptic_arc,
	--path API
	to_bezier3 = to_bezier3,
	hit = hit,
	split = split,
}

