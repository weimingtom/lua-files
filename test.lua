local ffi = require'ffi'
foo_t = ffi.typeof("struct { int x; };")
ffi.cdef("typedef struct { int x; } foo_t;")
