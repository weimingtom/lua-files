--finding the nearest-point on a quad bezier curve using closed form (3rd degree equation) solution.
--solution from http://blog.gludion.com/2009/08/distance-to-quadratic-bezier-curve.html adapted by Cosmin Apreutesei.

local solve_equation3 = require'math_eq3'
local distance2 = require'path_point'.distance2
local bezier2_point = require'path_bezier2'.point

local bezier2_best_hit --forward decl.

--shortest distance-squared from point (x0, y0) to a quad bezier curve, plus the touch point,
--and the parametric value t on the curve where the touch point splits the curve.
local function bezier2_hit(x0, y0, x1, y1, x2, y2, x3, y3)
	local Ax, Ay = x2 - x1, y2 - y1                  --A = P2-P1
	local Bx, By = x3 - x2 - Ax, y3 - y2 - Ay        --B = P3-P2-A, also P3-2*P2+P1
	local Mx, My = x1 - x0, y1 - y0                  --M = P1-P0
	local a = Bx^2 + By^2                            --a = B^2
	local b = 3 * (Ax * Bx + Ay * By)                --b = 3*AxB
	local c = 2 * (Ax^2 + Ay^2) + Mx * Bx + My * By  --c = 2*A^2+MxB
	local d = Mx * Ax + My * Ay                      --d = MxA
	local t1, t2, t3 = solve_equation3(a, b, c, d)   --solve a*t^3 + b*t^2 + c*t + d = 0
	return bezier2_best_hit(x0, y0, x1, y1, x2, y2, x3, y3, t1, t2, t3)
end

function bezier2_best_hit(x0, y0, x1, y1, x2, y2, x3, y3, ...)
	local d, x, y, t = 1/0
	--test all given t's for minimum distance
	for i=1,select('#',...) do
		local pt = select(i,...)
		if pt and pt >= 0 and pt <= 1 then
			local px, py = bezier2_point(pt, x1, y1, x2, y2, x3, y3)
			local pd = distance2(x0, y0, px, py)
			if pd < d then
				d, x, y, t = pd, px, py, pt
			end
		end
	end
	--also test distances to beginning and end of the curve, where t = 0 and 1 respectively.
	local pd = distance2(x0, y0, x1, y1)
	if pd < d then
		d, x, y, t = pd, x1, y1, 0
	end
	local pd = distance2(x0, y0, x3, y3)
	if pd < d then
		d, x, y, t = pd, x3, y3, 1
	end
	if not x then return end
	return d, x, y, t
end

if not ... then require'path_hit_demo' end

return bezier2_hit

