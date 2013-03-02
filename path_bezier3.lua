--math for 2d cubic bezier curves defined as (x1, y1, x2, y2, x3, y3, x4, y4)
--where (x2, y2) and (x3, y3) are the control points and (x1, y1) and (x4, y4) are the end points.

local interpolate = require'path_bezier3_ai'
local line_hit = require'path_line'.hit
local point_distance2 = require'path_point'.distance2
local hit_function = require'path_bezier'.hit_function

local min, max = math.min, math.max

--return the control point of a quadratic bezier that (wildly) approximates a cubic bezier.
--the equation has two solutions, which are averaged out to form the final control point.
local function bezier2_control_point(x1, y1, x2, y2, x3, y3, x4, y4)
	return
		-.25*x1 + .75*x2 + .75*x3 -.25*x4,
		-.25*y1 + .75*y2 + .75*y3 -.25*y4
end

--split a cubic bezier at time t (t is capped between 0..1) into two curves using De Casteljau interpolation.
local function bezier3_split(t, x1, y1, x2, y2, x3, y3, x4, y4)
	t = min(max(t,0),1)
	local mint = 1 - t
	local x12 = x1 * mint + x2 * t
	local y12 = y1 * mint + y2 * t
	local x23 = x2 * mint + x3 * t
	local y23 = y2 * mint + y3 * t
	local x34 = x3 * mint + x4 * t
	local y34 = y3 * mint + y4 * t
	local x123 = x12 * mint + x23 * t
	local y123 = y12 * mint + y23 * t
	local x234 = x23 * mint + x34 * t
	local y234 = y23 * mint + y34 * t
	local x1234 = x123 * mint + x234 * t
	local y1234 = y123 * mint + y234 * t
	return
		x1, y1, x12, y12, x123, y123, x1234, y1234, --first curve
		x1234, y1234, x234, y1234, x34, y34, x4, y4 --second curve
end

--evaluate a cubic bezier at time t (t is capped between 0..1) using linear interpolation.
local function bezier3_point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	local x, y = select(7, bezier3_split(t, x1, y1, x2, y2, x3, y3, x4, y4))
	return x, y
end

--approximate length of a cubic bezier.
--computed by summing up the lengths of the segments resulted from the recursive adaptive interpolation of the curve.
local function bezier3_length(x1, y1, x2, y2, x3, y3, x4, y4, m_approximation_scale)
	local x0, y0 = x1, y1
	local length = 0
	local function write(_, x, y)
		length = length + line_length(x0, y0, x, y)
		x0, y0 = x, y
	end
	interpolate(write, x1, y1, x2, y2, x3, y3, x4, y4, m_approximation_scale)
	return length
end

local bezier3_hit = hit_function(interpolate)

if not ... then require'path_hit_demo' end

return {
	bezier2_control_point = bezier2_control_point,
	interpolate = interpolate,
	--hit & split API
	point = bezier3_point,
	length = bezier3_length,
	split = bezier3_split,
	hit = bezier3_hit,
}

