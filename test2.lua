local ffi = require'ffi'

ffi.cdef[[
typedef struct s1rec_ {
	int i;
} s1rec;

typedef struct s2rec_ {
	s1rec root;
} s2rec;

typedef struct s1rec_* s1;
typedef struct s2rec_* s2;

]]

local s1rec = ffi.new('s1rec')
local s1 = ffi.new('s1', s1rec)
ffi.gc(s1, function() print's1 done' end)

local s2 = ffi.cast('s2', s1)

print(s1, s2)

ffi.gc(s1, nil)
s1 = nil
