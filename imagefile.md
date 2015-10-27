_**NOTE: work-in-progress (version 1.0 coming soon)**_

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/imagefile.lua) | LuaJIT 2

## `local imagefile = require'imagefile'` ##

## `imagefile.load(t) -> image` ##

Read and decode a raster image.

  * `t` is a table specifying where to get the data from and other loading options. It is passed directly to the specific loader chosen. If loading from a `path`, the image type is inferred from the file extension, otherwise you must specify the `type` field.

Supported types:
  * 'gif', through [giflib](giflib.md); returns the first frame for animated gifs (use giflib directly to get all the frames)
  * 'jpeg', through [libjpeg](libjpeg.md)
  * 'png', through [libpng](libpng.md)

Examples:
```
local image = imagefile.load{path = 'some.jpg'} --type inferred from path
local image = imagefile.load{string = s, type = 'jpeg'}
local image = imagefile.load{cdata = buf, size = sz, type = 'jpeg'}
```

The returned image is the image object as returned by the specific image loader.

You can force a conversion of the image to a specified pixel format and/or bitmap orientation, with an `accept` option in which you can specify only the accepted pixel formats, and if necessary, a conversion will be done automatically:
```
local image = imagefile.load({path = 'some.jpeg', accept = {bottom_up = true, rgba = true, argb = true})
```

In the above example the image will always be returned in bottom-row-first 8-bits-per-channel RGBA or ARGB format (whichever requires less conversion steps), regardless of the original format of the image.

## `imagefile.detect_type(filename) -> filetype` ##

Infer the file type from a file extension. Returns nil for unknown extensions.


---

See also: [bitmap](bitmap.md).