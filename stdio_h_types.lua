--result of cpp stdio.h from mingw (FILE made opaque)
local ffi = require'ffi'

ffi.cdef[[
typedef struct _iobuf FILE;
typedef long long fpos_t;
]]
