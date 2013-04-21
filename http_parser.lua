--http protocol parsing
local glue = require'glue'

local function request_line(s)
	local method, uri, version = s:match'^([^ ]+) ([^ ]+) HTTP/(%d+%.%d+)$'
	return method, uri, version
end

local function response_line(s)
	local version, status, message = s:match'^HTTP/(%d+%.%d+) (%d%d%d) ?(.*)$'
	status = tonumber(status)
	return status, message, version
end

local function headers(reader)
	local t = {}
	local s = reader:readline()
	while s and s ~= '' do                           --headers end with an empty line
		s = s:gsub('[\t ]+', ' ')                     --LWS -> one SP
		local k,v = s:match'^([^:]+): ?(.-) ?$'       --name: SP? value SP?
		k = glue.assert(k, 'malformed header %s', s)
		k = k:gsub('%-','_'):lower()                  --Some-Header -> some_header
		s = reader:readline()
		while s and s:find'^[\t ]' do                 --values can span multiple lines
			s = s:gsub('[\t ]+', ' ')                  --LWS -> one SP
			v = v .. s:gsub(' $', '')                  --rtrim and concat
			s = reader:readline()
		end
		t[k] = t[k] and t[k]..','..v or v             --combine duplicate headers
	end
	return t
end

--return a reader function that reads up the bytes of the next chunk in a chunked transfer encoding.
--returns nil if the next chunk has size 0, which signals eof.
local function chunk_source(reader)
	local s = reader:readline()
	local size = tonumber(s:match'^[^;]+', 16)
	assert(size, 'invalid chunk size')
	if size == 0 then return end
	local read = reader:readchunks(size)
	return function()
		local s = read()
		if not s then
			reader:readline()
		end
		return s
	end
end

--return a reader function for the chunked transfer encoding.
local function chunked_source(reader)
	local read = chunk_source(reader)
	return function()
		if not read then return end
		local s = read()
		if not s then
			read = chunk_source(reader)
			if not read then return end
			s = read()
		end
		return s
	end
end

local function pipe(source, filter)
	return function()
		local s = source()
		return s and filter(s)
	end
end

local function pipe_encodings(source, reader, encodings)
	if not encodings then return source end
	encodings = glue.collect(glue.gsplit(encodings, ' ?, ?'))
	for i = #encodings, 1, -1 do
		local encoding = encodings[i]
		if encoding == 'identity' then
			--nothing
		elseif encoding == 'chunked' then
			--the chunked encoding must be the last encoding and can only be specified once.
			source = chunked_source(reader)
		elseif encoding == 'gzip' then
			error'NYI gzip'
		elseif encoding == 'deflate' then
			error'NYI deflate'
		else
			error(string.format('unsupported encoding %s', encoding))
		end
	end
	return source
end

local function body(reader, headers)
	local source
	if headers.content_length then
		local sz = tonumber(headers.content_length)
		source = reader:readchunks(sz)
	else
		function source()
			return reader:readall()
		end
	end
	source = pipe_encodings(source, reader, headers.transfer_encoding)
	source = pipe_encodings(source, reader, headers.content_encoding)
	return source
end

--if not ... then require'http_parser_test' end
--if not ... then require'scraping_anuntul' end

return {
	request_line = request_line,
	response_line = response_line,
	headers = headers,
	body = body,
	decoders = decoders,
}

