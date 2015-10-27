_**NOTE: work-in-progress (version 1.0 coming soon)**_

v1.0 | [binding](http://code.google.com/p/lua-files/source/browse/libjpeg.lua) | [header](http://code.google.com/p/lua-files/source/browse/libjpeg_h.lua) | [demo](http://code.google.com/p/lua-files/source/browse/libjpeg_demo.lua) | libjpeg-turbo 1.2.1 | LuaJIT 2

## `local libjpeg = require'libjpeg'` ##

A ffi binding of [libjpeg-turbo](http://libjpeg-turbo.virtualgl.org/), a fast and complete JPEG codec.

## Features ##
  * progressive loading
  * partial loading
  * fractional scaling
  * multiple conversion options.

## `libjpeg.load(t) -> image` ##

Read and decode a JPEG image.

  * `t` is a table specifying:
    * where to read the data from (one of the following):
      * `path`: read data from a file given its filename
      * `string`: read data from a string
      * `cdata`, `size`: read data from a buffer of specified size
      * `stream`: read data from an opened `FILE *` stream
      * `read`: read data from a reader function of the form:
        * `read() -> cdata, size | string | nil`
    * decoding and conversion options:
      * `accept`: if present, it is a table specifying accepted pixel formats and bitmap orientations for the output image.
        * `[pixel_format] = true` - specify one or more accepted pixel formats:
          * 'rgb8', 'bgr8', 'rgba8', 'bgra8', 'argb8', 'abgr8', 'rgbx8', 'bgrx8', 'xrgb8', 'xbgr8', 'g8', 'ga8', 'ag8', 'ycc8', 'ycck8', 'cmyk8'.
            * note: not all conversions are possible with libjpeg-turbo, so always consult the output image's `format` field to get the actual format; use [bitmap](bitmap.md) to further convert the image if necessary.
        * `[orientation] = true` - specify one or both accepted bitmap orientations:
          * 'top\_down', 'bottom\_up' (default is 'top\_down')
        * `padded`: true/false (default is false) - specify that the row stride should be a multiple of 4
      * `scale_num`, `scale_denom`: scale down the image by the fraction scale\_num/scale\_denom. Currently, the only supported scaling ratios are M/8 with all M from 1 to 16, or any reduced fraction thereof (such as 1/2, 3/4, etc.) Smaller scaling ratios permit significantly faster decoding since fewer pixels need be processed and a simpler IDCT method can be used.
      * `dct_method`: 'accurate', 'fast', 'float' (default is 'accurate')
      * `fancy_upsampling`: true/false (default is false); use a fancier upsampling method
      * `block_smoothing`: true/false (default is false); smooth out large pixels of early progression stages for progressive JPEGs.
      * `partial_loading`: true/false (default is true); display broken images partially or break with an error.
      * `header_only`: do not decode the image; return only the image header fields.
    * callbacks:
      * `render_scan`: a function to be called as `render_scan(image, is_last_scan, scan_number)` for each progressive scan of a multi-scan JPEG. It can used to implement progressive display of images.
        * also called once for single-scan images.
        * also called on error, as `render_scan(nil, true, scan_number, error)`, where `scan_number` is the scan number that was supposed to be rendering next and `error` the error message.
      * `warning`: a function to be called as `warning(msg, level)` on non-fatal errors.

For more info on the decoding process and options read the [libjpeg-turbo documentation](http://sourceforge.net/p/libjpeg-turbo/code/HEAD/tree/trunk/libjpeg.txt).

The returned image object is a table with the fields:
  * `file`: a table describing file attributes: `w`, `h`, `format`, `progressive`, `jfif`, `adobe`.
    * `file.format` is missing for unknown formats.
  * `format`, `bottom_up`, `stride`, `data`, `size`, `w`, `h`: output image format, dimensions and pixel data.
    * the number of bits per channel is always 8.
    * these fields are not present with the `headers_only` option.
  * `partial`: true if the image was found to be truncated and it was partially loaded.

## Help needed ##
  * encoding API
  * progressive loading at scan line level
  * jit is turned off because we can't call error() from a ffi callback called from C; and yet we must not return control to C on errors. is there a way around it?
  * the read callback cannot yield since it is called from C code. this means coroutine-based socket schedulers are out, so much for progressive loading. is there a way around it?


---

See also: [nanojpeg](nanojpeg.md), [imagefile](imagefile.md).