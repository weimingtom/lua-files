OpenGL scene graph shape objects

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/sg_gl_shape.lua)

## `require'sg_gl_shape'`

Extends [sg_gl sg_gl] to render shape objects.

## Shape objects

A shape is a type of OpenGL scene graph object that describes a 3D object in a state-machine kind of language. Internally, the shape description is converted into a [sg_gl_mesh mesh object] which is then rendered.

~~~{.lua}
<shape_object> = {
	type = 'shape',
	<mode> |
	'color', r, g, b, a |
}

<mode> = see sg_gl_mesh for available modes.
~~~

----
See also: [sg_gl_mesh].
