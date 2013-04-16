--math for 2D elliptic arcs defined as:
--  (center_x, center_y, radius_x, radius_y, start_angle, sweep_angle, [rotation], [x2, y2]).
--angles are expressed in degrees, not radians.
--sweep angle is capped between -360..360deg when drawing but otherwise the time on the arc is relative to the full sweep.
--x2, y2 is an optional override of arc's second end point to use when numerical exactness of the endpoint is required.
--mt is an affine transform that applies to the resulted segments.
--segment_max_sweep is for limiting the arc portion that each bezier segment can cover and is computed automatically.

local reflect_point = require'path_point'.reflect_point
local rotate_point  = require'path_point'.rotate_point
local hypot         = require'path_point'.hypot
local line_to_bezier3 = require'path_line'.to_bezier3
local bezier3_hit = require'path_bezier3_hit'

local abs, min, max, sqrt, ceil, sin, cos, radians =
	math.abs, math.min, math.max, math.sqrt, math.ceil, math.sin, math.cos, math.rad

local angle_epsilon = 1e-10
local max_radii = 1e2

--observed sweep: an arc's sweep can be larger than 360deg but we can only render the first -360..360deg of it.
local function observed_sweep(sweep_angle)
	return max(min(sweep_angle, 360), -360)
end

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

--angle time on an arc (or outside the arc if outside 0..1 range) for a specified angle.
local function sweep_time(hit_angle, start_angle, sweep_angle)
	return sweep_between(start_angle, hit_angle, sweep_angle >= 0) / sweep_angle
end

--check if an angle is inside the sweeped arc.
local function is_sweeped(hit_angle, start_angle, sweep_angle)
	local t = sweep_time(hit_angle, start_angle, sweep_angle)
	return t >= 0 and t <= 1
end

--evaluate ellipse at angle a.
local function point_at(a, cx, cy, rx, ry, rotation, mt)
	rx, ry = abs(rx), abs(ry)
	a = radians(a)
	rotation = rotation or 0
	local x = cx + cos(a) * rx
	local y = cy + sin(a) * ry
	if rotation ~= 0 then
		x, y = rotate_point(x, y, cx, cy, rotation)
	end
	if mt then
		x, y = mt(x, y)
	end
	return x, y
end

--evaluate elliptic arc at time t (the time between 0..1 covers the arc over the sweep interval).
local function point(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	return point_at(start_angle + t * sweep_angle, cx, cy, rx, ry, rotation, mt)
end

--tangent vector on elliptic arc at time t based on http://content.gpwiki.org/index.php/Tangents_To_Circles_And_Ellipses.
--the vector is always oriented towards the sweep of the arc.
local function tangent_vector(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	rx, ry = abs(rx), abs(ry)
	rotation = rotation or 0
	local a = radians(start_angle + t * sweep_angle)
	--px,py is the point at time t on the origin-centered, unrotated ellipse (0, 0, rx, ry, 0).
	local px = cos(a) * rx
	local py = sin(a) * ry
	--tx,ty is the tip point of the tangent vector at angle a, oriented towards the sweep.
	local sign = sweep_angle >= 0 and 1 or -1
	local tx = px + sign * rx * py / ry
	local ty = py - sign * ry * px / rx
	--now rotate, translate to origin, and transform the points as needed.
	if rotation ~= 0 then
		px, py = rotate_point(px, py, 0, 0, rotation)
		tx, ty = rotate_point(tx, ty, 0, 0, rotation)
	end
	px, py = cx + px, cy + py
	tx, ty = cx + tx, cy + ty
	if t == 1 and x2 then
		px, py = x2, y2
	end
	if mt then
		px, py = mt(px, py)
		tx, ty = mt(tx, ty)
	end
	return px, py, tx, ty
end

local function endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	local x1, y1 = point_at(start_angle, cx, cy, rx, ry, rotation, mt)
	if not x2 then
		x2, y2 = point_at(start_angle + observed_sweep(sweep_angle), cx, cy, rx, ry, rotation, mt)
	elseif mt then
		x2, y2 = mt(x2, y2)
	end
	return x1, y1, x2, y2
end

--determine the length of the major axis of a circle of the given radius after applying an affine transformation.
--look at cairo-matrix.c for the math behind it.
local function transformed_circle_major_axis(mt, r)
	if not mt or mt:has_unity_scale() then return r end
	local a, b, c, d = mt:unpack()
	local i = a^2 + b^2
	local j = c^2 + d^2
	local f = (i + j) / 2
	local g = (i - j) / 2
	local h = a*c + b*d
	return r * sqrt(f + hypot(g, h))
end

--this formula is such that enables a non-oscillating segment-time-to-arc-time at screen resolutions (see demo).
function best_segment_max_sweep(mt, rx, ry)
	local scale_factor = transformed_circle_major_axis(mt, max(abs(rx), abs(ry))) / 1024
	scale_factor = max(scale_factor, 0.1) --cap scale factor so that we don't create sweeps larger than 90 deg.
	return sqrt(1/scale_factor^0.6) * 30 --faster way to say 1/2^log10(scale) * 30
end

local function segment(cx, cy, rx, ry, start_angle, sweep_angle)
	local a = radians(sweep_angle / 2)
	local x0 = cos(a)
	local y0 = sin(a)
	local tx = (1 - x0) * 4 / 3
	local ty = y0 - tx * x0 / y0
	local px1 =  x0 + tx
	local py1 = -ty
	local px2 =  x0 + tx
	local py2 =  ty
	local px3 =  x0
	local py3 =  y0
	local a = radians(start_angle + sweep_angle / 2)
	local sn = sin(a)
	local cs = cos(a)
	return
		cx + rx * (px1 * cs - py1 * sn), --c1x
		cy + ry * (px1 * sn + py1 * cs), --c1y
		cx + rx * (px2 * cs - py2 * sn), --c2x
		cy + ry * (px2 * sn + py2 * cs), --c2y
		cx + rx * (px3 * cs - py3 * sn), --p2x
		cy + ry * (px3 * sn + py3 * cs)  --p2y
end

local function to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	if abs(sweep_angle) < angle_epsilon then
		local x1, y1, x2, y2 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		write('curve', select(3, line_to_bezier3(x1, y1, x2, y2)))
	end

	rx, ry = abs(rx), abs(ry)
	sweep_angle = observed_sweep(sweep_angle)
	rotation = rotation or 0
	if not x2 then
		x2, y2 = point_at(start_angle + sweep_angle, cx, cy, rx, ry, rotation, mt)
	elseif mt then
		x2, y2 = mt(x2, y2)
	end
	segment_max_sweep = segment_max_sweep or best_segment_max_sweep(mt, rx, ry)

	local segments = ceil(abs(sweep_angle / segment_max_sweep))
	local segment_sweep = sweep_angle / segments
	local end_angle = start_angle + sweep_angle - segment_sweep / 2

	for angle = start_angle, end_angle, segment_sweep do
		local bx2, by2, bx3, by3, bx4, by4 = segment(cx, cy, rx, ry, angle, segment_sweep)
		if rotation ~= 0 then
			bx2, by2 = rotate_point(bx2, by2, cx, cy, rotation)
			bx3, by3 = rotate_point(bx3, by3, cx, cy, rotation)
			bx4, by4 = rotate_point(bx4, by4, cx, cy, rotation)
		end
		if mt then
			bx2, by2 = mt(bx2, by2)
			bx3, by3 = mt(bx3, by3)
			bx4, by4 = mt(bx4, by4)
		end
		if abs(end_angle - angle) < abs(segment_sweep) then --last segment: override endpoint with the specified one
			bx4, by4 = x2, y2
		end
		write('curve', bx2, by2, bx3, by3, bx4, by4)
	end
end

--given the time t on the i'th arc segment of an arc, return the corresponding arc time.
--we assume that time found on the bezier segment approximates well the time on the arc segment.
--the assumption is only accurate if the arc is composed of enough segments, given arc's transformed size.
local function segment_time_to_arc_time(i, t, sweep_angle, segment_max_sweep)
	local sweep_angle = abs(observed_sweep(sweep_angle))
	if sweep_angle < angle_epsilon then
		return t
	end
	local segments = ceil(sweep_angle / segment_max_sweep)
	return (i-1+t) / segments
end

--arc hit under affine transform: we construct the arc from a number of bezier segments, hit those and then
--compute the arc time from segment time. segment_max_sweep must be small enough given arc's size.
local function hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	local i = 0 --segment count
	local mind, minx, miny, mint, mini
	local x1, y1 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
	local function write(s, ...)
		i = i + 1
		local d, x, y, t = bezier3_hit(x0, y0, x1, y1, ...)
		x1, y1 = select(5, ...)
		if not mind or d < mind then
			mind, minx, miny, mint, mini = d, x, y, t, i
		end
	end
	segment_max_sweep = segment_max_sweep or best_segment_max_sweep(mt, rx, ry)
	to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, segment_max_sweep)
	mint = segment_time_to_arc_time(mini, mint, sweep_angle, segment_max_sweep)
	return mind, minx, miny, mint
end

local function split(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	t = min(max(t,0),1)
	local sweep1 = t * sweep_angle
	local sweep2 = sweep_angle - sweep1
	local split_angle = start_angle + sweep1
	return
		cx, cy, rx, ry, start_angle, sweep1, rotation,        --first arc
		cx, cy, rx, ry, split_angle, sweep2, rotation, x2, y2 --second arc
end

--from http://www.w3.org/TR/SVG/implnote.html#ArcConversionCenterToEndpoint
local function to_svgarc(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	local x1, y1, x2, y2 = endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	local large = abs(sweep_angle) > 180 and 1 or 0
	local sweep = sweep_angle >= 0 and 1 or 0
	return x1, y1, rx, ry, rotation, large, sweep, x2, y2
end

if not ... then require'path_elliptic_arc_demo' end

return {
	observed_sweep = observed_sweep,
	sweep_between = sweep_between,
	sweep_time = sweep_time,
	is_sweeped = is_sweeped,
	endpoints = endpoints,
	to_svgarc = to_svgarc,
	best_segment_max_sweep = best_segment_max_sweep,
	point_at = point_at,
	tangent_vector = tangent_vector,
	--path API
	to_bezier3 = to_bezier3,
	point = point,
	hit = hit,
	split = split,
}

