local hash = require'murmurhash3'
local chash = require'pmurhash'
local md5 = require'md5'
local ffi = require'ffi'
require'unit'

local function sanity_test() --from their tests
	local key = ffi.new'uint8_t[256]'
	local hashes = ffi.new'uint32_t[256]'
	for i=0,255 do
		key[i] = i
		hashes[i] = hash(key,i,256-i)
	end
	local final = hash(ffi.cast('uint8_t*', hashes), 1024, 0)
  	assert(final == bit.tobit(0xB0F57EE3))
	print'hash verified'
end

local function benchmark(s, hash) --250M/s on E5200
	timediff()
	local sz = 1024^2
	local iter = 1024
	local key = ffi.new('uint8_t[?]', sz)
	for i=0,sz-1 do key[i] = i%256 end
	local h = 0
	for i=1,iter do
		h = hash(key, sz, h)
	end
	print(string.format('%s: %f MB/s', s, fps(sz*iter)/sz))
end

sanity_test()
benchmark('murmurhash3 Lua', hash)
benchmark('murmurhash3 C', chash)
benchmark('md5', require'md5'.digest())
