--2nd degree equation solver, see http://en.wikipedia.org/wiki/Quadratic_equation#Floating-point_implementation.
--epsilon controls the precision of the solver.

local abs, sqrt = math.abs, math.sqrt

local function solve_equation2(a, b, c, epsilon)
	epsilon = epsilon or 1e-30
	if abs(a) < epsilon then
		if abs(b) < epsilon then return end --contradiction
		return -c / b --1st degree
	end
	local D = b^2 - 4*a*c --discriminant
	if D > epsilon then --D > 0, real root
		local q = -1/2 * (b + (b >= 0 and 1 or -1) * sqrt(D))
		return
			q / a,
			c / q
	elseif D < -epsilon then --D < 0, complex root
		return
	else --D == 0, double root
		return -b / (2 * a)
	end
end

if not ... then require'math_eq2_test' end

return solve_equation2
