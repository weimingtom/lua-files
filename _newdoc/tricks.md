Lua tricks and idioms

### Quick Lua cheat sheet

                                                                           *logic*
                                                                           `not a == not b`                                                                            both or none
                                                                           *numbers*
                                                                           math.min(math.max(x, min), max)                                                                            clamp x
                                                                           `x ~= x`                                                                              number is NaN
                                                                           `1/0`                                                                                 inf
                                                                           `-1/0`                                                                                -inf
                                                                           `math.huge == math.huge-1`                                                                            check if inf is available (Lua numbers are floats) without dividing by zero
                                                                           `x % 1`                                                                                 fractional part (always positive)
                                                                           `x % 1 ##  0`                                                                            number is integer; but better use `math.floor(x)  x`
                                                                           `x - x % 1`                                                                               integer part; but better use `math.floor(x)`
                                                                           `x - x % 0.01`                                                                            x floored to two decimal digits
                                                                           `x - x % n`                                                                            closest to `x` smaller than `x` multiple of `n`
                                                                           `math.modf(x)`                                                                            integer part and fractional part
                                                                           `math.floor(x+.5)`                                                                            round
                                                                           `x >= 0 and 1 or -1`                                                                            sign
                                                                           `y0 + (x-x0) * ((y1-y0) / (x1 - x0))`                                                                            linear interpolation
                                                                           `math.fmod(angle, 2*math.pi)`                                                                            normalize an angle
                                                                           *tables*
                                                                           `next(t) == nil`                                                                            table is empty
                                                                           *strings*
                                                                           `s:match'^something'`                                                                            starts with
                                                                           `s:match'something$'`                                                                            ends with
                                                                           `s:match'["\'](.-)%1'`                                                                            match pairs of single or double quotes
                                                                           *i/o*
                                                                           `f:read(4096, '*l')`                                                                            read lines efficiently

### LuaJIT tricks

Pointer to number conversion that turns into a no-op when compiled:
~~~{.lua}
tonumber(ffi.cast('intptr_t', ffi.cast('void *', ptr)))
~~~

Switching endianness of a 64bit integer (to use in conjunction with `ffi.abi'le'` and `ffi.abi'be'`):
~~~{.lua}
local p = ffi.cast('uint32*', int64_buffer)
p[0], p[1] = bit.bswap(p[1]), bit.bswap(p[0])
~~~

### Assumptions about LuaJIT

  * LuaJIT hoists table accesses with constant keys (so module functions) out of loops, so no point caching those in locals.
  * LuaJIT hoists constant branches out of loops so it's ok to specialize loop kernels with if/else or and/or inside the loops.
  * LuaJIT inlines functions (except when using `...` and `select()` with non-constant indices), so specializing loop kernels with function composition is ok.
  * multiplications and additions can be cheaper than a memory access, so no point caching results in out-of-loop locals.
  * there's no difference between using if/else and using and/or expressions - they generate the same pipeline-trashing branch code.
  * divisions are 4x slower than multiplications, so when dividing by a constant, it helps turning `x / c` into `x * (1 / c)` since the constant expression is folded -- LuaJIT seems to do this already for power-of-2 constants where the semantics are equivalent (are they? need reference).
  * the `%` operator is slow (it's implemented in terms of `math.floor()` and division) and really kills hot loops; `math.fmod()` is even slower; I don't have a solution for this (except for `x % 2^n` which can be made with bit ops).

The above are assumptions I use throughout my code, so if any of them are wrong, please correct me.

----
*See also*: [APIDesign API Design Notes].
