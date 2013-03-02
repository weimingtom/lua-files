--math for 2d circular arcs defined as (centerx, centery, radius, start_angle, sweep_angle).
--sweep angle can exceed -360..360deg which will cause the arc to draw over itself.

local glue = require'glue'
local point_angle = require'path_point'.point_angle
local point_around = require'path_point'.point_around
local point_distance2 = require'path_point'.point_distance2

local sin, cos, pi, abs, max, min, fmod =
	math.sin, math.cos, math.pi, math.abs, math.max, math.min, math.fmod

local arc_angle_overflow_epsilon = 0.01

local function elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
	rx, ry = abs(rx), abs(ry)
	return
		cx + rx * cos(start_angle),
		cy + ry * sin(start_angle),
		cx + rx * cos(start_angle + sweep_angle),
		cy + ry * sin(start_angle + sweep_angle)
end

--arc to bezier conversion adapted from agg/src/agg_bezier_arc.cpp.
local function elliptic_arc_segment_to_bezier3(cx, cy, rx, ry, start_angle, sweep_angle)
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

--returns a table which contains either the points of a line or the points of some 1 to 4 curves.
--in any case, (t[1],t[2]) is the arc's starting point, and (t[#t-1],t[#t]) is the arc's end point.
local function elliptic_arc_to_bezier3(cx, cy, rx, ry, start_angle, sweep_angle)
	if abs(sweep_angle) < 1e-10 then
		return {elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle)}
	end
	rx, ry = abs(rx), abs(ry)
	local segments = {}
	local angle, left = start_angle, sweep_angle
	local sweep_sign = sweep_angle > 0 and 1 or -1
	while left ~= 0 do
		local sweep = sweep_sign * pi / 2
		left = left - sweep
		if sweep_sign * left < arc_angle_overflow_epsilon then
			--`left` now represents the overflow or a very small underflow, a tiny curve that's left,
			--which we swallow into this one and make this the last curve.
			sweep = sweep + left
			left = 0
		end
		glue.append(segments, elliptic_arc_segment_to_bezier3(cx, cy, rx, ry, angle, sweep))
		angle = angle + sweep
	end
	--update arc endpoints to exactly match the ones approximated by elliptic_arc_endpoints()
	local x1, y1, x2, y2 = elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
	segments[1] = x1
	segments[2] = y1
	segments[#segments-1] = x2
	segments[#segments] = y2
	return segments
end

local function arc_to_bezier3(cx, cy, r, start_angle, sweep_angle)
	return elliptic_arc_to_bezier3(cx, cy, r, r, start_angle, sweep_angle)
end

local function arc_endpoints(cx, cy, r, start_angle, sweep_angle)
	return elliptic_arc_endpoints(cx, cy, r, r, start_angle, sweep_angle)
end

--evaluate arc at time t (the time between 0..1 covers the arc over the sweep interval).
local function arc_point(t, cx, cy, r, start_angle, sweep_angle)
	r = abs(r)
	return
		cx + r * cos(start_angle + t * sweep_angle),
		cy + r * sin(start_angle + t * sweep_angle)
end

local function arc_length(r, sweep_angle)
	return abs(sweep_angle * r)
end

--split arc into two arcs at time t (t is capped between 0..1).
local function arc_split(t, cx, cy, r, start_angle, sweep_angle)
	t = min(max(t,0),1)
	local sweep1 = t * sweep_angle
	local sweep2 = sweep_angle - sweep1
	local split_angle = start_angle + sweep1
	return
		cx, cy, r, start_angle, sweep1, --first arc
		cx, cy, r, split_angle, sweep2  --second arc
end

local function sign(x) return x >= 0 and 1 or -1 end

local function observed_sweep(sweep_angle) --we can only observe the first -360..360deg of the arc.
	return max(min(sweep_angle, 2*pi), -2*pi)
end

--shortest distance-squared from point (x0, y0) to an arc, plus the touch point, and the time
--in the arc where the touch point splits the arc.
local function arc_hit(x0, y0, cx, cy, r, start_angle, sweep_angle)
	r = abs(r)
	if x0 == cx and y0 == cy then --projecting from the center
		local x, y = point_around(cx, cy, r, start_angle)
		return r, x, y, 0
	end
	local a = point_angle(x0, y0, cx, cy)
	local a1 = start_angle
	local a2 = start_angle + observed_sweep(sweep_angle)
	--normalize angles in 0..2pi
	a = a % (2*pi)
	a1 = a1 % (2*pi)
	a2 = a2 % (2*pi)
	--find sweep from a1 to a
	local sweep = a - a1
	if sign(sweep_angle) ~= sign(sweep) then
		sweep = sweep + 2*pi * sign(sweep_angle)
	end
	local t = sweep / sweep_angle
	--check if point is outside arc's opening
	if sweep_angle < 0 then a2, a1 = a1, a2 end
	if a1 < a2 then
		if a < a1 or a > a2 then return end
	else
		if a < a1 and a > a2 then return end
	end
	local x, y = point_around(cx, cy, r, a)
	return point_distance2(x0, y0, x, y), x, y, t
end

if not ... then require'path_arc_demo' end

return {
	elliptic_arc_to_bezier3 = elliptic_arc_to_bezier3,
	arc_to_bezier3 = arc_to_bezier3,
	arc_endpoints = arc_endpoints,
	--hit & split API
	arc_point = arc_point,
	arc_length = arc_length,
	arc_split = arc_split,
	arc_hit = arc_hit,
}
