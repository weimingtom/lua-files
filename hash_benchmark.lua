local ffi = require'ffi'
require'unit'

local function benchmark(s, hash)
	timediff()
	local sz = 1024^2
	local iter = 1024
	local key = ffi.new('uint8_t[?]', sz)
	for i=0,sz-1 do key[i] = i % 256 end
	local h = 0
	for i=1,iter do
		h = hash(key, sz, h)
	end
	print(string.format('%s  %f MB/s', s, fps(sz*iter)/sz))
end

benchmark('murmurhash3 Lua', require'murmurhash3'.hash)
benchmark('murmurhash3 C  ', require'pmurhash'.hash)
benchmark('md5 C          ', require'md5'.sum)
benchmark('crc32b C       ', require'zlib'.crc32b)
benchmark('adler32 C      ', require'zlib'.adler32)
benchmark('sha256 C       ', require'sha2'.sha256)
benchmark('sha384 C       ', require'sha2'.sha384)
benchmark('sha512 C       ', require'sha2'.sha512)
