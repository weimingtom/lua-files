--http protocol parsing and formatting.
local glue = require'glue'
local coro = require'coro'

local function read_request_line(readline)
	local s = readline()
	local method, uri, version = s:match'^([^ ]+) ([^ ]+) HTTP/(%d+%.%d+)$'
	return method, uri, version
end

local function write_request_line(write, method, uri, version)
	method = method:upper()
	write(string.format('%s %s HTTP/%s\r\n', method, uri, version))
end

local function read_response_line(readline)
	local s = readline()
	local version, status, message = s:match'^HTTP/(%d+%.%d+) (%d%d%d) ?(.*)$'
	status = tonumber(status)
	return status, message, version
end

local function write_response_line(write, status, message, version)
	status = tostring(status)
	message = message or status_messages[status] or ''
	write(string.format('HTTP/%s %s %s\r\n', version, status, message))
end

local function read_headers(readline, headers)
	headers = headers or {}
	local s = readline()
	while s ~= '' do                                 --headers end with an empty line
		s = s:gsub('[\t ]+', ' ')                     --LWS -> one SP
		local k,v = s:match'^([^:]+): ?(.-) ?$'       --name: SP? value SP?
		k = glue.assert(k, 'malformed header %s', s)
		k = k:gsub('%-','_'):lower()                  --Some-Header -> some_header
		s = readline()
		while s:find'^[\t ]' do                       --values can span multiple lines
			s = s:gsub('[\t ]+', ' ')                  --LWS -> one SP
			v = v .. s:gsub(' $', '')                  --rtrim and concat
			s = readline()
		end
		if headers[k] then
			headers[k] = headers[k]..','..v            --combine duplicate headers
		else
			headers[k] = v
		end
	end
	return headers
end

local function upper1(c, s)
	return c:upper() .. s
end
local function format_header_name(k)
	k = k:gsub('_', '-')
	k = k:gsub('(%a)(%w*)', upper1) --some_header = Some-Header
	return k
end

local function format_header_value(v)
	v = v:gsub('[\t ]+', ' ')             --LWS -> one SP
	v = v:gsub('^ ', ''):gsub(' $', '')   --trim
	return v
end

local function format_header(k, v)
	return string.format('%s: %s\r\n', k, v)
end

--headers/trailers are normalized to preserve binary equivalence when possible.
local function write_headers(write, headers)
	local names, values = {}, {}
	for k,v in pairs(headers) do
		k = format_header_name(k)
		names[#names+1] = k
		assert(not values[k], 'duplicate header')
		values[k] = format_header_value(v)
	end
	table.sort(names)
	for _,k in ipairs(names) do
		write(format_header(k, values[k]))
	end
	write('\r\n')
end

local function chunked_reader(readline, readsize, trailers)
	local parent = coro.current
	return coro.wrap(function()
		local function write(s)
			coro.transfer(parent, s)
		end
		while true do
			size = readline()
			size = size:match'^[^;]+' --strip extension
			size = tonumber(size, 16) --comes in hex
			size = assert(size, 'invalid chunk size')
			if size == 0 then
				read_headers(readline, trailers)
				break
			end
			for s in readsize(size) do
				write(s)
			end
			readline()
		end
	end)
end

local function zlib_reader(format)
	return function(read)
		local zlib = require'zlib'
		local ffi = require'ffi'
		local parent = coro.current

		return coro.wrap(function()
			local function write(buf, sz)
				local s = ffi.string(buf, sz)
				coro.transfer(parent, s)
			end
			zlib.inflate(read, write, nil, format)
		end)
	end
end

local deflate_reader = zlib_reader'deflate' --decodes raw deflate without zlib header
local gzip_reader = zlib_reader'gzip'

local function pipe_reader(read, encodings)
	if not encodings then return read end
	encodings = glue.collect(glue.gsplit(encodings, ' ?, ?'))
	for i = #encodings, 1, -1 do
		local encoding = encodings[i]
		if encoding == 'identity' or encoding == 'chunked' then
			--identity does nothing, chunked would already be set.
		elseif encoding == 'gzip' then
			read = gzip_reader(read)
		elseif encoding == 'deflate' then
			read = deflate_reader(read)
		else
			error(string.format('unsupported encoding %s', encoding))
		end
	end
	return read
end

local function body_reader(readline, readsize, readall, headers)
	local read
	if headers.transfer_encoding and headers.transfer_encoding ~= 'identity' then
		read = chunked_reader(readline, readsize, headers)
	elseif headers.content_length then
		local length = tonumber(headers.content_length)
		assert(length and length >= 0, 'invalid Content-Length header')
		read = readsize(length)
	else
		assert(headers.connection == 'close',
				'"Connection: close" expected in absence of "Transfer-Encoding: chunked" or Content-Length')
		read = readall()
	end
	read = pipe_reader(read, headers.transfer_encoding)
	read = pipe_reader(read, headers.content_encoding)
	return read
end

local function write_chunk(write, s)
	write(string.format('%x\r\n', #s))
	write(s)
	write('\r\n')
end

--[[
local function chunked_writer(write)
	return function(s)
		s = s or ''
		write_chunk(write, s)
	end
end

local function zlib_writer(format)
	return function(write)
		local zlib = require'zlib'
		local ffi = require'ffi'
		local parent = coro.current
		return coro.wrap(function()
			local function read()
				return coro.transfer(parent)
			end
			zlib.deflate(read, write, nil, format)
		end)
	end
end

local inflate_writer = zlib_writer'deflate' --encodes raw deflate without zlib header
local gzip_writer = zlib_writer'gzip'
]]

if not ... then require'http_client_test' end

return {
	read_request_line = read_request_line,
	write_request_line = write_request_line,

	read_response_line = read_response_line,
	write_response_line = write_response_line,

	read_headers = read_headers,
	write_headers = write_headers,

	body_reader = body_reader,

	write_chunk = write_chunk,
	--chunked_writer = chunked_writer,
	--gzip_writer = gzip_writer,
	--zlib_writer = zlib_writer,
}

