--3rd degree equation solver using the trigonometric method, see http://en.wikipedia.org/wiki/Cubic_function.
--epsilon controls the precision of the solver.
--TODO: review this code for catastrophic cancelations and alike.

local solve_equation2 = require'math_eq2'

local abs, sqrt, acos, cos, pi = math.abs, math.sqrt, math.acos, math.cos, math.pi

local function solve_equation3(a, b, c, d, epsilon)
	epsilon = epsilon or 1e-16
	if abs(a) < epsilon then --2nd degree
		return solve_equation2(b, c, d)
	end
	local z = a
	a = b / z
	b = c / z
	c = d / z
	local p = b - a^2 / 3
	local q = a * (2 * a^2 - 9 * b) / 27 + c
	local p3 = p^3
	local D = q^2 + 4 * p3 / 27
	local offset = -a / 3
	if D > epsilon then
		z = sqrt(D)
		local u = ( -q + z) / 2
		local v = ( -q - z) / 2
		u = u >= 0 and u^(1 / 3) or -((-u)^(1 / 3))
		v = v >= 0 and v^(1 / 3) or -((-v)^(1 / 3))
		return
			u + v + offset
	elseif D < -epsilon then
		local u = 2 * sqrt( -p / 3)
		local v = acos( -sqrt( -27 / p3) * q / 2) / 3
		return
			u * cos(v) + offset,
			u * cos(v + 2 * pi / 3) + offset,
			u * cos(v + 4 * pi / 3) + offset
	else --D == 0
		local u = q < 0 and (-q / 2)^(1 / 3) or -((q / 2)^(1 / 3))
		if abs(u) < epsilon then
			return offset
		end
		return
			2*u + offset,
			-u + offset
	end
end

if not ... then require'math_eq3_test' end

return solve_equation3

