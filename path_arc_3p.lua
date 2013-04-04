--math for 2D circular arcs defined as (x1, y1, xp, yp, x2, y2) where (x1, y1) and (x2, y2) are its end points,
--and (xp, yp) is a third point on the arc. if the 3 points are collinear, then the arc is the line between
--(x1, y1) and (x2, y2), regardless of where (xp, yp) is.

local distance2    = require'path_point'.distance2
local point_angle  = require'path_point'.point_angle

local line_bounding_box = require'path_line'.bounding_box
local line_to_bezier3   = require'path_line'.to_bezier3
local line_point        = require'path_line'.point
local line_length       = require'path_line'.length
local line_hit          = require'path_line'.hit
local line_split        = require'path_line'.split

local circle_3p_to_circle = require'path_circle_3p'.to_circle

local sweep_between  = require'path_elliptic_arc'.sweep_between
local observed_sweep = require'path_elliptic_arc'.observed_sweep
local arc_to_bezier3 = require'path_arc'.to_bezier3
local arc_endpoints  = require'path_arc'.endpoints
local arc_point      = require'path_arc'.point
local arc_length     = require'path_arc'.length
local arc_split      = require'path_arc'.split
local arc_hit        = require'path_arc'.hit

local function to_arc(x1, y1, xp, yp, x2, y2)
	local cx, cy, r = circle_3p_to_circle(x1, y1, xp, yp, x2, y2)
	if not cx then return end
	local start_angle = point_angle(x1, y1, cx, cy)
	local end_angle   = point_angle(x2, y2, cx, cy)
	local ctl_angle   = point_angle(xp, yp, cx, cy)
	local sweep_angle = sweep_between(start_angle, end_angle)
	local ctl_sweep   = sweep_between(start_angle, ctl_angle)
	if ctl_sweep > sweep_angle then
		--control point is outside the positive sweep, must be inside the negative sweep then.
		sweep_angle = sweep_between(start_angle, end_angle, false)
	end
	return cx, cy, r, start_angle, sweep_angle, x2, y2
end

local function transform_endpoints(mt, x1, y1, x2, y2)
	if mt then
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
	end
	return x1, y1, x2, y2
end

local function to_bezier3(write, x1, y1, xp, yp, x2, y2, mt, ...)
	local cx, cy, r, start_angle, sweep_angle = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then
		--ponts are collinear, radius is infinite, arc is a line between p1 and p2 or an infinite line
		--interrupted between p1 and p2 but we can't draw that so we draw a line between p1 and p2 either way.
		x1, y1, x2, y2 = transform_endpoints(mt, x1, y1, x2, y2)
		write('curve', select(3, line_to_bezier3(x1, y1, x2, y2)))
		return
	end
	arc_to_bezier3(write, cx, cy, r, start_angle, sweep_angle, x2, y2, mt, ...)
end

local function bounding_box(t, x1, y1, xp, yp, x2, y2, mt)
	local cx, cy, r, start_angle, sweep_angle, x2, y2 = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then
		x1, y1, x2, y2 = transform_endpoints(mt, x1, y1, x2, y2)
		return line_bounding_box(x1, y1, x2, y2)
	end
	return arc_bounding_box(t, cx, cy, r, start_angle, sweep_angle, x2, y2, mt)
end

local function point(t, x1, y1, xp, yp, x2, y2)
	local cx, cy, r, start_angle, sweep_angle, x2, y2 = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then
		x1, y1, x2, y2 = transform_endpoints(mt, x1, y1, x2, y2)
		return line_point(t, x1, y1, x2, y2)
	end
	return arc_point(t, cx, cy, r, start_angle, sweep_angle, x2, y2)
end

local function length(t, x1, y1, xp, yp, x2, y2)
	local cx, cy, r, start_angle, sweep_angle, x2, y2 = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then
		x1, y1, x2, y2 = transform_endpoints(mt, x1, y1, x2, y2)
		return line_length(t, x1, y1, x2, y2)
	end
	return arc_length(t, cx, cy, r, start_angle, sweep_angle, x2, y2)
end

local function split(t, x1, y1, xp, yp, x2, y2)
	local cx, cy, r, start_angle, sweep_angle, x2, y2 = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then return line_split(t, x1, y1, x2, y2) end
	local
		cx1, cy1, r1, start_angle1, sweep_angle1,
		cx2, cy2, r2, start_angle2, sweep_angle2 = arc_split(t, cx, cy, r, start_angle, sweep_angle, x2, y2)
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

local function hit(x0, y0, x1, y1, xp, yp, x2, y2)
	local cx, cy, r, start_angle, sweep_angle, x2, y2 = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then return line_hit(x0, y0, x1, y1, x2, y2) end
	return arc_hit(x0, y0, cx, cy, r, start_angle, sweep_angle, x2, y2)
end

return {
	to_arc = to_arc,
	--path API
	to_bezier3 = to_bezier3,
	point = point,
	length = length,
	split = split,
	hit = hit,
}

