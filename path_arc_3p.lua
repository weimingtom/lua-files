--math for 2d circular arcs defined as (x1, y1, xp, yp, x2, y2) where (x1, y1) and (x2, y2) are its end points
--and (xp,yp) is a third point on the arc.

local distance2    = require'path_point'.distance2
local point_angle  = require'path_point'.point_angle
local point_around = require'path_point'.point_around
local line_point = require'path_line'.point
local circle_3p_to_circle = require'path_circle_3p'.to_circle
local sweep_between  = require'path_arc'.sweep_between
local observed_sweep = require'path_arc'.observed_sweep
local arc_to_bezier3 = require'path_arc'.to_bezier3
local arc_endpoints  = require'path_arc'.endpoints
local arc_point      = require'path_arc'.point
local arc_length     = require'path_arc'.length
local arc_split      = require'path_arc'.split
local arc_hit        = require'path_arc'.hit

local function to_arc(x1, y1, xp, yp, x2, y2)
	local cx, cy, r = circle_3p_to_circle(x1, y1, xp, yp, x2, y2)
	if not cx then return end --points are collinear, can't make an arc.
	local start_angle = point_angle(x1, y1, cx, cy)
	local end_angle   = point_angle(x2, y2, cx, cy)
	local ctl_angle   = point_angle(xp, yp, cx, cy)
	local sweep_angle = sweep_between(start_angle, end_angle)
	local ctl_sweep   = sweep_between(start_angle, ctl_angle)
	if ctl_sweep > sweep_angle then --control point is outside the positive sweep, must be inside the negative sweep then.
		sweep_angle = sweep_between(start_angle, end_angle, false)
	end
	return cx, cy, r, start_angle, sweep_angle
end

local function arc_to_arc_3p(cx, cy, r, start_angle, sweep_angle)
	local x1, y1, x2, y2 = arc_endpoints(cx, cy, r, start_angle, sweep_angle)
	local xp, yp = point_around(cx, cy, r, start_angle + observed_sweep(sweep_angle) / 2)
	return x1, y1, xp, yp, x2, y2
end

local function to_bezier3(write, x1, y1, xp, yp, x2, y2)
	local cx, cy, r, start_angle, sweep_angle = to_arc(x1, y1, xp, yp, x2, y2)
	if not cx then --ponts are collinear, radius is infinite, arc is a line
		--find out where pp is on the line relative to p1 and p2
		local d1p = distance2(x1, y1, xp, yp)
		local d2p = distance2(x2, y2, xp, yp)
		local d12 = distance2(x1, y1, x2, y2)
		if d12 > d1p and d12 > d2p then --pp is between p1 and p2 and so the arc is a line between p1 and p2
			write('line', x2, y2)
			return
		else --pp is outside p1 and p2 and so the arc is an infinite line interrupted between p1 and p2
			--TODO: make this so it doesn't interrupts the path!!!
			write('line', line_point(-10000, x1, y1, x2, y2)) --line to -inf
			write('move', line_point( 10000, x1, y1, x2, y2)) --move to +inf
			write('line', x2, y2) --line from +inf to arc endpoint
			return
		end
	end
	arc_to_bezier3(write, cx, cy, r, start_angle, sweep_angle, x2, y2)
end

local function point(t, x1, y1, x2, y2, x3, y3)
	return arc_point(t, to_arc(x1, y1, x2, y2, x3, y3))
end

local function length(t, x1, y1, x2, y2, x3, y3)
	return arc_length(t, to_arc(x1, y1, x2, y2, x3, y3))
end

local function split(t, x1, y1, x2, y2, x3, y3)
	local
		cx1, cy1, r1, start_angle1, sweep_angle1,
		cx2, cy2, r2, start_angle2, sweep_angle2 = arc_split(t, to_arc(x1, y1, x2, y2, x3, y3))
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

local function hit(x0, y0, x1, y1, x2, y2, x3, y3)
	return arc_hit(x0, y0, to_arc(x1, y1, x2, y2, x3, y3))
end

if not ... then require'path_editor_demo' end

return {
	to_arc = to_arc,
	arc_to_arc_3p = arc_to_arc_3p,
	to_bezier3 = to_bezier3,
	--hit & split API
	point = point,
	length = length,
	split = split,
	hit = hit,
}

