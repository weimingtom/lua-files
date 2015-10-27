v1.0 | [code](http://code.google.com/p/lua-files/source/browse/path_line.lua) | [demo](http://code.google.com/p/lua-files/source/browse/path_hit_demo.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local line = require'path_line'` ##

Math for 2D line segments defined as
> `x1, y1, x2, y2`
where `(x1, y1)` and `(x2, y2)` are the endpoints.

| `line.point(t, x1, y1, x2, y2) -> x, y` | evaluate a line at time t using linear interpolation. The time between 0..1 covers the segment interval. |
|:----------------------------------------|:---------------------------------------------------------------------------------------------------------|
| `line.length(t, x1, y1, x2, y2) -> length` | length of line at time t.                                                                                |
| `line.bounding_box(x1, y1, x2, y2) -> left, top, width, height` | bounding box of line segment.                                                                            |
| `line.split(t, x1, y1, x2, y2) -> ax1, ay1, ax2, ay2, bx1, by1, bx2, by2` | split line segment into two line segments at time t. t is capped between 0..1.                           |
| `line.point_line_intersection(x, y, x1, y1, x2, y2) -> x, y` | intersect an infinite line with its perpendicular from point (x, y). Return the intersection point.      |
| `line.hit(x0, y0, x1, y1, x2, y2) -> d2, x, y, t` | return the shortest distance-squared from point (x0, y0) to line, plus the touch point, and the time in the line where the touch point splits the line. |
| `line.line_line_intersection(x1, y1, x2, y2, x3, y3, x4, y4) -> x1, y1` | intersect line segment `(x1, y1, x2, y2)` with line segment `(x3, y3, x4, y4)`. Return the time on the first line and the time on the second line where intersection occurs. <br> If the intersection occurs outside the segments themselves, then t1 and t2 are outside the 0..1 range. If the lines are parallel or coincident then t1 and t2 are infinite. <br>
<tr><td> <code>line.to_bezier2(x1, y1, x2, y2) -&gt; x1, y1, x2, y2, x3, y3</code> </td><td> return a quadratic bezier that approximates a line segment and also advances linearly i.e. the point on the line at t best matches the point on the curve at t. </td></tr>
<tr><td> <code>line.to_bezier3(x1, y1, x2, y2) -&gt; x1, y1, x2, y2, x3, y3, x4, y4</code> </td><td> return a cubic bezier that approximates a line segment and also advances linearly i.e. the point on the line at t best matches the point on the curve at t. </td></tr>