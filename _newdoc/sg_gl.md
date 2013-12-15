OpenGL scene graph render

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/sg_gl.lua) | [test](http://code.google.com/p/lua-files/source/browse/sg_gl_test.lua) | [player](http://code.google.com/p/lua-files/source/browse/sg_gl_player.lua)

## `local SG = require'sg_gl'`

## `local sg = SG:new([cache])`

Create a new scene graph render to render OpenGL scene graph objects on the currently active OpenGL context.

## OpenGL scene graph objects

~~~{.lua}
<object> = {
	<group> | ...
}

<group> =
	type = 'group', <object>, ...



~~~

## `sg:free()`

Free the render and any associated resources.

----
See also: [sg_gl_mesh], [sg_gl_shape], [sg_gl_obj], [sg_gl_debug].
