--http client supporting:
-- overriding specific parts of the url and headers, including specifying only the parts without the url.
-- accepting gzip and deflate for both content and transfer encodings and accepting trailers with chunked transfers.
-- sending a message body with the request, which can be either a string or a read function to get the bits.
-- using a proxy server.
-- basic authentication for end servers and for proxy servers.
-- redirecting on 3xx replies with redirect = true and limited with max_redirects, using an abs. or rel. Location header.
	--TODO: preserving the conn. if possible.
	--TODO: passing the Location header back as a hint we redirected
	--TODO: we can't redirect if we already used the source, so we report the error
-- TODO: ssl with or without cert. verification.
-- TODO: cookie jar: store cookies and give them back according to storage rules
-- TODO: keep-alive: reuse the connection for more requests
-- TODO: separate read and write threads: send request bursts and tie back replies to requests on the reply thread.
-- TODO: connection & thread pool: reuse connections.
-- TODO: digest authentication (proxy and endpoint).
-- TODO: override/specify path segments and query args.

local glue = require'glue'
local socketloop = require'socketloop_coro'
local socketreader = require'socketreader'
local http = require'http'
local uri = require'uri'
local b64 = require'libb64'.encode_string
local coro = require'coro'

local function request(t)
	local url = type(t) == 'string' and t or t.url
	local url = url and uri.parse(url)
	local t = type(t) ~= 'string' and t or nil
	local scheme = t and t.scheme or url and url.scheme or 'http'
	local ssl = scheme == 'https'
	local body = t and t.body
	local method = t and t.method or body and 'POST' or 'GET'
	local host = t and t.host or url and url.host
	local port = t and t.port or url and url.port or ssl and 443 or 80
	local user = t and t.user or url and url.user
	local pass = t and t.pass or url and url.pass
	local path = t and t.path or url and url.path
	local query = t and t.query or url and url.query
	local fragment = t and t.fragment or url and url.fragment
	local proxy_url = t and t.proxy_url and uri.parse(t.proxy_url)
	local proxy_scheme = t and t.proxy_scheme or proxy_url and proxy_url.scheme or 'http'
	local proxy_ssl = proxy_scheme == 'https'
	local proxy_host = t and t.proxy_host or proxy_url and proxy_url.host
	local proxy_port = t and t.proxy_port or proxy_url and proxy_url.port or proxy_ssl and 443 or 80
	local proxy_user = t and t.proxy_user or proxy_url and proxy_url.user
	local proxy_pass = t and t.proxy_pass or proxy_url and proxy_url.pass
	local request_host = host
	local request_uri
	if proxy_host then
		request_uri = uri.format{
			scheme = scheme,
			host = host,
			port = port,
			user = user,
			pass = pass,
			path = path,
			query = query,
		}
		host = proxy_host
		port = proxy_port
	else
		request_uri = uri.format{path = path, query = query}
	end
	local content_length = body and (t and t.content_length or type(body) == 'string' and #body or nil)
	local content_type = body and (t and t.content_type or 'application/x-www-form-urlencoded')
	local user_agent = t and t.user_agent or 'Mozilla/5.0'
	local accept_compression = not t or not t.disable_compression

	local headers = {}
	headers.host = request_host
	headers.connection = 'close,TE'
	headers.te = 'trailers' .. (accept_compression and ',gzip,deflate' or '')
	headers.accept_encoding = accept_compression and 'gzip,deflate' or nil
	headers.user_agent = user_agent
	headers.content_length = content_length
	headers.content_type = content_type
	if user and pass then
		headers.authorization = 'Basic ' .. b64(user .. ':' .. pass)
	end
	if proxy_user and proxy_pass then
		headers.proxy_authorization = 'Basic ' .. b64(proxy_user .. ':' .. proxy_pass)
	end
	glue.update(headers, t and t.headers)

	assert(host, 'invalid url/host')
	assert(not proxy_url or proxy_host, 'invalid proxy/proxy_host')

	return {
		host = host, port = port, ssl = ssl,
		method = method, uri = request_uri,
		headers = headers, body = body,
		options = t,
	}
end

local function getpage(t, connect)
	local t = request(t)
	assert(not t.ssl, 'ssl not supported')
	local api = connect(t.host, t.port)
	http.write_request_line(api.write, t.method, t.uri, '1.1')
	http.write_headers(api.write, t.headers)
	if t.headers.content_length then
		if type(t.body) == 'string' then
			api.write(t.body)
		else
			for s in t.body do
				api.write(s)
			end
		end
	elseif t.body then
		for s in t.body do
			http.write_chunk(api.write, s)
		end
		http.write_chunk(api.write, '')
		api.write('r\n')
	end

	local read_thread = coro.current
	return coro.create(function()
		local status, message, version = http.read_response_line(api.readline)
		local headers = {}
		while status == 100 do --ignore any 100-continue messages
			http.read_headers(api.readline, headers)
			status, message, version = http.read_response_line(api.readline)
		end
		http.read_headers(api.readline, headers)

		local should_receive_body =
			method ~= 'HEAD'
			and (status < 100 or status >= 200)
			and status ~= 204
			and status ~= 304

	   if t.redirect
			and (status == 301 or status == 302)
			and (method == 'GET' or method == 'HEAD')
		then
			local redirect_num = t.redirect_num or 0
			local max_redirects = t.max_redirects or 5
			local location = headers.location
			assert(redirect_num < max_redirects, 'too many redirects')
			assert(location, 'cannot redirect: location missing')
			--TODO: status == 303 or status == 307 or status == 308
			--TODO: location: rel. url to abs. url
			request = {
				url = location,
				method = method,
				proxy_url = proxy_url,
				proxy_host = proxy_host,
				proxy_port = proxy_port,
				proxy_user = proxy_user,
				proxy_pass = proxy_pass,
				redirect_num = redirect_num + 1,
			}
			return http_request(request, connect)
		end

		coro.transfer(read_thread, headers)

		for s in http.body_reader(api.readline, api.readsize, api.readall, headers) do
			coro.transfer(read_thread, s)
		end
	end)
end

if not ... then require'http_client_test' end

return {
	request = request,
	getpage = getpage,
}

