--md5 sum and digest
local ffi = require "ffi"
local glue = require'glue'

ffi.cdef[[
typedef unsigned int MD5_u32plus;

typedef struct {
	MD5_u32plus lo, hi;
	MD5_u32plus a, b, c, d;
	unsigned char buffer[64];
	MD5_u32plus block[16];
} MD5_CTX;

void MD5_Init(MD5_CTX *ctx);
void MD5_Update(MD5_CTX *ctx, void *data, unsigned long size);
void MD5_Final(unsigned char *result, MD5_CTX *ctx);
]]

local lib = ffi.load'md5'

local function digest()
	local ctx = ffi.new'MD5_CTX'
	local result = ffi.new'uint8_t[16]'
	lib.MD5_Init(ctx)
	return function(data, sz)
		if data then
			if type(data) == 'string' then
				lib.MD5_Update(ctx, ffi.cast('void*', data), sz or #data)
			else
				lib.MD5_Update(ctx, data, sz)
			end
		else
			lib.MD5_Final(result, ctx)
			return glue.string.tohex(ffi.string(result, 16))
		end
	end
end

local function sum(s)
	local d = digest(); d(s); return d()
end

if not ... then require'md5_test' end

return {
	digest = digest,
	sum = sum,
	lib = lib,
}

