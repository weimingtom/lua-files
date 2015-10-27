v0.1 | [code](http://code.google.com/p/lua-files/source/browse/obj_loader.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local obj_loader = require'obj_loader'` ##

## `obj_loader.load(file[, use_cache]) -> mesh_object` ##

Loads an wavefront obj file into an OpenGL scene graph mesh object that can be rendered with [sg\_gl](sg_gl.md).

Supports groups with triangle and quad faces and textures with uv texcoords.

The resulting VBO and IBO arrays and IBO partitions can be cached to a temp file for a small speed increase with `use_cache`.


---

See also: [obj\_parser](obj_parser.md), [sg\_gl\_obj](sg_gl_obj.md).