v1.0 | [code](http://code.google.com/p/lua-files/source/browse/path_point.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local point = require'path_point'` ##

Basic math functions for the cartesian plane. Angles are expressed in degrees, not radians.

| `point.hypot(a, b) -> c` | hypotenuse function: computes `sqrt(a^2 + b^2)` without underflow / overflow problems. |
|:-------------------------|:---------------------------------------------------------------------------------------|
| `point.distance(x1, y1, x2, y2) -> d` | distance between two points.                                                           |
| `point.distance2(x1, y1, x2, y2) -> d2` | distance between two points squared.                                                   |
| `point.point_around(cx, cy, r, angle) -> x, y` | point at a specified angle on a circle.                                                |
| `point.rotate_point(x, y, cx, cy, angle) -> x, y` | rotate point (x,y) around origin (cx,cy) by angle.                                     |
| `point.point_angle(x, y, cx, cy) -> angle` | angle between two points in -360..360 degree range.                                    |
| `point.reflect_point(x, y, cx, cy) -> x, y` | reflect point through origin (i.e. rotate point 180deg around another point).          |
| `point.reflect_point_distance(x, y, cx, cy, length) -> x, y` | reflect point through origin at a specified distance.                                  |