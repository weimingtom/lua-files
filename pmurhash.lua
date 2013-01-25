--pmurhash binding
local ffi = require'ffi'
local pmurhash = ffi.load'pmurhash'

ffi.cdef[[
uint32_t PMurHash32(uint32_t seed, const void *key, int len);
]]

local function hash(data, sz, seed)
	seed = seed or 0
	if type(data) == 'string' then
		data, sz = ffi.cast('const char*', data), sz or #data
	end
	return pmurhash.PMurHash32(seed, data, sz)
end

if not ... then assert(hash'hey' == 318325784) end

return hash
