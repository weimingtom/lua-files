--math for 2d circular arcs defined as the arc between points (x1, y1) and (x3, y3) which passes through (x2, y2).

local point_angle = require'path_point'.angle
local point_distance2 = require'path_point'.distance2
local circle_3p_to_circle = require'path_circle_3p'.to_circle
local arc_to_bezier3 = require'path_arc'.to_bezier3
local arc_endpoints = require'path_arc'.endpoints
local observed_sweep = require'path_arc'.observed_sweep
local arc_point = require'path_arc'.point
local arc_length = require'path_arc'.length
local arc_split = require'path_arc'.split
local arc_hit = require'path_arc'.hit
local sweep_between = require'path_arc'.sweep_between

local pi = math.pi

local function arc_3p_to_arc(x1, y1, x2, y2, x3, y3)
	local cx, cy, r = circle_3p_to_circle(x1, y1, x2, y2, x3, y3)
	if not cx then return end --points are collinear, can't make an arc.
	local start_angle = point_angle(x1, y1, cx, cy)
	local end_angle   = point_angle(x3, y3, cx, cy)
	local ctl_angle   = point_angle(x2, y2, cx, cy)
	local sweep_angle = sweep_between(start_angle, end_angle)
	local ctl_sweep   = sweep_between(start_angle, ctl_angle)
	if ctl_sweep > sweep_angle then --control point outside the positive sweep, must be inside the negative sweep then.
		sweep_angle = sweep_between(start_angle, end_angle, false)
	end
	return cx, cy, r, start_angle, sweep_angle
end

local function arc_to_arc_3p(cx, cy, r, start_angle, sweep_angle)
	local x1, y1, x2, y2 = arc_endpoints(cx, cy, r, start_angle, sweep_angle)
	local x3, y3 = point_angle(cx, cy, r, start_angle + observed_sweep(sweep_angle) / 2)
	return x1, y1, x2, y2, x3, y3
end

local function arc_3p_to_bezier3(x1, y1, x2, y2, x3, y3)
	local cx, cy, r, start_angle, sweep_angle = arc_3p_to_arc(x1, y1, x2, y2, x3, y3)
	if not cx then --ponts are collinear, radius is infinite, arc is a line or nothing
		--find out where p2 is on the line relative to p1 and p3
		local d12 = point_distance2(x1, y1, x2, y2)
		local d23 = point_distance2(x2, y2, x3, y3)
		local d13 = point_distance2(x1, y1, x3, y3)
		if d12 > d13 and d12 > d23 then --p3 is between p1 and p2 and so the arc is a line between p1 and p2
			return 'line', {x1, y1, x2, y2}
		else --p3 is outside p1 and p2 and so the arc is an infinite line interrupted between p1 and p2
			return 'negative_line', {x1, y1, x2, y2}
		end
	end
	local command, segments = arc_to_bezier3(cx, cy, r, start_angle, sweep_angle)
	-- override arc's end points for numerical stability
	segments[1] = x1
	segments[2] = y1
	segments[#segments-1] = x3
	segments[#segments-0] = y3
	return command, segments
end

local function arc_3p_point(t, x1, y1, x2, y2, x3, y3)
	return arc_point(t, arc_3p_to_arc(x1, y1, x2, y2, x3, y3))
end

local function arc_3p_length(t, x1, y1, x2, y2, x3, y3)
	return arc_length(t, arc_3p_to_arc(x1, y1, x2, y2, x3, y3))
end

local function arc_3p_split(t, x1, y1, x2, y2, x3, y3)
	local
		cx1, cy1, r1, start_angle1, sweep_angle1,
		cx2, cy2, r1, start_angle2, sweep_angle2 = arc_split(t, arc_3p_to_arc(x1, y1, x2, y2, x3, y3))
	local ax1, ay1, ax2, ay2, ax3, ay3 = arc_to_arc_3p(cx1, cy1, r1, start_angle1, sweep_angle1)
	local bx1, by1, bx2, by2, bx3, by3 = arc_to_arc_3p(cx2, cy2, r2, start_angle2, sweep_angle2)
	--overide arcs' end points for numerical stability
	ax1, ay1 = x1, y1
	bx3, by3 = x3, y3
	bx1, by1 = ax3, ay3
	return
		ax1, ay1, ax2, ay2, ax3, ay3, --first arc
		bx1, by1, bx2, by2, bx3, by3  --second arc
end

local function arc_3p_hit(x0, y0, x1, y1, x2, y2, x3, y3)
	return arc_hit(x0, y0, arc_3p_to_arc(x1, y1, x2, y2, x3, y3))
end

if not ... then require'path_editor_demo' end

return {
	arc3p_to_arc = arc_3p_to_arc,
	arc_to_arc_3p = arc_to_arc_3p,
	to_bezier3 = arc_3p_to_bezier3,
	--hit & split API
	point = arc_3p_point,
	length = arc_3p_length,
	split = arc_3p_split,
	hit = arc_3p_hit,
}

