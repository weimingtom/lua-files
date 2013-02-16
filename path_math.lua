--path math from various sources.
local bezier_function = require'path_bezier'

local sqrt, abs, atan2, cos, sin, pi =
	math.sqrt, math.abs, math.atan2, math.cos, math.sin, math.pi

local function point_angle(x0, y0, x1, y1) --the angle between two points
	return atan2(y1 - y0, x1 - x0)
end

local function point_distance(x0, y0, x1, y1) --the distance between two points
	return sqrt((x1 - x0)^2) + (y1 - y0)^2
end

local function point_at(x0, y0, distance, angle) --point at distance and angle from origin
	return
		x0 + cos(angle) * distance,
		y0 + sin(angle) * distance
end

local function rotate_point(x, y, x0, y0, angle) --point rotated at an angle around origin
	x, y = x - x0, y - y0
	local cs, sn = cos(angle), sin(angle)
	return
		x * cs - y * sn + x0,
		y * cs + x * sn + y0
end

local function reflect_point(x, y, x0, y0, d, a) --point reflected through origin
	d = d or 1 --same length
	a = a or pi --opposite point
	if d == 1 and a == pi then
		return 2 * x0 - x, 2 * y0 - y
	else
		return point_at(x0, y0, d * point_distance(x0, y0, x, y), a + point_angle(x0, y0, x, y))
	end
end

--get the control points of a cubic bezier corresponding to a quadratic bezier.
local function cubic_control_points(x1, y1, x2, y2, x3, y3) --bezier degree elevation
	return
		(x1 + 2 * x2) / 3,
		(y1 + 2 * y2) / 3,
		(x3 + 2 * x2) / 3,
		(y3 + 2 * y2) / 3
end

--get the control point of a quadratic bezier that approximates a cubic bezier.
--the equation has two solutions, which are averaged out to form the final control point.
local function quad_control_points(x1, y1, x2, y2, x3, y3, x4, y4)
	return
		-.25*x1 + .75*x2 + .75*x3 -.25*x4,
		-.25*y1 + .75*y2 + .75*y3 -.25*y4
end

--evaluate a line at t between 0..1.
local function line_point(t, x0, y0, x1, y1)
	return x0 + t * (x1 - x0), y0 + t * (y1 - y0)
end

local function line_length(x0, y0, x1, y1)
	return sqrt(abs(x0 - x1)^2 + abs(y0 - y1)^2)
end

--evaluate a cubic bezier at t between 0..1 based on the de Casteljau interpolation algorithm.
--returns the point at t plus the control points of the two curves resulting from splitting the curve at t.
local function curve_point(t, x0, y0, x1, y1, x2, y2, x3, y3)
	local mint = 1 - t
	local x01 = x0 * mint + x1 * t
	local y01 = y0 * mint + y1 * t
	local x12 = x1 * mint + x2 * t
	local y12 = y1 * mint + y2 * t
	local x23 = x2 * mint + x3 * t
	local y23 = y2 * mint + y3 * t
	local out_c1x = x01 * mint + x12 * t
	local out_c1y = y01 * mint + y12 * t
	local out_c2x = x12 * mint + x23 * t
	local out_c2y = y12 * mint + y23 * t
	local out_x = out_c1x * mint + out_c2x * t
	local out_y = out_c1y * mint + out_c2y * t
	return
		out_x, out_y,      --the break point
		out_c1x, out_c1y,  --curve1.cp2
		out_c2x, out_c2y,  --curve2.cp1
		x01, y01,          --curve1.cp1
		x23, y23           --curve2.cp2
end

--integrates the estimated length of the cubic bezier curve by adding the lengths of linear lines between points at t.
--the number of points is defined by n: n=10 would add the lengths of lines between 0.0 and 0.1, between 0.1 and 0.2 etc.
--the default n=20 is fine for most cases, usually resulting in a deviation of less than 0.01.
--TODO: implement this with the adaptive interpolation method and compare the accuracy and speed.
local function curve_length(x0, y0, x1, y1, x2, y2, x3, y3, n)
	n = n or 20
	local xi, yi = x0, y0
	local length = 0
	for i=1,n do
		local x, y = curve_point(i / n, x0, y0, x1, y1, x2, y2, x3, y3)
		length = length + line_length(xi, yi, x, y)
		xi, yi = x, y
	end
	return length
end

--intersection point between two line segments.
--based on http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/
function line_line_intersection(x1, y1, x2, y2, x3, y3, x4, y4)
	local ua = (x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)
	local ub = (x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)
	local d  = (y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)
	if d == 0 then return end --the lines are coincident or parallel
	ua = ua / d
	ub = ub / d
	local inside = ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1
	return x1 + ua * (x2 - x1), y1 + ua * (y2 - y1), inside
end

function segment_segment_intersection(x1, y1, x2, y2, x3, y3, x4, y4)
	local x, y, inside = line_line_intersection(x1, y1, x2, y2, x3, y3, x4, y4)
	if not inside then return end
	return x, y
end

function line_curve_intersection(x01, y01, x02, y02, x1, y1, x2, y2, x3, y3, x4, y4)
	--(write, x1, y1, x2, y2, x3, y3, x4, y4)
end

return {
	point_angle = point_angle,
	point_distance = point_distance,
	point_at = point_at,
	rotate_point = rotate_point,
	reflect_point = reflect_point,
	cubic_control_points = cubic_control_points,
	quad_control_points = quad_control_points,
	line_point = line_point,
	line_length = line_length,
	curve_point = curve_point,
	curve_length = curve_length,
	line_line_intersection = line_line_intersection,
	segment_segment_intersection = segment_segment_intersection,
}

