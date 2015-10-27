The OpenGL API is not usually found in a OS as a straight C library, or at least not all of it is. Instead, the OS supplies a loader API (called WGL in Windows, GLX in Linux, CGL in MacOS X) through which you retrieve pointers to actual OpenGL functions. So while the OpenGL functions and constants themselves are standard, you can only get access to a working OpenGL namespace through a platform-specific API.

## `local gl = require'winapi.gl11'` ##
## `local gl = require'winapi.gl21'` ##

Get an OpenGL 1.1 or 2.1 namespace. Functions are discovered automatically through WGL and their pointers memoized for later calls.

Below are the function prototypes and constants that are accessible in the `gl` namespace depending on which version you load:

  * [common OpenGL C types](http://code.google.com/p/lua-files/source/browse/gl_types.lua)
  * [OpenGL 1.1 constants](http://code.google.com/p/lua-files/source/browse/gl_consts11.lua)
  * [OpenGL 1.1 function prototypes](http://code.google.com/p/lua-files/source/browse/gl_funcs11.lua)
  * [OpenGL 2.1 constants](http://code.google.com/p/lua-files/source/browse/gl_consts21.lua)
  * [OpenGL 2.1 function pointer prototypes](http://code.google.com/p/lua-files/source/browse/gl_funcs21.lua)
    * imagine that PFNGLDRAWARRAYSINDIRECTPROC is glDrawArraysIndirect

## `local glu = require'glu'` ##

The [GLU API](http://code.google.com/p/lua-files/source/browse/glu_h.lua) contains auxiliary utilities that let you set a perspective transform or an orthogonal transform or move the camera, among other things. [glu\_lua](http://code.google.com/p/lua-files/source/browse/glu_lua.lua) implements a few of these for environments that don't have a GLU implementation.

## `local glut = require'glut'` ##

The [GLUT API](http://code.google.com/p/lua-files/source/browse/glut.lua) lets you render the Utah Teapot (other stuff not included).

## `local wgl = require'winapi'` ##
## `require'winapi.wgl'` ##

The [WGL API](http://code.google.com/p/lua-files/source/browse/winapi/wgl.lua) provides `wglCreateContext` for creating an OpenGL context on a HDC. It also provides `wglGetProcAddress` for discovery of OpenGL functions.

For a straight application of the WGL API see module [winapi.wglpanel](wglpanel.md).

## `local wglex = require'winapi'` ##
## `require'winapi.wglext'` ##

The [WGLEXT API](http://code.google.com/p/lua-files/source/browse/winapi/wglext.lua) provides various Windows-specific OpenGL extensions.