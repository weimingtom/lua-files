3-point arcs

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/path_arc_3p.lua) | [demo](http://code.google.com/p/lua-files/source/browse/path_arc_3p_demo.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local arc_3p = require'path_arc_3p'`

Math for 2D 3-point circular arcs defined as:
  `x1, y1, xp, yp, x2, y2`

where `(x1, y1)`, `(xp, yp)` and `(x2, y2)` are the arc's endpoints

### `arc_3p.to_arc(x1, y1, xp, yp, x2, y2) -> cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2`

Convert a 3-point arc an [path_arc elliptic arc].

If the endpoints conicide are collinear then the parametrization is invalid and nothing is returned.

### `arc_3p.split(t, x1, y1, xp, yp, x2, y2) -> `
  ### `x11, y11, x1p, y1p, x22, y22`
  ### `x21, y21, x2p, y2p, x22, y22`

Split a 3-point arc at time `t` into two arcs.

*See also:* [path_arc].
