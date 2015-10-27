v1.0 | [code](http://code.google.com/p/lua-files/source/browse/eq2.lua) | [test](http://code.google.com/p/lua-files/source/browse/eq2_test.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local solve_equation2 = require'eq2'` ##
## `solve_equation2(a, b, c[, epsilon]) -> [s1[, s2]]` ##

Solve the [2nd degree equation](http://en.wikipedia.org/wiki/Quadratic_equation) **ax<sup>2</sup> + bx + c** and return all the real solutions.

Epsilon controls the precision at which the solver converges on close enough solutions.


---

**See also:** [eq3](eq3.md).