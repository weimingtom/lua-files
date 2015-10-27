v1.0 | [ffi binding](http://code.google.com/p/lua-files/source/browse/clipper.lua) | [C binding](http://code.google.com/p/lua-files/source/browse/csrc/clipper/clipper.c) | [demo](https://code.google.com/p/lua-files/source/browse/clipper_demo.lua) | Clipper 5.1.5 | LuaJIT 2

## `local clipper = require'clipper'` ##

A C+ffi binding of [Clipper](http://www.angusj.com/delphi/clipper.php), Angus Johnson's free polygon clipping library.

![http://media.lua-files.googlecode.com/hg/screenshots/clipper_demo.png](http://media.lua-files.googlecode.com/hg/screenshots/clipper_demo.png)

## Features ##
  * polygon clipping: `intersection`, `union`, `difference`, `xor`
  * polygon simplificaion with `even_odd`, `non_zero`, `positive` and `negative` fill types
  * polygon offsetting with `square`, `round` and `miter` join types

## API ##

| **Polygons** | |
|:-------------|:|
| `clipper.polygon([n]) -> poly` | create a polygon object of size `n` (default 0) |
| `poly:size() -> n` | number of vertices |
| `poly:add(x, y)` | add a vertex to the polygon |
| `poly:get(i).x -> n` <br> <code>poly:get(i).y -&gt; n</code> <table><thead><th> get vertex coordinates </th></thead><tbody>
<tr><td> <code>poly:get(i).x = n</code> <br> <code>poly:get(i).y = n</code> </td><td> set vertex coordinates </td></tr>
<tr><td> <code>poly:simplify(['even_odd'|'non_zero'|'positive'|'negative']) -&gt; polys</code> </td><td> <a href='http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/SimplifyPolygon.htm'>simplify a polygon</a> </td></tr>
<tr><td> <code>poly:clean([distance]) -&gt; polys</code> </td><td> <a href='http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/CleanPolygon.htm'>clean a polygon</a> </td></tr>
<tr><td> <code>poly:reverse()</code> </td><td> reverse the order (and hence orientation) of vertices </td></tr>
<tr><td> <code>poly:orientation() -&gt; true | false</code> </td><td> get polygon orientation (true = clockwise) </td></tr>
<tr><td> <code>poly:area() -&gt; n</code> </td><td> get polygon area </td></tr>
<tr><td> <b>Polygon lists</b> </td><td> </td></tr>
<tr><td> <code>clipper.polygons([n | poly1, poly2, ...]) -&gt; polys</code> </td><td> create a polygon list </td></tr>
<tr><td> <code>polys:size() -&gt; n</code> </td><td> list size </td></tr>
<tr><td> <code>polys:add(poly)</code> </td><td> add a polygon to the end of the list </td></tr>
<tr><td> <code>polys:get(i) -&gt; poly</code> </td><td> get a polygon from the list </td></tr>
<tr><td> <code>polys:set(i, poly)</code> </td><td> set a polygon in the list </td></tr>
<tr><td> <code>polys:simplify(['even_odd'|'non_zero'|'positive'|'negative']) -&gt; polys</code> </td><td> <a href='http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/SimplifyPolygons.htm'>simplify polygons</a> (default is 'even_odd') </td></tr>
<tr><td> <code>polys:clean([distance]) -&gt; polys</code> </td><td> <a href='http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/CleanPolygons.htm'>clean polygons</a> (default distance is <code>~= sqrt(2)</code>) </td></tr>
<tr><td> <code>polys:reverse()</code> </td><td> reverse the order (and hence orientation) of vertices </td></tr>
<tr><td> <code>polys:offset(delta, ['square'|'round'|'miter'], [limit]) -&gt; polys</code> </td><td> offset polygons (default is 'square', 0) </td></tr>
<tr><td> <b>Clipping</b> </td><td> </td></tr>
<tr><td> <code>clipper.new() -&gt; cl</code> </td><td> create a clipper object </td></tr>
<tr><td> <code>cl:add_subject(poly | polys)</code> </td><td> add polygons to be clipped </td></tr>
<tr><td> <code>cl:add_clip(poly | polys) </code> </td><td> add polygons to be clipped against </td></tr>
<tr><td> <code>cl:execute(operation, [subj_fill_type], [clip_fill_type], [reverse]) -&gt; polys</code> <br> <code>operation = 'intersection'|'union'|'difference'|'xor'</code> <br> <code>*_fill_type = 'even_odd'|'non_zero'|'positive'|'negative'</code> <br> <code>reverse = true | false</code> </td><td> clip subject polygons against clip polygons <br> optionally setting the fill type for each polygon list and, <br> optionally reversing the order of the vertices </td></tr>
<tr><td> <code>cl:get_bounds() -&gt; x1, y1, x2, y2</code> </td><td> bounding box of all the polygons in the clipper </td></tr></tbody></table>

<h2>Notes</h2>
<ul><li>input and output vertices are <code>int64_t</code> cdata, not Lua numbers; use simple scaling on the input and output points to preserve sub-pixel accuracy.<br>
</li><li>all objects are garbage collected.<br>
</li><li>adding a polygon to a polygon list copies the polygon and all its elements to the list so there's no need to keep a reference to the polygon afterwards.<br>
</li><li><code>poly:get(1)</code> returns a pointer to the beginning of the vertex array so pointer arithmetic and memcpy are allowed on it.