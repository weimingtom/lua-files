--sha256/384/512 sum and digest
local ffi = require'ffi'
local glue = require'glue'
local lib = ffi.load'sha2'

ffi.cdef[[
enum {
	SHA256_BLOCK_LENGTH  = 64,
	SHA256_DIGEST_LENGTH = 32,
	SHA384_BLOCK_LENGTH = 128,
	SHA384_DIGEST_LENGTH = 48,
	SHA512_BLOCK_LENGTH = 128,
	SHA512_DIGEST_LENGTH = 64,
};
typedef struct _SHA256_CTX {
	uint32_t	state[8];
	uint64_t	bitcount;
	uint8_t	buffer[SHA256_BLOCK_LENGTH];
} SHA256_CTX;
typedef struct _SHA512_CTX {
	uint64_t	state[8];
	uint64_t	bitcount[2];
	uint8_t	buffer[SHA512_BLOCK_LENGTH];
} SHA512_CTX;
typedef SHA512_CTX SHA384_CTX;

void SHA256_Init(SHA256_CTX *);
void SHA256_Update(SHA256_CTX*, const uint8_t*, size_t);
void SHA256_Final(uint8_t[SHA256_DIGEST_LENGTH], SHA256_CTX*);

void SHA384_Init(SHA384_CTX*);
void SHA384_Update(SHA384_CTX*, const uint8_t*, size_t);
void SHA384_Final(uint8_t[SHA384_DIGEST_LENGTH], SHA384_CTX*);

void SHA512_Init(SHA512_CTX*);
void SHA512_Update(SHA512_CTX*, const uint8_t*, size_t);
void SHA512_Final(uint8_t[SHA512_DIGEST_LENGTH], SHA512_CTX*);
]]

local function digest_function(Context, Init, Update, Final, DIGEST_LENGTH)
	return function()
		local ctx = ffi.new(Context)
		local result = ffi.new('uint8_t[?]', DIGEST_LENGTH)
		Init(ctx)
		return function(data, size)
			if data then
				if type(data) == 'string' then
					Update(ctx,
						ffi.cast('uint8_t*', data),
						math.min(size or #data, #data))
				else
					Update(ctx, data, size)
				end
			else
				Final(result, ctx)
				return glue.string.tohex(ffi.string(result, ffi.sizeof(result)))
			end
		end
	end
end

local digest_functions = {
	[256] = digest_function(ffi.typeof'SHA256_CTX', lib.SHA256_Init, lib.SHA256_Update, lib.SHA256_Final, lib.SHA256_DIGEST_LENGTH),
	[384] = digest_function(ffi.typeof'SHA384_CTX', lib.SHA384_Init, lib.SHA384_Update, lib.SHA384_Final, lib.SHA384_DIGEST_LENGTH),
	[512] = digest_function(ffi.typeof'SHA512_CTX', lib.SHA512_Init, lib.SHA512_Update, lib.SHA512_Final, lib.SHA512_DIGEST_LENGTH),
}

local function digest(digest_size)
	return digest_functions[digest_size]()
end

local function sum(digest_size, data, size)
	local d = digest(digest_size); d(data, size); return d()
end

if not ... then require'sha2_test' end

return {
	digest = digest,
	sum = sum,
	lib = lib,
}
