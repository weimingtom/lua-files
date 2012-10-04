require'glue'
import'uri,httpheaders'

--parse response line and headers

function readresponseline(readline)
	local version, status, message = readline():match'^HTTP/(%d+%.%d+) (%d%d%d) ?(.*)$'
	assert(version, 'malformed response line %s', s)
	status = tonumber(status)
	return version, status, message
end

function parseheadername(s)
	s = s:gsub('[\t\r\n% ]+', ' '):trim' ':gsub('%-','_'):lower()
	assert(s ~= '', 'malformed header %s', s)
end

function parseheadervalue(s)
	return s:gsub('[\t\r\n ]+', ' '):trim' '
end

function readheaders(readline, h)
	h = h or {}
	local s = readline()
	while s ~= '' do --headers section ends with empty line
		local k,v = s:match'^(.-):(.*)'
		assert(k, 'malformed header %s', s)
		k = parseheadername(k)
		s = readline()
		while s:find'^[\t ]' do --headers can span multiple lines
			v = v .. s
			s = readline()
		end
		v = parseheadervalue(v)
		h[k] = (h[k] and ', ' or '') .. v --fold if multiple values
	end
	return map(httpheaders.parse, h)
end

--read response body

function readchunked(readline, readchunks)
	return cowrap(function()
		repeat
			local size = tonumber(readline():match'^([^;])', 16)
			assert(size, 'invalid chunk size')
			for s in readchunks(size) do yield(s) end
			readline()
		until size == 0
	end)
end

--keys are http encoding names; they reflect in the Accept-Encoding header
--decoders are function(iterator->s) -> iterator->s, so they can be pipelined
decoders = {
	identity = identity,
}

function readbody(headers, readline, readchunks, readall)

	local function pipeline(source, encodings)
		local d = source
		for i=#encodings,1,-1 do --order is significant
			local decoder = decoders[encodings[i]]
			assert(decoder, 'unsupported encoding %s', encodings[i])
			d = decoder(d)
		end
		return d
	end

	local source
	local te = headers.transfer_encoding
	if te and te[#te] == 'chunked' then
		source = readchunked(readline, readchunks)
		te = slice(te, 1, -1)
	elseif headers.content_length then
		source = readchunks(headers.content_length)
	else
		source = readall()
	end
	if te then source = pipeline(source, te) end
	if ce then source = pipeline(source, ce) end
	return source
end

--read response

local function shouldredirect(method, status, location)
    return (status == 301 or status == 302)
				and (method == 'GET' or method == 'HEAD')
				and location
end

function shouldhavebody(method, status)
    return method ~= 'HEAD' and code >= 200 and code ~= 204 and code ~= 304
end

function readresponse(readline, readchunks, readall)
	local t = {}
	t.http_version, t.status, t.status_message = readresponseline(readline)
	t.headers = readheaders(readline)
	t.readbody = readbody(t.headers, readline, readchunks, readall)
	return t
end

--format request line and headers

function formatrequestline(method, uri)
	return ('%s %s HTTP/1.1\r\n'):format(method:upper(), uri)
end

function formatheadername(s)
	return s:gsub('[\t\r\n_%- ]+', '-'):trim'%-':
			gsub('([a-zA-Z])([a-zA-Z]*)', function(c,s)
					return c:upper() .. s:lower()
				end)
end

function foldheadervalues(t)
	return cat(filter(parseheadervalue, tostring, t), ', ')
end

problemheaders = { --headers that it's not safe to send them folded
	set_cookie = true,
	cookie = true,
	www_authenticate = true,
}

function formatheaders(headers)
	local t, h = {}, {}
	for k,v in pairs(headers) do
		h[formatheadername(k)] = v
	end
	for k,v in sortedpairs(h) do --order is not significant
		if type(v) == 'table' then
			if problemheaders[k] then
				for i=1,#v do
					add(t, k .. ': ' .. parseheadervalue(tostring(v[i])))
				end
			else
				add(t, k .. ': ' .. foldheadervalues(v) .. '\r\n')
			end
		else
			add(t, k .. ': ' .. parseheadervalue(v))
		end
	end
	return cat(t) .. '\r\n'
end

--format request body

function formatchunk(s)
	return ('%x'):format(#s) .. '\r\n' .. s .. '\r\n'
end

--format request

default_ports = {http = 80, https = 443}

function formatrequest(req)
	local u = req.url and uri.parse(req.url) or {}
	update(u, req) --override any url components
	local pathquery = uri.format{
		path = u.path or '/',
		segments = u.segments,
		query = u.query,
		args = u.args,
	}
	local method = req.method or (req.body and 'POST' or 'GET')
	local headers = copy(req.headers)

	if not headers.accept_encoding then
		headers.accept_encoding = keys(decoders)
	end

	local bodychunks
	if req.body then
		headers.content_length = #req.body
		sendbody = sendstring(s)
	elseif req.readbody then
		headers.transfer_encoding = 'chunked'
		sendbody = sendchunks(req.readbody)
	end

	local function getdata(send)
		local co = coroutine.create(function()
			yield(formatrequestline(method, pathquery))
			yield(formatheaders(headers))
			if bodychunk then
				repeat
					local s, more = bodychunk()
					yield(s)
				until not more
			end
		end)
		return function()
			return resume(co)
		end
	end

	return {
		host = u.host,
		port = u.port or default_ports[u.scheme or 'http'],
		getdata = getdata,
	}
end

function request(req, state, connect, send)
	local t = formatrequestlines(req)
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


if not ... then
	require'unit'
	test({parseresponseline'HTTP/1.1 404 Not Found'}, {'1.1', '404', 'Not Found'})
	test({parseresponseline'HTTP/1.1 404'}, {'1.1', '404', ''})
	test(parseheadername' some-HEADER-Even \n\r\t invalid ', 'some_header_even_invalid')
	test(parseheadervalue'\n\rsome\tHEADER\tValue \n\r\t', 'some HEADER Value')
	--[[
	local readline = ('multivalue: \r5 \r\nmultivalue: 2\t ,\n 7 \r\nmultivalue: 1\r\n\r\n'):gmatch('(.-)\r\n')
	test(readheaders(readline), {multivalue = {'5','2','7', '1'}})
	local readline = ('multiline: 5\r\n\t,2,\r\n 7,\n1\r\n\r\n'):gmatch('(.-)\r\n')
	test(readheaders(readline, {}), {multiline = {'5','2','7','1'}})
	local readline = ('empty:\r\n'):gmatch('(.-)\r\n')
	test(readheaders(readline, {}), {empty = {''}})
	local readline = ('twiceempty:\r\ntwiceempty:\r\n'):gmatch('(.-)\r\n')
	test(readheaders(readline, {}), {twiceempty = {'',''}})
	]]
	--format
	test(formatrequestline('post', '/dude?wazup'), 'POST /dude?wazup HTTP/1.1\r\n')
	test(foldheadervalues{'  a ','   b'}, 'a,b')
	test(formatheaders({multiple = {'  c  ', 'b', '  a'}}, true),
						'Multiple: c,b,a\r\n\r\n')
	test(formatheaders
		{CONTENT_LENGTH='  100  ', connection=' Close ', Host='www.dude.com\n'},
		'Connection: Close\r\nContent-Length: 100\r\nHost: www.dude.com\r\n\r\n')
end



------------------------------------------------------------------------------

function connect(host, port, loop)
	local skt,err = loop.connect(host, port)
	if skt == nil then return nil,err end
	return sktloop.wrap(skt, loop)
end


local function adjustproxy(reqt)
	local proxy = reqt.proxy
	if proxy then
		proxy = url.parse(proxy)
		return proxy.host, proxy.port or 3128
	else
		return reqt.host, reqt.port
	end
end

local default = { port = 80, path = '/', scheme = 'http' }

local function adjustrequest(reqt)
	-- parse url if provided
	local nreqt = reqt.url and url.parse(reqt.url, default) or {}
	-- explicit components override url
	for k,v in pairs(reqt) do nreqt[k] = v end
	assert(nreqt.host, 'invalid host "' .. tostring(nreqt.host) .. '"')
	-- compute uri if user hasn't overriden
	nreqt.uri = reqt.uri or adjusturi(nreqt)
	-- ajust host and port if there is a proxy
	nreqt.host, nreqt.port = adjustproxy(nreqt)
	-- adjust headers in request
	nreqt.headers = adjustheaders(nreqt)
	return nreqt
end


function sendrequest(reqt)
	sendrequestline()
	sendheaders()
	sendbody()
end

local function test()
	local loop = sktloop.newloop()
	loop.newthread(getpage, {url='http://google.com', body='hello'}, say, nil, loop)
	loop.loop()
end

