# clipper ffi binding

v1.0 | [ffi binding](http://code.google.com/p/lua-files/source/browse/clipper.lua) | [C binding](http://code.google.com/p/lua-files/source/browse/csrc/clipper/clipper.c) | [demo](https://code.google.com/p/lua-files/source/browse/clipper_demo.lua) | Clipper 5.1.5 | LuaJIT 2

## `local clipper = require'clipper'`

A C+ffi binding of [Clipper](http://www.angusj.com/delphi/clipper.php), Angus Johnson's free polygon clipping library.

![](http://media.lua-files.googlecode.com/hg/screenshots/clipper_demo.png)

## Features
  * polygon clipping: `intersection`, `union`, `difference`, `xor`
  * polygon simplificaion with `even_odd`, `non_zero`, `positive` and `negative` fill types
  * polygon offsetting with `square`, `round` and `miter` join types

## API

**Polygons**
------------------------------------------------------------------------------------------ --------------------------------------------------------
`clipper.polygon([n]) -> poly`                                                             create a polygon object of size `n` (default 0)
`poly:size() -> n`                                                                         number of vertices
`poly:add(x, y)`                                                                           add a vertex to the polygon
`poly:get(i).x -> n` <br> `poly:get(i).y -> n`                                             get vertex coordinates
`poly:get(i).x = n` <br> `poly:get(i).y = n`                                               set vertex coordinates
`poly:simplify(['even_odd'|'non_zero'|'positive'|'negative']) -> polys`                    [simplify a polygon](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/SimplifyPolygon.htm)
`poly:clean([distance]) -> polys`                                                          [clean a polygon](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/CleanPolygon.htm)
`poly:reverse()`                                                                           reverse the order (and hence orientation) of vertices
`poly:orientation() -> true | false`                                                       polygon orientation (true = clockwise)
`poly:area() -> n`                                                                         polygon area
**Polygon lists**
`clipper.polygons([n | poly1, poly2, ...]) -> polys`                                       create a polygon list
`polys:size() -> n`                                                                        list size
`polys:add(poly)`                                                                          add a polygon to the end of the list
`polys:get(i) -> poly`                                                                     get a polygon from the list
`polys:set(i, poly)`                                                                       set a polygon in the list
`polys:simplify(['even_odd'|'non_zero'|'positive'|'negative']) -> polys`                   [simplify polygons](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/SimplifyPolygons.htm) (default is `'even_odd'`)
`polys:clean([distance]) -> polys`                                                         [clean polygons](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Routines/CleanPolygons.htm) (default distance is `~= sqrt(2)`)
`polys:reverse()`                                                                          reverse the order (and hence orientation) of vertices
`polys:offset(delta, ['square'|'round'|'miter'], [limit]) -> polys`                        offset polygons (default is 'square', 0)
**Clipping**
`clipper.new() -> cl`                                                                      create a clipper object
`cl:add_subject(poly | polys)`                                                             add polygons to be clipped
`cl:add_clip(poly | polys) `                                                               add polygons to be clipped against

------------------------------------------------------------------------------------------ --------------------------------------------------------
`cl:execute(operation, [subj_fill_type], [clip_fill_type], [reverse]) -> polys`            clip subject polygons against clip polygons
  <br> * `operation = 'intersection'|'union'|'difference'|'xor'`                                optionally setting the fill type for each polygon list and,
  <br> * `*_fill_type = 'even_odd'|'non_zero'|'positive'|'negative'`                            optionally reversing the order of the vertices
  <br> * `reverse = true | false`

`cl:get_bounds() -> x1, y1, x2, y2`                                                        bounding box of all the polygons in the clipper
------------------------------------------------------------------------------------------ --------------------------------------------------------

## Notes
  * input and output vertices are `int64_t` cdata, not Lua numbers; use simple scaling on the input and output points to preserve sub-pixel accuracy.
  * all objects are garbage collected.
  * adding a polygon to a polygon list copies the polygon and all its elements to the list so there's no need to keep a reference to the polygon afterwards.
  * `poly:get(1)` returns a pointer to the beginning of the vertex array so pointer arithmetic and memcpy are allowed on it.
