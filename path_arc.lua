--conversion of 2d arcs to lines and beziers. adapted from agg/src/agg_bezier_arc.cpp.
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

local function normalize_args(rx, ry, start_angle, sweep_angle)
	rx, ry = abs(rx), abs(ry)
	start_angle = fmod(start_angle, pi * 2)
	sweep_angle = max(sweep_angle, -pi * 2)
	sweep_angle = min(sweep_angle,  pi * 2)
	return rx, ry, start_angle, sweep_angle
end

local function arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
	rx, ry, start_angle, sweep_angle = normalize_args(rx, ry, start_angle, sweep_angle)
	return
		cx + rx * cos(start_angle),
		cy + ry * sin(start_angle),
		cx + rx * cos(start_angle + sweep_angle),
		cy + ry * sin(start_angle + sweep_angle)
end

local bezier_arc_angle_epsilon = 0.01 --limit to prevent adding degenerate curves

local function arc(write, cx, cy, rx, ry, start_angle, sweep_angle, has_cp, dont_connect)
	if rx == 0 or ry == 0 then return cx, cy end

	if abs(sweep_angle) < 1e-10 then
		local x1, y1, x2, y2 = arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
		if not dont_connect then write(has_cp and 'line' or 'move', x1, y1) end
		write('line', x2, y2)
		return x2, y2
	end
	rx, ry, start_angle, sweep_angle = normalize_args(rx, ry, start_angle, sweep_angle)

	local cpx, cpy, bx, by
	local total_sweep = 0
	local local_sweep = 0
	local prev_sweep, done
	local step = (sweep_angle < 0 and -1 or 1) * pi * 0.5
	for i=1,4 do
		prev_sweep  = total_sweep
		local_sweep = step
		total_sweep = total_sweep + step
		if sweep_angle < 0 then
			if total_sweep <= sweep_angle + bezier_arc_angle_epsilon then
				local_sweep = sweep_angle - prev_sweep
				done = true
			end
		else
			if total_sweep >= sweep_angle - bezier_arc_angle_epsilon then
				local_sweep = sweep_angle - prev_sweep
				done = true
			end
		end

		local x1, y1, x2, y2, x3, y3, x4, y4 = arc_segment(cx, cy, rx, ry, start_angle, local_sweep)
		if i == 1 and not dont_connect then
			write(has_cp and 'line' or 'move', x1, y1)
		end
		write('curve', x2, y2, x3, y3, x4, y4)
		bx, by = x3, y3
		cpx, cpy = x4, y4

		start_angle = start_angle + local_sweep
		if done then break end
	end
	return cpx, cpy, bx, by
end

if not ... then require'path_arc_demo' end

return {
	segment = arc_segment,
	endpoints = arc_endpoints,
	arc = arc,
}
