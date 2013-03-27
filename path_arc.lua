--math for 2D circular arcs defined as (centerx, centery, radius, start_angle, sweep_angle).
--angles are expressed in degrees, not radians. sweep angle is capped between -360..360deg when drawing but
--otherwise the time on the arc is relative to the full sweep.

local distance2    = require'path_point'.distance2
local point_angle  = require'path_point'.point_angle
local point_around = require'path_point'.point_around
local observed_sweep           = require'path_elliptic_arc'.observed_sweep
local elliptic_arc_endpoints   = require'path_elliptic_arc'.endpoints
local elliptic_arc_to_bezier3  = require'path_elliptic_arc'.to_bezier3

local abs, min, max, radians = math.abs, math.min, math.max, math.rad

--observed sweep between two arbitrary angles, sweeping from a1 to a2 in a specified direction.
local function sweep_between(a1, a2, clockwise)
	a1 = a1 % 360
	a2 = a2 % 360
	clockwise = clockwise ~= false
	local sweep = a2 - a1
	if sweep < 0 and clockwise then
		sweep = sweep + 360
	elseif sweep > 0 and not clockwise then
		sweep = sweep - 360
	end
	return sweep
end

--angle time on an arc (or outside the arc if is outside 0..1 range) for a specified angle.
local function sweep_time(hit_angle, start_angle, sweep_angle)
	return sweep_between(start_angle, hit_angle, sweep_angle >= 0) / sweep_angle
end

--test if an angle is inside the sweeped arc.
local function is_sweeped(hit_angle, start_angle, sweep_angle)
	local t = sweep_time(hit_angle, start_angle, sweep_angle)
	return t >= 0 and t <= 1
end

local function endpoints(cx, cy, r, start_angle, sweep_angle, x2, y2, ...)
	return elliptic_arc_endpoints(cx, cy, r, r, start_angle, sweep_angle, 0, x2, y2, ...)
end

--return a fake control point to serve as reflection point for a following smooth curve.
local function smooth_point(cx, cy, r, start_angle, sweep_angle, x2, y2, ...)
	--TODO: construct a point on the tangent of the arc's second endpoint
	return select(3, endpoints(cx, cy, r, start_angle, sweep_angle, 0, x2, y2, ...))
end

local function to_bezier3(write, cx, cy, r, start_angle, sweep_angle, x2, y2, ...)
	elliptic_arc_to_bezier3(write, cx, cy, r, r, start_angle, sweep_angle, 0, x2, y2, ...)
end

--convert to a 3-point parametric arc.
local function to_arc_3p(cx, cy, r, start_angle, sweep_angle, x2, y2)
	local x1, y1, x2, y2 = endpoints(cx, cy, r, start_angle, sweep_angle, x2, y2)
	local xp, yp = point_around(cx, cy, r, start_angle + observed_sweep(sweep_angle) / 2)
	return x1, y1, xp, yp, x2, y2
end

--bounding box as (x,y,w,h) for a circular arc.
local function bounding_box(cx, cy, r, start_angle, sweep_angle, x2, y2)
	local x1, y1, x2, y2 = endpoints(cx, cy, r, start_angle, sweep_angle, x2, y2)
	--assume the bounding box is between endpoints, i.e. that the arc doesn't touch any of its circle's extremities.
	local x1, x2 = min(x1, x2), max(x1, x2)
	local y1, y2 = min(y1, y2), max(y1, y2)
	if is_sweeped(0, start_angle, sweep_angle) then --arc touches its circle's rightmost point
		x2 = cx + r
	end
	if is_sweeped(90, start_angle, sweep_angle) then --arc touches its circle's most bottom point
		y2 = cy + r
	end
	if is_sweeped(180, start_angle, sweep_angle) then --arc touches its circle's leftmost point
		x1 = cx - r
	end
	if is_sweeped(-90, start_angle, sweep_angle) then --arc touches its circle's topmost point
		y1 = cy - r
	end
	return x1, y1, x2-x1, y2-y1
end

--evaluate circular arc at time t (the time between 0..1 covers the arc over the sweep interval).
local function point(t, cx, cy, r, start_angle, sweep_angle)
	return point_around(cx, cy, abs(r), start_angle + t * sweep_angle)
end

--length of circular arc at time t.
local function length(t, cx, cy, r, start_angle, sweep_angle)
	return abs(t * radians(sweep_angle) * r)
end

--split a circular arc into two arcs at time t (t is capped between 0..1).
local function split(t, cx, cy, r, start_angle, sweep_angle)
	t = min(max(t,0),1)
	local sweep1 = t * sweep_angle
	local sweep2 = sweep_angle - sweep1
	local split_angle = start_angle + sweep1
	return
		cx, cy, r, start_angle, sweep1, --first arc
		cx, cy, r, split_angle, sweep2  --second arc
end

--shortest distance-squared from point (x0, y0) to a circular arc, plus the touch point, and the time in the arc
--where the touch point splits the arc.
local function hit(x0, y0, cx, cy, r, start_angle, sweep_angle, x2, y2)
	r = abs(r)
	if x0 == cx and y0 == cy then --projecting from the center
		local x, y = point_around(cx, cy, r, start_angle)
		return r, x, y, 0
	end
	local hit_angle = point_angle(x0, y0, cx, cy)
	local end_angle = start_angle + observed_sweep(sweep_angle)
	local t = sweep_time(hit_angle, start_angle, sweep_angle)
	if t < 0 or t > 1 then --hit point is outside arc's sweep opening, check distance to end points
		local x1, y1, x2, y2 = endpoints(cx, cy, r, start_angle, sweep_angle, x2, y2)
		local d1 = distance2(x0, y0, x1, y1)
		local d2 = distance2(x0, y0, x2, y2)
		if d1 <= d2 then
			return d1, x1, y1, 0
		else
			return d2, x2, y2, sweep_time(end_angle, start_angle, sweep_angle)
		end
	end
	local x, y = point_around(cx, cy, r, hit_angle)
	return distance2(x0, y0, x, y), x, y, t
end

if not ... then require'path_arc_demo' end

return {
	observed_sweep = observed_sweep,
	sweep_between = sweep_between,
	is_sweeped = is_sweeped,
	endpoints = endpoints,
	smooth_point = smooth_point,
	to_arc_3p = to_arc_3p,
	--path API
	to_bezier3 = to_bezier3,
	bounding_box = bounding_box,
	point = point,
	length = length,
	split = split,
	hit = hit,
}

