--math for 2d cubic bezier curves defined as (x1, y1, x2, y2, x3, y3, x4, y4)
--where (x2, y2) and (x3, y3) are the control points and (x1, y1) and (x4, y4) are the end points.

local bezier3_to_lines = require'path_bezier3_ai'
local bezier3_to_lines_linear = require'path_bezier3_li'

local min, max, sqrt = math.min, math.max, math.sqrt

local function bezier3_value(t, x1, x2, x3, x4) --compute B(t) for one dimension (see wikipedia).
	return (1-t)^3 * x1 + 3*(1-t)^2*t * x2 + 3*(1-t)*t^2 * x3 + t^3 * x4
end

local function bezier3_first_derivative_roots(a, b, c, d) --solve B(t)'=0 for one dimension (use wolframalpha.com).
	local base = -a*c + a*d+b^2 - b*c - b*d+c^2
	local denom = -a + 3*b - 3*c + d
	if base > 0 and denom ~= 0 then
		local sq = sqrt(base)
		return
			 (sq - a + 2*b - c) / denom,
			(-sq - a + 2*b - c) / denom
	else
		local denom = 2*(a - 2*b + c)
		if denom ~= 0 then
			return (a-b) / denom
		end
	end
end

local function bezier3_minmax(x1, x2, x3, x4) --min and max values for B(t) for one dimension.
	--start off with the assumption that the curve doesn't extend past its endpoints.
	local minx = min(x1, x4)
	local maxx = max(x1, x4)
	--if the curve has local minima and/or maxima then adjust the bounding box.
	local t1, t2 = bezier3_first_derivative_roots(x1, x2, x3, x4)
	if t1 and t1 >= 0 and t1 <= 1 then
		local x = bezier3_value(t1, x1, x2, x3, x4)
		minx = min(x, minx)
		maxx = max(x, maxx)
	end
	if t2 and t2 >= 0 and t2 <= 1 then
		local x = bezier3_value(t2, x1, x2, x3, x4)
		minx = min(x, minx)
		maxx = max(x, maxx)
	end
	return minx, maxx
end

local function bezier3_bounding_box(x1, y1, x2, y2, x3, y3, x4, y4) --bounding box as (x, y, w, h)
	local minx, maxx = bezier3_minmax(x1, x2, x3, x4)
	local miny, maxy = bezier3_minmax(y1, y2, y3, y4)
	return minx, miny, maxx-minx, maxy-miny
end

--return the control point of a quadratic bezier that (wildly) approximates a cubic bezier.
--the equation has two solutions, which are averaged out to form the final control point.
local function bezier2_control_point(x1, y1, x2, y2, x3, y3, x4, y4)
	return
		-.25*x1 + .75*x2 + .75*x3 -.25*x4,
		-.25*y1 + .75*y2 + .75*y3 -.25*y4
end

--evaluate a cubic bezier at time t (t is capped between 0..1) using linear interpolation.
local function bezier3_point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	t = min(max(t,0),1)
	return
		bezier3_value(t, x1, x2, x3, x4),
		bezier3_value(t, y1, y2, y3, y4)
end

--approximate length of a cubic bezier by integrating the linear interpolation of the curve.
local function bezier3_length(x1, y1, x2, y2, x3, y3, x4, y4, steps)
	local x0, y0 = x1, y1
	local length = 0
	local function write(_, x, y)
		length = length + line_length(x0, y0, x, y)
		x0, y0 = x, y
	end
	bezier3_to_lines_linear(write, x1, y1, x2, y2, x3, y3, x4, y4, steps or 100)
	return length
end

--split a cubic bezier at time t (t is capped between 0..1) into two curves using De Casteljau interpolation.
local function bezier3_split(t, x1, y1, x2, y2, x3, y3, x4, y4)
	t = min(max(t,0),1)
	local mt = 1-t
	local x12 = x1 * mt + x2 * t
	local y12 = y1 * mt + y2 * t
	local x23 = x2 * mt + x3 * t
	local y23 = y2 * mt + y3 * t
	local x34 = x3 * mt + x4 * t
	local y34 = y3 * mt + y4 * t
	local x123 = x12 * mt + x23 * t
	local y123 = y12 * mt + y23 * t
	local x234 = x23 * mt + x34 * t
	local y234 = y23 * mt + y34 * t
	local x1234 = x123 * mt + x234 * t
	local y1234 = y123 * mt + y234 * t
	return
		x1, y1, x12, y12, x123, y123, x1234, y1234, --first curve
		x1234, y1234, x234, y1234, x34, y34, x4, y4 --second curve
end

if not ... then require'path_hit_demo' end

return {
	bounding_box = bezier3_bounding_box,
	bezier2_control_point = bezier2_control_point,
	to_lines = bezier3_to_lines,
	to_lines_linear = bezier_to_lines_linear,
	--hit & split API
	point = bezier3_point,
	length = bezier3_length,
	split = bezier3_split,
	hit1 = bezier3_hit1,
	hit2 = bezier3_hit2,
}

