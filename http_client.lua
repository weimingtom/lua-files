--primitive http client for demonstrating the http parser, socketloop and uri.
--TODO: support cookie jar, keep-alive.

local glue = require'glue'
local socketloop = require'socketloop'
local socketreader = require'socketreader'
local http_parser = require'http_parser'
local uri = require'uri'

local function getpage(loop, surl)
	local url = uri.parse(surl)
	assert(url.scheme == 'http', 'bad url %s', surl)
	print(url.host, url.port)
	local skt = assert(loop.connect(url.host, url.port or 80))

	local request =
		'GET '.. (url.path or '/') ..' HTTP/1.1' .. '\r\n' ..
		'Host: ' .. url.host .. '\r\n' ..
		'Connection: close' .. '\r\n' ..
		'Cache-Control: max-age=0' .. '\r\n' ..
		'User-Agent: Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/26.0.1410.64 Safari/537.31' .. '\r\n' ..
		'\r\n'
	skt:send(request)
	local reader = socketreader(skt)

	local response_line = assert(skt:receive'*l')
	local status, message, version = http_parser.response_line(response_line)
	local headers = http_parser.headers(reader)

	if status == 301 or status == 302 or status == 303 or status == 307 or status == 308 then
		assert(headers.location, 'status %d received but no Location header')
		return getpage(loop, headers.location)
	end

	local t = {}
	for s in http_parser.body(reader, headers) do
		t[#t+1] = s
	end
	return table.concat(t)
end

if not ... then

local loop = socketloop()
local function client()
	print(getpage(loop, 'http://www.google.com/'))
end
loop.newthread(client)
loop.start()

end

return getpage
