--http protocol parsing
local glue = require'glue'

--request/response line

local function request_line(s)
	local method, uri, version = s:match'^([^ ]+) ([^ ]+) HTTP/(%d+%.%d+)$'
	return method, uri, version
end

local function response_line(s)
	local version, status, message = s:match'^HTTP/(%d+%.%d+) (%d%d%d) ?(.*)$'
	status = tonumber(status)
	return status, message, version
end

--headers

local function headers(readline)
	local t = {}
	local s = readline()
	while s and s ~= '' do                           --headers end with an empty line
		s = s:gsub('[\t ]+', ' ')                     --LWS -> one SP
		local k,v = s:match'^([^:]+): ?(.-) ?$'       --name: SP? value SP?
		k = glue.assert(k, 'malformed header %s', s)
		k = k:gsub('%-','_'):lower()                  --Some-Header -> some_header
		s = readline()
		while s and s:find'^[\t ]' do                 --values can span multiple lines
			s = s:gsub('[\t ]+', ' ')                  --LWS -> one SP
			v = v .. s:gsub(' $', '')                  --rtrim and concat
			s = readline()
		end
		t[k] = t[k] and t[k]..','..v or v             --combine duplicate headers
	end
	return t
end

--body

local function body_chunks(readline, readchunks)
	return coroutine.wrap(function()
		repeat
			local size = tonumber(readline():match'^([^;])', 16)
			assert(size, 'invalid chunk size')
			for s in readchunks(size) do
				coroutine.yield(s)
			end
			readline()
		until size == 0
	end)
end

--keys are http encoding names; they reflect in the Accept-Encoding header
--decoders are function(iterator->s) -> iterator->s, so they can be pipelined
local decoders = {
	identity = glue.pass,
}

local function pipeline(source, encodings, decoders)
	if encodings then
		for i=#encodings,1,-1 do --order is significant
			local decoder = decoders[encodings[i]]
			assert(decoder, 'unsupported encoding %s', encodings[i])
			source = decoder(source)
		end
	end
	return source
end

local function body(readline, readchunks, readall, headers)
	local decoders = glue.update({}, decoders)
	decoders.chunked = body_chunks(readline, readchunks)
	local source
	local sz = tonumber(headers.content_length)
	if sz then
		source = readchunks(sz)
	else
		source = readall()
	end
	local function parse_encodings(s)
		return glue.collect(glue.gsplit(s, ' ?, ?'))
	end
	source = pipeline(source, parse_encodings(headers.transfer_encoding))
	source = pipeline(source, parse_encodings(headers.content_encoding))
	return source
end


if not ... then require'http_parser_test' end

return {
	reqwest_line = request_line,
	response_line = response_line,
	headers = headers,
	body = body,
	decoders = decoders,
}

