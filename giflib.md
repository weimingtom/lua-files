v1.0 | [binding](http://code.google.com/p/lua-files/source/browse/giflib.lua) | [header](http://code.google.com/p/lua-files/source/browse/giflib_h.lua) | [demo](http://code.google.com/p/lua-files/source/browse/giflib_demo.lua) | giflib 5.0 | LuaJIT 2

## `local giflib = require'giflib'` ##

Lightweight ffi binding of the antique [GIFLIB](http://sourceforge.net/projects/giflib/).

## `giflib.load(t) -> gif` ##

Read and decode a GIF image.

  * `t` is a table specifying where to read the data from and other loading options:
    * `path`: read data from a file given its filename
    * `string:` read data from a string
    * `cdata`, `size`: read data from a buffer of size `N`
    * `fileno`: read data from a low level file descriptor as returned by `C open()`
    * `opaque`: if `true`, prevents converting the gif transparent color to transparent black.

The returned `gif` object is a table with the fields:
  * `w`, `h`: the gif dimensions.
  * `frames = {image1, ...}`: the list of gif frames, in order, where each frame is an image object with the fields:
    * `format`, `stride`, `data`, `size`, `w`, `h`: image format, dimensions and pixel data.
      * the frames are always in top-down `rgba8` format (that is 32bit RGBA); use [bitmap](bitmap.md) to convert them to other formats.
    * `delay_ms`: gif frame delay in milliseconds, for animated gifs.
    * `x`, `y`: frame position relative to the top-left corner of the virtual canvas into which to paint the frame (in theory, gif frames can have different sizes and different positions than (0,0) but this feature is almost never used).


---

See also: [imagefile](imagefile.md).