--math for 2d elliptic arcs defined as (centerx, centery, radiusx, radiusy, start_angle, sweep_angle, x2, y2).
--sweep angle is capped between -360..360deg when drawing but otherwise the time on the arc is relative to the full sweep.
--x2, y2 is an optional override of arc's second end point (to use when numerical exactness of the endpoint is required).
--arc to bezier conversion adapted from agg/src/agg_bezier_arc.cpp.

local glue = require'glue'

local abs, min, max, sin, cos, pi = math.abs, math.min, math.max, math.sin, math.cos, math.pi

local arc_angle_tolerance_epsilon = 0.01

--observed sweep: we can only observe the first -360..360deg of the total sweep.
local function observed_sweep(sweep_angle)
	return max(min(sweep_angle, 2*pi), -2*pi)
end

local function endpoints(cx, cy, rx, ry, start_angle, sweep_angle, x2, y2)
	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	return
		cx + cos(start_angle) * rx,
		cy + sin(start_angle) * ry,
		x2 or cx + cos(start_angle + sweep_angle) * rx,
		y2 or cy + sin(start_angle + sweep_angle) * ry
end

local function segment(cx, cy, rx, ry, start_angle, sweep_angle)
	local x0 = cos(sweep_angle / 2)
	local y0 = sin(sweep_angle / 2)
	local tx = (1 - x0) * 4 / 3
	local ty = y0 - tx * x0 / y0
	local px0 =  x0
	local py0 = -y0
	local px1 =  x0 + tx
	local py1 = -ty
	local px2 =  x0 + tx
	local py2 =  ty
	local px3 =  x0
	local py3 =  y0
	local sn = sin(start_angle + sweep_angle / 2)
	local cs = cos(start_angle + sweep_angle / 2)
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
	x2 = x2 or cx + cos(start_angle + sweep_angle) * rx
	y2 = y2 or cy + sin(start_angle + sweep_angle) * ry
	if abs(sweep_angle) < 1e-10 then
		write('line', x2, y2)
	end
	local angle, left = start_angle, sweep_angle
	local sweep_sign = sweep_angle > 0 and 1 or -1
	while left ~= 0 do
		local sweep = sweep_sign * pi / 2
		left = left - sweep
		if sweep_sign * left < arc_angle_tolerance_epsilon then
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
	to_bezier3 = to_bezier3,
}

