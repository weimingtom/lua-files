--finding the nearest-point on a cubic bezier curve.
--solution from Graphics Gems (NearestPoint.c) adapted by Cosmin Apreutesei.

local distance2 = require'path_point'.distance2
local bezier3_point = require'path_bezier3'.point

local min, max = math.min, math.max

local curve_recursion_limit = 64
local curve_flatness_epsilon = 1*2^(-curve_recursion_limit-1)

--forward decl.
local bezier3_to_bezier5
local bezier5_roots
local bezier5_crossing_count
local bezier5_flat_enough
local bezier5_split_in_half

--shortest distance-squared from point (x0, y0) to a cubic bezier curve, plus the touch point,
--and the parametric value t on the curve where the touch point splits the curve.
local function bezier3_hit(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)
	--convert problem to 5th-degree Bezier form
	local ax1, ay1, ax2, ay2, ax3, ay3, ax4, ay4, ax5, ay5, ax6, ay6 =
		bezier3_to_bezier5(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)

	local d, x, y, t = 1/0 --shortest distance, touch point, and the parametric value for the touch point.

	--find all roots in [0, 1] interval for the 5th-degree equation and see which has the shortest distance.
	local function write(root)
		local px, py = bezier3_point(root, x1, y1, x2, y2, x3, y3, x4, y4)
		local pd = distance2(x0, y0, px, py)
		if pd < d then
			d, x, y, t = pd, px, py, root
		end
	end
	bezier5_roots(write, ax1, ay1, ax2, ay2, ax3, ay3, ax4, ay4, ax5, ay5, ax6, ay6, 0)

	--also test distances to beginning and end of the curve, where t = 0 and 1 respectively.
	local pd = distance2(x0, y0, x1, y1)
	if pd < d then
		d, x, y, t = pd, x1, y1, 0
	end
	local pd = distance2(x0, y0, x4, y4)
	if pd < d then
		d, x, y, t = pd, x4, y4, 1
	end

	return d, x, y, t
end

--given a polocal (x0,y0) and a Bezier curve, generate a 5th-degree Bezier-format equation whose solution
--finds the polocal on the curve nearest the user-defined point.
local cubic_z = { -- Precomputed "z" for cubics
	{1.0, 0.6, 0.3, 0.1},
	{0.4, 0.6, 0.6, 0.4},
	{0.1, 0.3, 0.6, 1.0},
}
local function dot_product(ax, ay, bx, by) --the dot product of two vectors
	return ax * bx + ay * by
end
function bezier3_to_bezier5(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)
	--c's are vectors created by subtracting the polocal (x0,y0) from each of the control points.
	local c = {
		{x1 - x0, y1 - y0},
		{x2 - x0, y2 - y0},
		{x3 - x0, y3 - y0},
		{x4 - x0, y4 - y0},
	}
	--d's are vectors created by subtracting each control polocal from the next and then scaling by 3.
	local d = {
		{3 * (x2 - x1), 3 * (y2 - y1)},
		{3 * (x3 - x2), 3 * (y3 - y2)},
		{3 * (x4 - x3), 3 * (y4 - y3)},
	}
	--create the c x d table: this is a table of dot products of the c's and d's.
	local cdTable = {{}, {}, {}}
	for row=1,3 do
		for column=1,4 do
			cdTable[row][column] = dot_product(d[row][1], d[row][2], c[column][1], c[column][2])
		end
	end

	--now, apply the z's to the dot products, on the skew diagonal and set up the x-values, making these "points".
	local w = {}
	for i=0,5 do
		w[i] = {y=0, x = i/5}
	end

	local n = 3
	local m = 3-1
	for k=0,n+m do
		local lb = max(0, k - m)
		local ub = min(k, n)
		for i=lb,ub do
			local j = k - i
			w[i+j].y = w[i+j].y + cdTable[j+1][i+1] * cubic_z[j+1][i+1]
		end
	end
	return w[0].x, w[0].y, w[1].x, w[1].y, w[2].x, w[2].y, w[3].x, w[3].y, w[4].x, w[4].y, w[5].x, w[5].y
end

--given a 5th-degree equation in Bernstein-Bezier form, find and write all roots in the interval [0, 1].
function bezier5_roots(write, x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6, depth)
	local switch = bezier5_crossing_count(y1, y2, y3, y4, y5, y6)
	if switch == 0 then --no solutions here
		return {}
	elseif switch == 1 then --unique solution
		--stop the recursion when the tree is deep enough and write the one solution at midpoint
		if depth >= curve_recursion_limit then
			write((x1 + x6) / 2)
			return
		end
		--stop the recursion when the curve is flat enough and write the solution at x-intercept
		if bezier5_flat_enough(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6) then
			write(bezier5_xintercept(x1, y1, x6, y6))
			return
		end
	end
	--otherwise, solve recursively after subdividing the control polygon
	local x1, y1, x12, y12, x123, y123, x1234, y1234, x12345, y12345, x123456, y123456,
			x123456, y123456, x23456, y23456, x3456, y3456, x456, y456, x56, y56, x6, y6 =
						bezier5_split_in_half(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6)
	bezier5_roots(write, x1, y1, x12, y12, x123, y123, x1234, y1234, x12345, y12345, x123456, y123456, depth+1)
	bezier5_roots(write, x123456, y123456, x23456, y23456, x3456, y3456, x456, y456, x56, y56, x6, y6, depth+1)
end

--split a 5th degree bezier at time t = 0.5 into two curves using De Casteljau interpolation (30 muls).
function bezier5_split_in_half(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6)
	local x12 = (x1 + x2) / 2
	local y12 = (y1 + y2) / 2
	local x23 = (x2 + x3) / 2
	local y23 = (y2 + y3) / 2
	local x34 = (x3 + x4) / 2
	local y34 = (y3 + y4) / 2
	local x45 = (x4 + x5) / 2
	local y45 = (y4 + y5) / 2
	local x56 = (x5 + x6) / 2
	local y56 = (y5 + y6) / 2
	local x123 = (x12 + x23) / 2
	local y123 = (y12 + y23) / 2
	local x234 = (x23 + x34) / 2
	local y234 = (y23 + y34) / 2
	local x345 = (x34 + x45) / 2
	local y345 = (y34 + y45) / 2
	local x456 = (x45 + x56) / 2
	local y456 = (y45 + y56) / 2
	local x1234 = (x123 + x234) / 2
	local y1234 = (y123 + y234) / 2
	local x2345 = (x234 + x345) / 2
	local y2345 = (y234 + y345) / 2
	local x3456 = (x345 + x456) / 2
	local y3456 = (y345 + y456) / 2
	local x12345 = (x1234 + x2345) / 2
	local y12345 = (y1234 + y2345) / 2
	local x23456 = (x2345 + x3456) / 2
	local y23456 = (y2345 + y3456) / 2
	local x123456 = (x12345 + x23456) / 2
	local y123456 = (y12345 + y23456) / 2
	return
		x1, y1, x12, y12, x123, y123, x1234, y1234, x12345, y12345, x123456, y123456, --first curve
		x123456, y123456, x23456, y23456, x3456, y3456, x456, y456, x56, y56, x6, y6  --second curve
end

--count the number of times a Bezier control polygon crosses the 0-axis, in other words, the number of times
--that the sign changes between consecutive y's. This number is >= the number of roots.
function bezier5_crossing_count(y1, y2, y3, y4, y5, y6)
	return
		((y1 < 0) ~= (y2 < 0) and 1 or 0) +
		((y2 < 0) ~= (y3 < 0) and 1 or 0) +
		((y3 < 0) ~= (y4 < 0) and 1 or 0) +
		((y4 < 0) ~= (y5 < 0) and 1 or 0) +
		((y5 < 0) ~= (y6 < 0) and 1 or 0)
end

--check if the control polygon of a Bezier curve is flat enough for recursive subdivision to bottom out.
function bezier5_flat_enough(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6)
	--coefficients of implicit equation for line from (x1,y1)-(x6,y6).
	--derive the implicit equation for line connecting first and last control points.
	local a = y1 - y6
	local b = x6 - x1
	local c = x1 * y6 - x6 * y1

	local max_distance_below = min(0,
		a * x2 + b * y2 + c,
		a * x3 + b * y3 + c,
		a * x4 + b * y4 + c,
		a * x5 + b * y5 + c)

	local max_distance_above = max(0,
		a * x2 + b * y2 + c,
		a * x3 + b * y3 + c,
		a * x4 + b * y4 + c,
		a * x5 + b * y5 + c)

	--implicit equation for the zero line.
	local a1 = 0.0
	local b1 = 1.0
	local c1 = 0.0

	--implicit equation for the "above" line.
	local a2 = a
	local b2 = b
	local c2 = c - max_distance_above
	local det = a1 * b2 - a2 * b1
	local intercept1 = (b1 * c2 - b2 * c1) * (1 / det)

	--implicit equation for the "below" line.
	local a2 = a
	local b2 = b
	local c2 = c - max_distance_below
	local det = a1 * b2 - a2 * b1
	local intercept2 = (b1 * c2 - b2 * c1) * (1 / det)

	--intercepts of the bounding box.
	local left_intercept  = min(intercept1, intercept2)
	local right_intercept = max(intercept1, intercept2)

	local error = right_intercept - left_intercept
	return error < curve_flatness_epsilon
end

--compute intersection of chord from first control polocal to last with 0-axis.
function bezier5_xintercept(x1, y1, x6, y6)
	local XLK = 1.0
	local YLK = 0.0
	local XNM = x6 - x1
	local YNM = y6 - y1
	local XMK = x1
	local YMK = y1
	local det = XNM * YLK - YNM * XLK
	local S = (XNM * YMK - YNM * XMK) * (1 / det)
	local X = 0.0 + XLK * S
	return X
end

if not ... then require'path_bezier3_hit_test' end

return bezier3_hit

