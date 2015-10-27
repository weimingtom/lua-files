v1.0 | [code](http://code.google.com/p/lua-files/source/browse/eq3.lua) | [test](http://code.google.com/p/lua-files/source/browse/eq3_test.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local solve_equation3 = require'eq3'` ##
## `solve_equation3(a, b, c, d[, epsilon]) -> [s1[, s2[, s3]]]` ##

Solve the [3rd degree equation](http://en.wikipedia.org/wiki/Cubic_function) **ax<sup>3</sup> + bx<sup>2</sup> + cx + d** and return all the real solutions.

Epsilon controls the precision at which the solver converges on close enough solutions.


---

**See also:** [eq2](eq2.md).