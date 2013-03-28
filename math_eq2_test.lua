local solve_equation2 = require'math_eq2'

local pformat = require'pp'.pformat
local function assert_approx(a,b)
	print(string.format("approximation error:\t%g",math.abs(a-b)))
	assert(math.abs(a-b) <= 1e-30, a..' ~= '..b)
end
local function assert_sol(a, b, c, s1, s2)
	local t = {solve_equation2(a, b, c)}
	local s = {s1, s2}
	assert(#t == #s, pformat(t))
	table.sort(t)
	table.sort(s)
	for i=1,#t do
		assert_approx(t[i],s[i])
	end
end

assert_sol(0, 0, 1       )   --degree 1, c ~= 0
assert_sol(0, 1, -2,    2)   --degree 1, -c/b
assert_sol(1, -1, 2      )   --D < 0
assert_sol(1, 2, 1,    -1)   --D > 0
assert_sol(2, 2, 0, -1, 0)   --D == 0

