--finding the nearest-point on a cubic curve, adapted from Graphics Gems (NearestPoint.c) by Cosmin Apreutesei.

local glue = require'glue'
local distance2 = require'path_point'.distance2
local bezier3_point = require'path_bezier3'.point
local bezier3_split = require'path_bezier3'.split

local min, max = math.min, math.max

local curve_recursion_limit = 64
local curve_flatness_epsilon = 1*2^(-curve_recursion_limit-1)

--forward decl.
local ConvertToBezierForm
local FindRoots
local CrossingCount
local ControlPolygonFlatEnough
local ComputeXIntercept
local Bezier

--split a 5th degree bezier at time t = 0.5 into two curves using De Casteljau interpolation (30 muls).
local function bezier5_split_in_half(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6)
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

local function vec_scale(s, vx, vy) --scale vector by a factor
	return vx * s, vy * s
end

local function bezier3_hit(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)
	-- Convert problem to 5th-degree Bezier form
	local ax1, ay1, ax2, ay2, ax3, ay3, ax4, ay4, ax5, ay5, ax6, ay6 =
		ConvertToBezierForm(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)

	-- Find all possible roots of 5th-degree equation
	local roots = FindRoots(ax1, ay1, ax2, ay2, ax3, ay3, ax4, ay4, ax5, ay5, ax6, ay6, 0) --possible roots, up to 5

	-- Compare distances of P to all candidates, and to t=0, and t=1
	-- Check distance to beginning of curve, where t = 0
	local dist = distance2(x0, y0, x1, y1)
	local t = 0

	-- Find distances for candidate points
	for i=1,#roots do
		local px, py = bezier3_point(roots[i], x1, y1, x2, y2, x3, y3, x4, y4)
		local new_dist = distance2(x0, y0, px, py)
		if new_dist < dist then
			dist = new_dist
			t = roots[i]
		end
	end

	-- Finally, look at distance to end point, where t = 1.0
	local new_dist = distance2(x0, y0, x4, y4)
	if new_dist < dist then
		dist = new_dist
		t = 1
	end

	-- Return the polocal on the curve at parameter value t
	local x, y = bezier3_point(t, x1, y1, x2, y2, x3, y3, x4, y4)
	return distance2(x, y, x0, y0), x, y, t
end


--	Given a polocal (x0,y0) and a Bezier curve, generate a 5th-degree Bezier-format equation whose solution
-- finds the polocal on the curve nearest the user-defined point.
local cubic_z = { -- Precomputed "z" for cubics
	{1.0, 0.6, 0.3, 0.1},
	{0.4, 0.6, 0.6, 0.4},
	{0.1, 0.3, 0.6, 1.0},
}
local function dot_product(ax, ay, bx, by) --the dot product of two vectors
	return ax * bx + ay * by
end
function ConvertToBezierForm(x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)
	-- V(i)'s - P: these are vectors created by subtracting polocal (x0,y0) from each of the control points.
	local c = {
		{x1 - x0, y1 - y0},
		{x2 - x0, y2 - y0},
		{x3 - x0, y3 - y0},
		{x4 - x0, y4 - y0},
	}
	-- V(i+1) - V(i): these are vectors created by subtracting each control polocal from the next.
	local d = {
		{vec_scale(3.0, x2 - x1, y2 - y1)},
		{vec_scale(3.0, x3 - x2, y3 - y2)},
		{vec_scale(3.0, x4 - x3, y4 - y3)},
	}
	-- create the c,d table -- this is a table of dot products of the c's and d's.
	local cdTable = {{}, {}, {}}	--dot product c x d
	for row=1,3 do
		for column=1,4 do
			cdTable[row][column] = dot_product(d[row][1], d[row][2], c[column][1], c[column][2])
		end
	end

	-- now, apply the z's to the dot products, on the skew diagonal.
	-- Also, set up the x-values, making these "points".
	local w = {} -- the 6 control points of 5th-degree curve
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

-- given a 5th-degree equation in Bernstein-Bezier form, find all of the roots in the interval [0, 1].
function FindRoots(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6, depth)
	local switch = CrossingCount(y1, y2, y3, y4, y5, y6)
	if switch == 0 then -- No solutions here
		return {}
	elseif switch == 1 then -- Unique solution
		-- stop recursion when the tree is deep enough and return the one solution at midpoint
		if depth >= curve_recursion_limit then
			return { (x1 + x6) / 2 }
		end
		if ControlPolygonFlatEnough(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6) then
			return { ComputeXIntercept(x1, y1, x6, y6) }
		end
	end

	-- otherwise, solve recursively after subdividing control polygon
	local x1, y1, x12, y12, x123, y123, x1234, y1234, x12345, y12345, x123456, y123456,
			x123456, y123456, x23456, y23456, x3456, y3456, x456, y456, x56, y56, x6, y6 =
						bezier5_split_in_half(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6)
	local left_roots  = FindRoots(x1, y1, x12, y12, x123, y123, x1234, y1234, x12345, y12345, x123456, y123456, depth+1)
	local right_roots = FindRoots(x123456, y123456, x23456, y23456, x3456, y3456, x456, y456, x56, y56, x6, y6, depth+1)

	-- gather solutions together
	local t = {}
	glue.extend(t, left_roots)
	glue.extend(t, right_roots)
	return t
end

local function SGN(x) return x >= 0 and 1 or -1 end
local function SD(x,y) return SGN(x) ~= SGN(y) and 1 or 0 end

--	count the number of times a Bezier control polygon crosses the 0-axis. This number is >= the number of roots.
function CrossingCount(y1, y2, y3, y4, y5, y6)
	return SD(y1, y2) + SD(y2, y3) + SD(y3, y4) + SD(y4, y5) + SD(y5, y6)
end

--	check if the control polygon of a Bezier curve is flat enough for recursive subdivision to bottom out.
function ControlPolygonFlatEnough(x1, y1, x2, y2, x3, y3, x4, y4, x5, y5, x6, y6)
	local V = {[0] = {x=x1, y=y1}, {x=x2, y=y2}, {x=x3, y=y3}, {x=x4, y=y4}, {x=x5, y=y5}, {x=x6, y=y6}}

	-- Coefficients of implicit equation for line from V[0]-V[deg]
	-- Derive the implicit equation for line connecting first and last control points
	local a = y1 - y6
	local b = x6 - x1
	local c = x1 * y6 - x6 * y1

	local max_distance_below = 0
	local max_distance_above = 0

	for i=1,5-1 do
	  local value = a * V[i].x + b * V[i].y + c

	  if value > max_distance_above then
			max_distance_above = value
	  elseif value < max_distance_below then
			max_distance_below = value
		end
	end

	-- Implicit equation for zero line
	local a1 = 0.0
	local b1 = 1.0
	local c1 = 0.0
	-- Implicit equation for "above" line
	local a2 = a
	local b2 = b
	local c2 = c - max_distance_above
	local det = a1 * b2 - a2 * b1
	local intercept1 = (b1 * c2 - b2 * c1) * (1 / det)
	-- Implicit equation for "below" line
	local a2 = a
	local b2 = b
	local c2 = c - max_distance_below
	local det = a1 * b2 - a2 * b1
	local intercept2 = (b1 * c2 - b2 * c1) * (1 / det)

	-- Compute intercepts of bounding box
	local left_intercept  = min(intercept1, intercept2)
	local right_intercept = max(intercept1, intercept2)

	local err = right_intercept - left_intercept

	return err < curve_flatness_epsilon
end

--	compute intersection of chord from first control polocal to last with 0-axis.
function ComputeXIntercept(x1, y1, x6, y6)
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


if not ... then

local d,x,y,t = bezier3_hit(3.5, 2.0, 0, 0, 1, 2, 3, 3, 4, 2)
print(string.format("point on curve: %f (%f, %f)\n", t, x, y))

local function assertf(x,y) assert(math.abs(x-y) < 0.0000001, x..' ~= '..y) end
assertf(t, 0.886311733891)
assertf(x, 3.623099)
assertf(y, 2.264984)

print(bezier3_hit(-30.5, 50.0, 0.1, 0.1, 1, 2, 3, 3, 4, 2))
end

return bezier3_hit

