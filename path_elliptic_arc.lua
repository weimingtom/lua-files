--math for 2d elliptic arcs defined as (centerx, centery, radiusx, radiusy, start_angle, sweep_angle).
--sweep angle is capped between -360..360deg when drawing but otherwise the time on the arc is relative to the full sweep.
--arc to bezier conversion adapted from agg/src/agg_bezier_arc.cpp.

local glue = require'glue'

local abs, min, max, sin, cos, pi = math.abs, math.min, math.max, math.sin, math.cos, math.pi

local arc_angle_tolerance_epsilon = 0.01

--observed sweep: we can only observe the first -360..360deg of the total sweep.
local function observed_sweep(sweep_angle)
	return max(min(sweep_angle, 2*pi), -2*pi)
end

local function endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	return
		cx + cos(start_angle) * rx,
		cy + sin(start_angle) * ry,
		cx + cos(start_angle + sweep_angle) * rx,
		cy + sin(start_angle + sweep_angle) * ry
end

local function arc_segment(cx, cy, rx, ry, start_angle, sweep_angle)
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
		cx + rx * (px0 * cs - py0 * sn), --p1x
		cy + ry * (px0 * sn + py0 * cs), --p1y
		cx + rx * (px1 * cs - py1 * sn), --c1x
		cy + ry * (px1 * sn + py1 * cs), --c1y
		cx + rx * (px2 * cs - py2 * sn), --c2x
		cy + ry * (px2 * sn + py2 * cs), --c2y
		cx + rx * (px3 * cs - py3 * sn), --p2x
		cy + ry * (px3 * sn + py3 * cs)  --p2y
end

--returns a table which contains either the points of a line or the points of one or many cubic bezier curves.
--in any case, (t[1],t[2]) is the arc's starting point, and (t[#t-1],t[#t]) is the arc's end point.
local function to_bezier3(cx, cy, rx, ry, start_angle, sweep_angle)
	if abs(sweep_angle) < 1e-10 then
		local x1, y1, x2, y2 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
		return 'line', {x1, y1, x2, y2}
	end
	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	local segments = {}
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
		glue.append(segments, arc_segment(cx, cy, rx, ry, angle, sweep))
		angle = angle + sweep
	end
	--update arc endpoints to exactly match the ones approximated by arc_endpoints()
	local x1, y1, x2, y2 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
	segments[1] = x1
	segments[2] = y1
	segments[#segments-1] = x2
	segments[#segments] = y2
	return 'curve', segments
end

if not ... then require'path_arc_demo' end

return {
	observed_sweep = observed_sweep,
	endpoints = endpoints,
	to_bezier3 = to_bezier3,
}

