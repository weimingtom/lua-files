v1.0 | [code](http://code.google.com/p/lua-files/source/browse/freetype.lua) | [header](http://code.google.com/p/lua-files/source/browse/freetype_h.lua) | [demo](https://code.google.com/p/lua-files/source/browse/freetype_demo.lua) | [test](https://code.google.com/p/lua-files/source/browse/freetype_test.lua) | LuaJIT 2

## `local freetype = require'freetype'` ##

A ffi binding of [FreeType 2](http://freetype.org/freetype2/).

![http://media.lua-files.googlecode.com/hg/screenshots/freetype_demo.png](http://media.lua-files.googlecode.com/hg/screenshots/freetype_demo.png)

## API ##

Look at the bottom of `freetype.lua` for method names for each object type. Use the demo and test files for usage examples.

Consult the [Freetype documentation](http://www.freetype.org/freetype2/documentation.html) for knowledge about fonts and rasterization.

## Binary ##

The included freetype binary is a **stripped** build of freetype. In particular, font formats other than ttf and cff are not supported. Also, the **patent-encumbered LCD filtering is enabled**, so it may well be illegal to use this binary in your country. If unsure, compile your own.