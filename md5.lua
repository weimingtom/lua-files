--md5 hash and digest
local ffi = require "ffi"
local lib = ffi.load'md5'

ffi.cdef[[
typedef struct {
	uint32_t lo, hi;
	uint32_t a, b, c, d;
	uint8_t buffer[64];
	uint32_t block[16];
} MD5_CTX;

void MD5_Init(MD5_CTX *ctx);
void MD5_Update(MD5_CTX *ctx, void *data, uint32_t size);
void MD5_Final(unsigned char *result, MD5_CTX *ctx);
]]

local function digest()
	local ctx = ffi.new'MD5_CTX'
	local result = ffi.new'uint8_t[16]'
	lib.MD5_Init(ctx)
	return function(data, size)
		if data then
			if type(data) == 'string' then
				lib.MD5_Update(ctx,
					ffi.cast('void*', data),
					math.min(size or #data, #data))
			else
				lib.MD5_Update(ctx, data, size)
			end
		else
			lib.MD5_Final(result, ctx)
			return ffi.string(result, 16)
		end
	end
end

local function sum(data, size)
	local d = digest(); d(data, size); return d()
end

if not ... then require'md5_test' end

return {
	digest = digest,
	sum = sum,
	lib = lib,
}

