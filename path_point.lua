--basic math for the cartesian plane.

local sqrt, abs, min, max, sin, cos, atan2 =
	math.sqrt, math.abs, math.min, math.max, math.sin, math.cos, math.atan2

local function hypot(a, b)
	if a == 0 and a == 0 then return 0 end
	a, b = abs(a), abs(b)
	a, b = max(a,b), min(a,b)
	return a * sqrt(1 + (b / a)^2)
end

--distance between two points. avoids underflow and overflow.
local function distance(x1, y1, x2, y2)
	return hypot(x2-x1, y2-y1)
end

--distance between two points squared.
local function distance2(x1, y1, x2, y2)
	return (x2-x1)^2 + (y2-y1)^2
end

--point at a specified angle on a circle.
local function point_around(cx, cy, r, angle)
	return
		cx + cos(angle) * r,
		cy + sin(angle) * r
end

--angle between two points in -pi..pi range.
local function point_angle(x, y, cx, cy)
	return atan2(y - cy, x - cx)
end

--reflect point through origin (i.e. rotate point 180deg around another point).
local function reflect_point(x, y, cx, cy)
	return 2 * cx - x, 2 * cy - y
end

--reflect point through origin at a specified distance.
local function reflect_point_distance(x, y, cx, cy, length)
	local d = distance(x, y, cx, cy)
	if d == 0 then return cx, cy end
	local scale = length / d
	return
		cx + (cx - x) * scale,
		cy + (cy - y) * scale
end

return {
	hypot = hypot,
	distance = distance,
	distance2 = distance2,
	point_around = point_around,
	point_angle = point_angle,
	reflect_point = reflect_point,
	reflect_point_distance = reflect_point_distance,
}
