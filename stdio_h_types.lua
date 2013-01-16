--result of cpp stdio.h from mingw
local ffi = require'ffi'
require'systypes'

ffi.cdef[[
typedef struct _iobuf
{
	char* _ptr;
	int _cnt;
	char* _base;
	int _flag;
	int _file;
	int _charbuf;
	int _bufsiz;
	char* _tmpfname;
} FILE;
typedef long long fpos_t;
]]
