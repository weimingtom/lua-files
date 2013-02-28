--2d geometry solutions from various sources.
local bezier = require'path_bezier'

local sqrt, abs, atan2, cos, sin, pi, log =
	math.sqrt, math.abs, math.atan2, math.cos, math.sin, math.pi, math.log

--hypotenuse function: computes sqrt((x2 - x1)^2 + (y2 - y1)^2) without overflow/underflow problems.
local function hypot(x, y)
	x, y = abs(x), abs(y)
	local t = min(x, y)
	x = max(x, y)
	t = t / x
	return x * sqrt(1 + t * t)
end

local function point_angle(x1, y1, x2, y2) --the angle between two points
	return atan2(y2 - y1, x2 - x1)
end

local function point_distance(x1, y1, x2, y2) --the distance between two points
	return hypot(x2 - x1, y2 - y1)
end

local function arc_point(xc, yc, distance, angle) --point at distance and angle from origin
	return
		xc + cos(angle) * distance,
		yc + sin(angle) * distance
end

local function arc_length(radius, sweep_angle) --length of a circular arc
	return sweep_angle * radius
end

local function rotate_point(x, y, xc, yc, angle) --point rotated at an angle around origin
	x, y = x - xc, y - yc
	local cs, sn = cos(angle), sin(angle)
	return
		x * cs - y * sn + xc,
		y * cs + x * sn + yc
end

local function reflect_point(x, y, xc, yc) --point reflected through origin (rotated 180deg around origin)
	return 2 * xc - x, 2 * yc - y
end

--get the control points of a cubic bezier corresponding to a quadratic bezier.
local function cubic_control_points(x1, y1, x2, y2, x3, y3) --bezier degree elevation
	return
		(x1 + 2 * x2) / 3,
		(y1 + 2 * y2) / 3,
		(x3 + 2 * x2) / 3,
		(y3 + 2 * y2) / 3
end

--get the control point of a quadratic bezier that (wildly) approximates a cubic bezier.
--the equation has two solutions, which are averaged out to form the final control point.
local function quad_control_points(x1, y1, x2, y2, x3, y3, x4, y4)
	return
		-.25*x1 + .75*x2 + .75*x3 -.25*x4,
		-.25*y1 + .75*y2 + .75*y3 -.25*y4
end

--evaluate a line at time t between 0..1
local function line_point(t, x1, y1, x2, y2)
	return x1 + t * (x2 - x1), y1 + t * (y2 - y1)
end

local line_length = point_distance

--evaluate a quad bezier at time t (t is between 0..1) based on de Casteljau interpolation algorithm.
--returns the point at t plus the 2 control points of the two quad curves resulting from splitting the curve at t.
local function quad_curve_point(t, x1, y1, x2, y2, x3, y3)
	local mint = 1 - t
	local c1x = x1 * mint + x2 * t
	local c1y = y1 * mint + y2 * t
	local c2x = x2 * mint + x3 * t
	local c2y = y2 * mint + y3 * t
	local x = c1x * mint + c2x * t
	local y = c1y * mint + c2y * t
	return
		x, y,     --the breaking point
		c1x, c1y, --curve1.control_point
		c2x, c2y  --curve2.control_point
end

--length of quad bezier curve using closed-form solution from http://segfaultlabs.com/docs/quadratic-bezier-curve-length.
local function quad_curve_length(x1, y1, x2, y2, x3, y3)
	local ax = x1 - 2*x2 + x3
	local ay = y1 - 2*y2 + y3
	local bx = 2*x2 - 2*x1
	local by = 2*y2 - 2*y1
	local A = 4*(ax*ax + ay*ay)
	local B = 4*(ax*bx + ay*by)
	local C = bx*bx + by*by
	local Sabc = 2*sqrt(A+B+C)
	local A2 = sqrt(A)
	local A32 = 2*A*A2
	local C2 = 2*sqrt(C)
	local BA = B/A2
	return (A32*Sabc + A2*B*(Sabc - C2) + (4*C*A - B*B)*log((2*A2 + BA + Sabc) / (BA+C2))) / (4*A32)
end

--evaluate a cubic bezier at time t (t is between 0..1) based on de Casteljau interpolation algorithm.
--returns the point at t plus the 4 control points of the two cubic curves resulting from splitting the curve at t.
local function curve_point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	local mint = 1 - t
	local x12 = x1 * mint + x2 * t
	local y12 = y1 * mint + y2 * t
	local x23 = x2 * mint + x3 * t
	local y23 = y2 * mint + y3 * t
	local x34 = x3 * mint + x4 * t
	local y34 = y3 * mint + y4 * t
	local c1x = x12 * mint + x23 * t
	local c1y = y12 * mint + y23 * t
	local c2x = x23 * mint + x34 * t
	local c2y = y23 * mint + y34 * t
	local x = c1x * mint + c2x * t
	local y = c1y * mint + c2y * t
	return
		x, y,      --the break point
		x12, y12,  --curve1.cp1
		c1x, c1y,  --curve1.cp2
		c2x, c2y,  --curve2.cp1
		x34, y34   --curve2.cp2
end

--integrates the estimated length of the cubic bezier curve by adding the lengths of linear lines between points at t.
--the number of points is defined by n: n=10 would add the lengths of lines between 0.0 and 0.1, between 0.1 and 0.2 etc.
--the default n=20 is fine for most cases, usually resulting in a deviation of less than 0.01.
local function curve_length(x1, y1, x2, y2, x3, y3, x4, y4, n)
	n = n or 20
	local xi, yi = x0, y0
	local length = 0
	for i=1,n do
		local x, y = curve_point(i / n, x1, y1, x2, y2, x3, y3, x4, y4)
		length = length + line_length(xi, yi, x, y)
		xi, yi = x, y
	end
	return length
end

--intersect infinite line with its perpendicular from point (x, y).
local function point_line_intersection(x, y, x1, y1, x2, y2)
	local px = x2 - x1
	local py = y2 - y1
	local k = px^2 + py^2
	if k == 0 then return x1, y1 end --line has no length
	local k = ((x - x1) * py - (y - y1) * px) / k
	return x - k * py, y + k * px
end

--shortest distance from (x0, y0) to a line segment.
local function point_line_segment_distance(x0, y0, x1, y1, x2, y2)
	local x, y = point_line_intersection(x0, y0, x1, y1, x2, y2)
	if x < x1 or x > x2 or y < y1 or y > y2 then return end --intersection is outside the segment
	return point_distance(x0, y0, x, y)
end

local function point_line_segment_cut(x0, y0, x1, y1, x2, y2)

end

--
local function point_arc_distance(x0, y0, cx, cy, r, start_angle, sweep_angle)

end

local function point_quad_curve_distance(x0, y0, x1, y1, x2, y2, x3, y3)

end

local function point_curve_distance(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)

end

--[[

--intersect line segment (x1, y1, x2, y2) with line segment (x3, y3, x4, y4).
--returns the time on the first line and the time on the second line where intersection occurs.
--if the intersection occurs outside the segments themselves, then t1 and t2 are outside the 0..1 range.
--if the lines are parallel or coincidental then t1 and t2 are infinite.
local function line_line_intersection(x1, y1, x2, y2, x3, y3, x4, y4)
	local d = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)
	if d == 0 then return 1/0, 1/0 end
	return
		((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / d,
		((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / d
end

local function point_line_distance(x, y, x1, y1, x2, y2)
	return abs((x - x1) * (y2 - y1) - (y - y1) * (x2 - x1)) / hypot(x2 - x1, y2 - y1)
end

--intersection point between a line segment (x01, y01, x02, y02) and a cubic bezier curve.
local function line_curve_intersection(x01, y01, x02, y02, x1, y1, x2, y2, x3, y3, x4, y4,
														m_approximation_scale, m_angle_tolerance, m_cusp_limit)
	local x, y
	local function write(_, x2, y2)
		x, y = segment_segment_intersection(x01, y01, x02, y02, x1, y1, x2, y2)
		x1, y1 = x2, y2
	end
	bezier(write, x1, y1, x2, y2, x3, y3, x4, y4, m_approximation_scale, m_angle_tolerance, m_cusp_limit)
	return x, y
end
]]

if not ... then require'path_math_demo' end

return {
	point_angle = point_angle,
	point_distance = point_distance,
	rotate_point = rotate_point,
	reflect_point = reflect_point,

	cubic_control_points = cubic_control_points,
	quad_control_points = quad_control_points,

	arc_point = arc_point,
	arc_length = arc_length,

	line_point = line_point,
	line_length = line_length,

	quad_curve_point = quad_curve_point,
	quad_curve_length = quad_curve_length,

	curve_point = curve_point,
	curve_length = curve_length,

	--[[
	point_line_intersection = point_line_intersection,
	point_arc_intersection = point_arc_intersection,
	line_line_intersection = line_line_intersection,
	line_curve_intersection = line_curve_intersection,
	]]
}

