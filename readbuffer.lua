--readbuffer interface for use with string-based network protocols like http.
--based on the function read(size) -> s | nil which should return a string of upto `size` bytes
--or nil on eof (i.e. connection closed).

local function readbuffer(read, bufsize)

	bufsize = bufsize or 16384
	local buf = ''

	local function load()
		local size = bufsize - #buf
		assert(size > 0, 'buffer overflow')
		local s = read(size)
		if s then
			buf = buf .. s
			return true
		end
	end

	local function flush()
		local s = buf
		buf = ''
		return s
	end

	--read until a match is found and return the captures. break on eof.
	local function readmatch(pat)
		while true do
			local s, rest = buf:match(pat .. '(.*)')
			if s then buf = rest return s end
			assert(load(), 'eof')
		end
	end

	--read until a line is captured. break on eof.
	local function readline()
		return readmatch('^(.-)\r\n')
	end

	--read a fixed amount of bytes. break on eof.
	local function readsize(size)
		while true do
			if #buf >= size then
				local s = buf:sub(1, size)
				buf = buf:sub(size + 1)
				return s
			end
			assert(load(), 'eof')
		end
	end

	--read chunks until size or eof. flushsize controls buffering.
	local function readchunks(size, flushsize)
		local flushsize = flushsize or bufsize
		assert(flushsize > 0, 'invalid flushsize')
		local done
		return function()
			while not done do
				assert(done ~= false, 'eof')
				if size and #buf >= size then
					done = true
					return readsize(size)
				elseif #buf >= flushsize then
					size = size and size - #buf
					return flush()
				elseif not load() then
					done = not size
					if #buf > 0 then
						return flush()
					end
				end
			end
		end
	end

	local function readall(flushsize)
		return readchunks(nil, flushsize)
	end

	return {
		flush = flush,
		readmatch = readmatch,
		readline = readline,
		readsize = readsize,
		readchunks = readchunks,
		readall = readall,
	}
end

if not ... then require'readbuffer_test' end

return readbuffer
