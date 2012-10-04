--result of cpp stdint.h from mingw
--the following types are ffi built-ins:
--int8_t, int16_t, int32_t, int64_t, uint8_t, uint16_t, uint32_t, uint64_t, intptr_t, uintptr_t
local ffi = require'ffi'
require'clib.stddef'
ffi.cdef[[
typedef signed char int_least8_t;
typedef unsigned char uint_least8_t;
typedef short int_least16_t;
typedef unsigned short uint_least16_t;
typedef int int_least32_t;
typedef unsigned uint_least32_t;
typedef long long int_least64_t;
typedef unsigned long long uint_least64_t;
typedef signed char int_fast8_t;
typedef unsigned char uint_fast8_t;
typedef short int_fast16_t;
typedef unsigned short uint_fast16_t;
typedef int int_fast32_t;
typedef unsigned int uint_fast32_t;
typedef long long int_fast64_t;
typedef unsigned long long uint_fast64_t;
typedef long long intmax_t;
typedef unsigned long long uintmax_t;
]]
