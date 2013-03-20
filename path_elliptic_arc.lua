--math for 2d elliptic arcs defined as (centerx, centery, radiusx, radiusy, start_angle, sweep_angle, x2, y2).
--angles are expressed in degrees, not radians.
--sweep angle is capped between -360..360deg when drawing but otherwise the time on the arc is relative to the full sweep.
--x2, y2 is an optional override of arc's second end point (to use when numerical exactness of the endpoint is required).
--arc to bezier conversion adapted from agg/src/agg_bezier_arc.cpp.

local glue = require'glue'

local abs, min, max, sin, cos, radians = math.abs, math.min, math.max, math.sin, math.cos, math.rad

local angle_epsilon = 1e-10

--observed sweep: we can only observe the first -360..360deg of the total sweep.
local function observed_sweep(sweep_angle)
	return max(min(sweep_angle, 360), -360)
end

local function endpoints(cx, cy, rx, ry, start_angle, sweep_angle, x2, y2)
	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	local a = radians(start_angle)
	local x1 = cx + cos(a) * rx
	local y1 = cy + sin(a) * ry
	if not x2 then
		local a = radians(start_angle + sweep_angle)
		x2 = cx + cos(a) * rx
		y2 = cy + sin(a) * ry
	end
	return x1, y1, x2, y2
end

local function segment(cx, cy, rx, ry, start_angle, sweep_angle)
	local a = radians(sweep_angle / 2)
	local x0 = cos(a)
	local y0 = sin(a)
	local tx = (1 - x0) * 4 / 3
	local ty = y0 - tx * x0 / y0 --NaN is avoided because sweep_angle is > angle_epsilon
	local px0 =  x0
	local py0 = -y0
	local px1 =  x0 + tx
	local py1 = -ty
	local px2 =  x0 + tx
	local py2 =  ty
	local px3 =  x0
	local py3 =  y0
	local a = radians(start_angle + sweep_angle / 2)
	local sn = sin(a)
	local cs = cos(a)
	return
		cx + rx * (px1 * cs - py1 * sn), --c1x
		cy + ry * (px1 * sn + py1 * cs), --c1y
		cx + rx * (px2 * cs - py2 * sn), --c2x
		cy + ry * (px2 * sn + py2 * cs), --c2y
		cx + rx * (px3 * cs - py3 * sn), --p2x
		cy + ry * (px3 * sn + py3 * cs)  --p2y
end

--writes either one line or one or more cubic bezier curves.
--x2, y2 is the arc's 2nd endpoint which can be specified exactly.
local function to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, x2, y2)
	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	if not x2 then
		local a = radians(start_angle + sweep_angle)
		x2 = cx + cos(a) * rx
		y2 = cy + sin(a) * ry
	end
	if abs(sweep_angle) < angle_epsilon then
		write('line', x2, y2)
	end
	local angle, left = start_angle, sweep_angle
	local sweep_sign = sweep_angle > 0 and 1 or -1
	while left ~= 0 do
		local sweep = sweep_sign * 90
		left = left - sweep
		if sweep_sign * left < angle_epsilon then
			--`left` now represents the overflow or a very small underflow, a tiny curve that's left,
			--which we swallow into this one and make this the last curve.
			sweep = sweep + left
			left = 0
		end
		local cx2, cy2, cx3, cy3, cx4, cy4 = segment(cx, cy, rx, ry, angle, sweep)
		if left == 0 then --override endpoint with the specified one
			cx4, cy4 = x2, y2
		end
		write('curve', cx2, cy2, cx3, cy3, cx4, cy4)
		angle = angle + sweep
	end
end

if not ... then require'path_arc_demo' end

return {
	segment = segment,
	observed_sweep = observed_sweep,
	endpoints = endpoints,
	--path API
	to_bezier3 = to_bezier3,
}

