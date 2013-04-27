local request = require'http_client'.request
local getpage = require'http_client'.getpage
local socketloop = require'socketloop_dummy'
local socketreader = require'socketreader'
local coro = require'coro'
local glue = require'glue'

local loop = socketloop()
local connect = function(host, port)
	local skt = loop.connect(host, port)
	local api = socketreader(skt)
	function api.write(s) skt:send(s) end
	return api
end

local getpage1 = getpage
local function getpage(t)
	local thread = getpage1(t, connect)
	local headers = coro.transfer(thread)
	local body = glue.collect(function() return coro.transfer(thread) end)
	return table.concat(body), headers
end

local function preview(s)
	print(s:sub(1, 30)..' ... '..s:sub(-30))
end

local function client()
	local function test_gzip()
		local body, headers = getpage('http://httpbin.org/gzip')
		preview(body)
		assert(headers.content_encoding == 'gzip')
	end

	local function test_chunked_transfer()
		local body, headers = getpage('http://www.httpwatch.com/httpgallery/chunked/')
		preview(body)
		assert(headers.transfer_encoding == 'chunked')
	end

	local function test_comp_gzip()
		local url = 'http://www.vervestudios.co/projects/compression-tests/static/js/test-libs/jquery.min.js?format=gzip'
		local body, headers = getpage(url)
		preview(body)
		assert(headers.content_encoding == 'gzip')
	end

	local function test_comp_deflate()
		local url = 'http://www.vervestudios.co/projects/compression-tests/static/js/test-libs/jquery.min.js?format=deflate'
		local body, headers = getpage(url)
		preview(body)
		assert(headers.content_encoding == 'deflate')
	end

	local function test_comp_zlib()
		do return end --we don't support zlib
		local url = 'http://www.vervestudios.co/projects/compression-tests/static/js/test-libs/jquery.min.js?format=zlib'
		local body, headers = getpage(url)
		preview(body)
		assert(headers.content_encoding == 'deflate')
	end

	local function test_auth()
		local body, headers = getpage{
			url = 'http://httpbin.org/basic-auth/user/pass',
			user = 'user',
			pass = 'pass',
		}
		preview(body)
		pp(headers)
		assert(body:match'"authenticated": true')
	end

	test_gzip()
	test_chunked_transfer()
	test_comp_gzip()
	test_comp_deflate()
	test_comp_zlib()
	test_auth()
end

loop.newthread(client)
loop.start()
