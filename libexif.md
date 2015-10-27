v1.0 | [binding](http://code.google.com/p/lua-files/source/browse/libexif.lua) | [header](http://code.google.com/p/lua-files/source/browse/libexif_h.lua) | libexif 0.6.21 | LuaJIT 2

## `local libexif = require'libexif'` ##

A ffi binding of [libexif](http://libexif.sourceforge.net/), the library for reading and writing EXIF information from/to image files.

## Help needed ##
Currently there's the binary, sanitized header and the module stub that returns the `clib` object so the library is usable at ffi level with the aid of the [libexif API documentation](http://libexif.sourceforge.net/api/). A Lua-ized API is missing, but the library is otherwise usable without it.