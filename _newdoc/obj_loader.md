wavefront obj loader to the OpenGL scene graph mesh format

v0.1 | [code](http://code.google.com/p/lua-files/source/browse/obj_loader.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local obj_loader = require'obj_loader'`

## `obj_loader.load(file[, use_cache]) -> mesh_object`

Loads an wavefront obj file into an OpenGL scene graph mesh object that can be rendered with [sg_gl sg_gl].

Supports groups with triangle and quad faces and textures with uv texcoords.

The resulting VBO and IBO arrays and IBO partitions can be cached to a temp file for a small speed increase with `use_cache`.

----
See also: [obj_parser obj_parser], [sg_gl_obj sg_gl_obj].
