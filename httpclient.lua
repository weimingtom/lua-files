--http protocol: formatting and parsing of client and server messages
local glue = require'glue'
local http_parse = require'http_parse'
local http_format = require'http_format'

--read response

local function should_redirect(method, status, location)
    return (status == 301 or status == 302)
				and (method == 'GET' or method == 'HEAD')
				and location
end

local function should_have_body(method, status)
    return method ~= 'HEAD' and code >= 200 and code ~= 204 and code ~= 304
end

local function read_response(readline, readchunks, readall)
	local t = {}
	t.http_version, t.status, t.status_message = parse_response_line(readline())
	t.headers = read_headers(readline)
	t.read_body = read_body(t.headers, readline, readchunks, readall)
	return t
end

--format request

local default_ports = {http = 80, https = 443}

local function format_request(req)
	local url = req.url and uri.parse(req.url) or {}
	glue.update(url, req) --override any url components
	local pathquery = uri.format{
		path = url.path or '/',
		segments = url.segments,
		query = url.query,
		args = url.args,
	}
	local method = req.method or (req.body and 'POST' or 'GET')
	local headers = glue.update({}, req.headers)

	if not headers.accept_encoding then
		headers.accept_encoding = glue.keys(decoders)
	end

	if req.body then
		headers.content_length = #req.body
	elseif req.read_body_chunk then
		headers.transfer_encoding = 'chunked'
	end

	local function getdata(send)
		return coroutine.wrap(function()
			coroutine.yield(format_request_line(method, pathquery))
			coroutine.yield(format_headers(headers))
			if req.body then
				coroutine.yield(req.body)
			else
				repeat
					local s = req.read_body_chunk()
					coroutine.yield(format_chunk(s or ''))
				until not s
			end
		end)
	end

	return {
		host = url.host,
		port = url.port or default_ports[url.scheme or 'http'],
		getdata = getdata,
	}
end

t = format_request{
	url = 'http://google.com/search?q=bear',
	body = 'hello',
}
for s in t.getdata() do print(s) end

local function request(req, state, connect, send)
	local t = http_format.request_line(req.method, req.pathquery)
	if not state or t.host ~= state.host or t.port ~= state.port then
		connect(t.host, t.port)
		state = {host = t.host, port = t.port}
		send(t.lines)
		if t.sendbody then
			repeat
				local s, more = t.sendbody()
				send(s)
			until not more
		end
	end
	return state
end

