--sources return a reader function read() that returns a string or nil on eof.
--sinks return a writer function write(s) that flushes the sink when called without arguments.

local source = {}

function source.string(s)
	return function()

	end
end

function source.file(filename, mode)
	local f = io.open(filename, mode or 'rb')
	return function(sz)
		f:read(sz)
	end
end

function source.cdata(data, sz)
	return function()

	end
end

local sink = {}

function sink.table(t)
	t = t or {}
	local function write(s)
		t[#t+1] = s
	end
	return write, t
end

function sink.buffer(write, maxnum, maxlen)
	maxnum = maxnum or 1024
	maxlen = maxlen or 65536

	local buf = {}
	local buflen = 0

	local function flush()
		local s = table.concat(buf)
		if #s > 0 then write(s) end
		buf = {}
		buflen = 0
	end

	local function write(s)
		buf[#buf+1] = s
		buflen = buflen + #s
		if #buf >= maxnum or buflen >= maxlen then flush() end
	end

	return write, flush
end

function sink.file(filename, mode, bufmode, bufsize)
	local f = io.open(filename, mode or 'wb')
	f:setvbuf(bufmode or 'full', bufsize or 65536)
	local function write(s)
		f:write(s)
	end
	return write, f
end

if not ... then require'streams_test' end

return {
	sink = sink,
	source = source,
}

