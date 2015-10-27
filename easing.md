v1.0 | [code](http://code.google.com/p/lua-files/source/browse/easing.lua) | [demo](http://code.google.com/p/lua-files/source/browse/easing_demo.lua) | Lua 5.1, Lua 5.2, LuaJIT 2

## `local easing = require'easing'` ##

Robert Penner's [easing functions](http://www.robertpenner.com/easing/).

### API ###

#### `easing.<formula>(current_time - start_time, 0, 1, fixed_duration) -> value in 0..1` ####

The formulas map input `d` to output `r`, where `d` is in `0 .. t` and `r` is in `b + 0 .. c`.

Some formulas take additional parameters (see code).