svg parser to a cairo scene graph object


v0.9 | [code](http://code.google.com/p/lua-files/source/browse/svg_parser.lua) | [test](http://code.google.com/p/lua-files/source/browse/svg_parser_test.lua) | LuaJIT 2 (written in Lua but uses [expat])

## `local svg_parser = require'svg_parser'`

A SVG 1.1 parser implemented in Lua. There's a handy collection of [svg files](http://code.google.com/p/lua-files/source/browse?repo=media#hg%2Fsvg) to test the parser with.

Some notable features are not yet implemented:
  * patterns
  * radial gradient has issues
  * text
  * markers
  * constrained transforms: ref(svg,[x,y])
  * external references
  * use tag

Low-priority missing features:
  * icc colors
  * css language

## `svg_parser.parse(source) -> object`

Parses a SVG into a cairo scene graph object that can be rendered with [sg_cairo sg_cairo]. <br>
  * `source` is an [expat] source.
