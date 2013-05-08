require'unit'
local readbuffer = require'readbuffer'

function fakereceive(s, return_sizes)
	local i = 1
	return function(maxsize)
		if i > #return_sizes then return end
		local size = return_sizes[i] i = i + 1
		assert(size <= maxsize, string.format('size %d > %d', size, maxsize))
		local ret = s:sub(1, size)
		s = s:sub(size + 1)
		--print('receive', size, ret)
		return ret
	end
end

--multiple reads till \r\n; even \r and \n come in two reads
local s = '12345\r\n'
local readline = readbuffer(fakereceive(s, {2,2,1,1,1}), 7).readline
assert(readline() == '12345')

--subsequent readline() uses leftover in buffer
local s = '123\r\nxy\r\nabcd'
local readline = readbuffer(fakereceive(s, {6,5}), 7).readline
assert(readline() == '123')
assert(readline() == 'xy')

--fill the buffer
local s = '123456\r\nabc\r\n'
local readline = readbuffer(fakereceive(s, {4,3,1,2,3}), 8).readline
assert(readline() == '123456')
assert(readline() == 'abc')

--buffer overflow
local s = '1234567\r\n'
local readline = readbuffer(fakereceive(s, {4,3,1,1}), 8).readline
local ok, err = pcall(readline)
assert(not ok and err == 'buffer overflow')

--readsize
test(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readsize(0), '')
test(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readsize(-5), '')
test(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readsize(4), 'abcd')
test({pcall(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readsize,5)}, {false,'buffer overflow'})

--readchunks
--read an invalid number of bytes
test(ipack(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readchunks(-5)), {''})
test(ipack(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readchunks(0)), {''})
--reader returning empty string doesn't cause an infinite loop
test(ipack(readbuffer(fakereceive('abcdefghijkl', {0,0,0,3,0,1,0,4,0,0}), 4).readchunks(7)), {'abcd','efg'})
--flush on every read, read up to size
test(ipack(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readchunks(9,1)), {'abcd','efg','h','i'})
--flush when buffer full, last chunk must be read up to size instead of flushed because buffer is full
test(ipack(readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readchunks(10)), {'abcd','efgh','ij'})
--eof before size
test({pcall(ipack,readbuffer(fakereceive('abcdefghijkl', {4,3,1,2}), 4).readchunks(11))},{false,'eof'})
--read till eof, flush when buffer full
test(ipack(readbuffer(fakereceive('abcdefghijkl', {1,2,1,2}), 4).readall()), {'abcd','ef'})
--read till eof, flush on each load
test(ipack(readbuffer(fakereceive('abcdefghijkl', {1,2,1,2}), 4).readall(1)), {'a','bc','d','ef'})

