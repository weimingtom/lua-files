--2d arc to bezier conversion. adapted from agg/src/agg_bezier_arc.cpp.
local glue = require'glue'

local sin, cos, pi, abs, fmod, max, min =
	math.sin, math.cos, math.pi, math.abs, math.fmod, math.max, math.min

local function arc_segment(cx, cy, rx, ry, start_angle, sweep_angle)
	local x0 = cos(sweep_angle * 0.5)
	local y0 = sin(sweep_angle * 0.5)
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
	local sn = sin(start_angle + sweep_angle * 0.5)
	local cs = cos(start_angle + sweep_angle * 0.5)
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

--returns a table which contains either the points of a line or the points of some 1 to 4 curves.
--in any case, (t[1],t[2]) is the arc's starting point, and (t[#t-1],t[#t]) is the arc's end point.
local function arc(cx, cy, rx, ry, start_angle, sweep_angle)
	rx, ry = abs(rx), abs(ry)
	start_angle = fmod(start_angle, pi * 2)
	sweep_angle = max(sweep_angle, -pi * 2)
	sweep_angle = min(sweep_angle,  pi * 2)
	if abs(sweep_angle) < 1e-10 then
		local x1 = cx + rx * cos(start_angle)
		local y1 = cy + ry * sin(start_angle)
		local x2 = cx + rx * cos(start_angle + sweep_angle)
		local y2 = cy + ry * sin(start_angle + sweep_angle)
		return {x1, y1, x2, y2}
	end
	local segments = {}
	local angle, left = start_angle, sweep_angle
	local sign = sweep_angle > 0 and 1 or -1
	while left ~= 0 do
		local sweep = sign * pi * 0.5
		left = left - sweep
		if sign * left < 0.01 then
			--`left` now represents the overflow or a very small underflow, a tiny curve that's left,
			--which we swallow into this one and make this the last curve.
			sweep = sweep + left
			left = 0
		end
		glue.append(segments, arc_segment(cx, cy, rx, ry, angle, sweep))
		angle = angle + sweep
	end
	return segments
end

if not ... then require'path_arc_demo' end

return arc
