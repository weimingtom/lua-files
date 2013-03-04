--math for 2d circular arcs defined as (centerx, centery, radius, start_angle, sweep_angle).
--sweep angle is capped between -360..360deg when drawing but otherwise the time on the arc is relative to the full sweep.

local glue = require'glue'
local point_angle = require'path_point'.angle
local point_around = require'path_point'.around
local point_distance2 = require'path_point'.distance2
local elliptic_arc_to_bezier3 = require'path_elliptic_arc'.to_bezier3
local elliptic_arc_endpoints = require'path_elliptic_arc'.endpoints

local abs, sin, cos, min, max, pi = math.abs, math.sin, math.cos, math.min, math.max, math.pi

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

local function observed_sweep(sweep_angle) --we can only observe the first -360..360deg of the sweep.
	return max(min(sweep_angle, 2*pi), -2*pi)
end

local function sweep_between(a1, a2, clockwise) --observed sweep between two arbitrary angles.
	a1 = a1 % (2*pi)
	a2 = a2 % (2*pi)
	clockwise = clockwise ~= false
	local sweep = a2 - a1
	if sweep < 0 and clockwise then
		sweep = sweep + 2*pi
	elseif sweep > 0 and not clockwise then
		sweep = sweep - 2*pi
	end
	return sweep
end

--shortest distance-squared from point (x0, y0) to an arc, plus the touch point, and the time
--in the arc where the touch point splits the arc.
local function arc_hit(x0, y0, cx, cy, r, start_angle, sweep_angle)
	r = abs(r)
	if x0 == cx and y0 == cy then --projecting from the center
		local x, y = point_around(cx, cy, r, start_angle)
		return r, x, y, 0
	end
	local hit_angle = point_angle(x0, y0, cx, cy)
	local end_angle = start_angle + observed_sweep(sweep_angle)
	local sweep = sweep_between(start_angle, hit_angle, sweep_angle >= 0)
	local t = sweep / sweep_angle
	if t > 1 then return end --hit point is outside arc's sweep
	local x, y = point_around(cx, cy, r, hit_angle)
	return point_distance2(x0, y0, x, y), x, y, t
end

if not ... then require'path_arc_demo' end

return {
	to_bezier3 = arc_to_bezier3,
	endpoints = arc_endpoints,
	observed_sweep = observed_sweep,
	sweep_between = sweep_between,
	--hit & split API
	point = arc_point,
	length = arc_length,
	split = arc_split,
	hit = arc_hit,
}

