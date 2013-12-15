OpenGL scene graph wavefront obj objects

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/sg_gl_obj.lua)

## `require'sg_gl_obj'`

Extends [sg_gl] to render obj type objects. Uses [obj_loader] to parse obj files into [sg_gl_mesh mesh objects].
## Wavefront obj objects

~~~{.lua}
<obj_object> = {
  type = 'obj',
  file = {
    path = S,
    use_cache = true | false (false),
  },
}
~~~

----
See also: [sg_gl_mesh], [obj_loader].
