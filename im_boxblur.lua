local ffi = require'ffi'

ffi.cdef[[
void box_blur_argb32(uint8_t* pix, int w, int h, int radius);
]]

return ffi.load'boxblur'.box_blur_argb32
