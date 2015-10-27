v1.0 | [code](http://code.google.com/p/lua-files/source/browse/box2d.lua) | Lua 5.1, Lua 5.2, LuaJIT 2

## `local box = require'box2d'` ##

Math for 2D rectangles defined as `(x, y, w, h)`.

### API ###

| **representation forms** | |
|:-------------------------|:|
| `box.corners(x, y, w, h) -> x1, y1, x2, y2` | left,top and right,bottom corners |
| `box.rect(x1, y1, x2, y2) -> x, y, w, h` | box given left,top and right,bottom corners |
| **layouting**            | |
| `box.align(w, h, halign, valign, bx, by, bw, bh) -> x, y, w, h` | align a box in another box |
| `box.vsplit(i, sh, x, y, w, h) -> x, y, w, h` | slice a box horizontally at a certain height and return the i'th box. <br> if sh is negative, slicing is done from the bottom side. <br>
<tr><td> <code>box.hsplit(i, sw, x, y, w, h) -&gt; x, y, w, h</code> </td><td> slice a box vertically at a certain width and return the i'th box. <br> if sw is negative, slicing is done from the right side. </td></tr>
<tr><td> <code>box.nsplit(i, n, direction, x, y, w, h) -&gt; x, y, w, h</code> </td><td> slice a box in n equal slices, vertically or horizontally, and return the i'th box. <br> direction = 'v' or 'h' </td></tr>
<tr><td> <code>box.translate(x0, y0, x, y, w, h) -&gt; x, y, w, h</code> </td><td> move a box </td></tr>
<tr><td> <code>box.offset(d, x, y, w, h) -&gt; x, y, w, h</code> </td><td> offset a box by d, outward if d is positive </td></tr>
<tr><td> <code>box.fit(w, h, bw, bh) -&gt; w, h</code> </td><td> fit a box into another box preserving aspect ratio. use align() to position the box </td></tr>
<tr><td> <b>hit testing</b>       </td><td> </td></tr>
<tr><td> <code>box.hit(x0, y0, x, y, w, h) -&gt; true | false</code> </td><td> check if a point (x0, y0) is inside rect (x, y, w, h) </td></tr>
<tr><td> <code>box.hit_margins(x0, y0, d, x, y, w, h)</code> <br> <code>-&gt; hit, left, top, right, bottom</code> </td><td> hit test for margins and corners </td></tr>
<tr><td> <b>edge snapping</b>     </td><td> </td></tr>
<tr><td> <code>box.snap_margins(d, x, y, w, h, rectangles) -&gt; x, y, w, h</code> </td><td> snap the sides of a rectangle against an iterator of rectangles. <br> <code>rectangles = function() -&gt; x, y, w, h | nil</code> </td></tr>
<tr><td> <code>box.snap_pos(d, x, y, w, h, rectangles) -&gt; x, y, w, h</code> </td><td> snap the position of a rectangle against an iterator of rectangles. </td></tr>
<tr><td> <code>box.snapped_margins(d, x1, y1, w1, h1, x2, y2, w2, h2)</code> <br> <code>-&gt; snapped, left, top, right, bottom</code> </td><td> check if two boxes are snapped and on which margins. </td></tr></tbody></table>

<h3>OOP API</h3>

<b>v0.1a</b>, untested.<br>
<br>
Operations never mutate the box object, they always return a new one.<br>
<br>
<table><thead><th> <code>box(x, y, w, h) -&gt; box</code> </th><th> create a new box object </th></thead><tbody>
<tr><td> <code>box.x, box.y, box.w, box.h</code> </td><td> box coordinates (for reading and writing) </td></tr>
<tr><td> <code>box:rect() -&gt; x, y, w, h</code> <br> <code>box() -&gt; x, y, w, h</code> </td><td> coordinates unpacked    </td></tr>
<tr><td> <code>box:corners() -&gt; x1, y1, x2, y2</code> </td><td> left,top and right,bottom corners </td></tr>
<tr><td> <code>box:align(halign, valign, parent_box) -&gt; box</code> </td><td> align                   </td></tr>
<tr><td> <code>box:vsplit(i, sh) -&gt; box</code> </td><td> split vertically        </td></tr>
<tr><td> <code>box:hsplit(i, sw) -&gt; box</code> </td><td> split horizontally      </td></tr>
<tr><td> <code>box:nsplit(i, n, direction) -&gt; box</code> </td><td> split in equal parts    </td></tr>
<tr><td> <code>box:translate(x0, y0) -&gt; box</code> </td><td> translate               </td></tr>
<tr><td> <code>box:offset(d) -&gt; box</code>   </td><td> offset by d (outward if d is positive) </td></tr>
<tr><td> <code>box:fit(parent_box, halign, valign) -&gt; box</code> </td><td> enlarge/shrink-to-fit and align </td></tr>
<tr><td> <code>box:hit(x0, y0) -&gt; true | false</code> </td><td> hit test                </td></tr>
<tr><td> <code>box:hit_margins(x0, y0, d) -&gt; hit, left, top, right, bottom</code> </td><td> hit test for margins    </td></tr>
<tr><td> <code>box:snap_margins(d, boxes) -&gt; box</code> </td><td> snap the margins. boxes is an <code>iterator&lt;box&gt;</code> or a list of boxes </td></tr>
<tr><td> <code>box:snap_pos(d, boxes) -&gt; box</code> </td><td> snap the position       </td></tr></tbody></table>

TODO: access x1, y1, x2, y2 directly.