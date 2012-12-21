--http parsing for known headers

local glue = require'glue'
local httpdate = require'httpdate'
local uri = require'uri'
local b64 = require'libb64'

local function unfold(v) return glue.collect(v:gsplit' *%, *') end
local function ci(v) return v:asciilower() end
local function cilist(v) return unfold(v:asciilower()) end
local function int(v) v = tonumber(v) return v and math.floor(v) end
local function url(v) return uri.parse(v) end
local function base64(v) return base64.decode_string(v) end
local function headernames(v) return filter(httpclient.parseheadername, unfold(v)) end

--k1=v1,... -> {k1=v1,...}
local function kv(v)
	local t = {}
	for i=1,#v do
		local k,v = v[i]:match'([^=]*)=?(.*)'
		if k ~= '' or v ~= '' then
			t[k:asciilower()] = v
		end
	end
	return t
end

--name[; k1=v1 ...] -> {name,k1=v1,...}
local function params(known)
	return function(v)
		local t = {}
		local value, rest = v[#v]:match'([^;]*);?(.*)'
		t[1] = value:asciilower()
		for param in rest:gsplit' ' do
			local k,v = param:match'([^=]*)=?(.*)'
			k = k:asciilower()
			t[k] = known[k] and known[k](k,{v}) or v
		end
		return t
	end
end

--bytes=<from>-<to> -> {from=,to=,size=}
local function request_range(v)
	local from,to = v:match'bytes=(%d+)%-(%d+)'
	local t = {
		from = tonumber(from),
		to = tonumber(to),
	}
	if t.from and t.to then t.size = t.to - t.from + 1 end
	return t
end

--bytes <from>-<to>/<total> -> {from=,to=,total=,size=}
local function response_range(v)
	local from,to,total = v:match'bytes (%d+)%-(%d+)/(%d+)'
	local t = {
		from = tonumber(from),
		to = tonumber(to),
		total = tonumber(total),
	}
	if t.from and t.to then t.size = t.to - t.from + 1 end
	return t
end

--cookies
local function cookies(v)
	return t
end

local parsers = {
	--general header fields
	--cache_control = kv, --no_cache
	connection = ci,
	content_length = int,
	content_md5 = base64,
	content_type = params{charset = ci}, --text/html; charset=iso-8859-1
	date = httpdate,
	pragma = nil, --cilist?
	trailer = headernames,
	transfer_encoding = cilist,
	upgrade = nil, --http/2.0, shttp/1.3, irc/6.9, rta/x11
	via = nil, --1.0 fred, 1.1 nowhere.com (apache/1.1)
	warning = nil, --list of '(%d%d%d) (.-) (.-) ?(.*)' --code agent text[ date]
	--standard request headers
	accept = cilist, --paramslist?
	accept_charset = cilist,
	accept_encoding = cilist,
	accept_language = cilist,
	authorization = ci, --basic <password>
	cookie = kv, --TODO: kv';',
	expect = cilist, --100-continue
	from = nil, --user@example.com
	host = nil,
	if_match = nil, --<etag>
	if_modified_since = date,
	if_none_match = nil, --etag
	if_range = nil, --etag
	if_unmodified_since	= date,
	max_forwards = int,
	proxy_authorization = nil, --basic <password>
	range = request_range, --bytes=500_999
	referer = nil, --it's an url but why parse it
	te = cilist, --"trailers, deflate"
	user_agent = nil, --mozilla/5.0 (compatible; msie 9.0; windows nt 6.1; wow64; trident/5.0)
	--non-standard request headers
	x_requested_with = ci,--xmlhttprequest
	dnt = function(v) return v[#v]=='1' end, --means "do not track"
	x_forwarded_for = nil, --client1, proxy1, proxy2
	--standard response headers
	accept_ranges = ci, --"bytes"
	age = int, --seconds
	allow = cilist, --method
	content_disposition = params{filename = nil}, --attachment; ...
	content_encoding = ci,
	content_language = cilist,
	content_location = url,
	content_range = response_range, --bytes 0-500/1250
	etag = nil,
	expires = date,
	last_modified = date,
	link = nil, --?
	location = url,
	p3p = nil,
	proxy_authenticate = ci, --basic
	refresh = params{url = url}, --seconds; ... (not standard but supported)
	retry_after = int, --seconds
	server = nil,
	set_cookie = cookies,
	strict_transport_security = nil, --eg. max_age=16070400; includesubdomains
	vary = headernames,
	www_authenticate = ci,
	--non-standard response headers
	x_Forwarded_proto = ci, --https|http
	x_powered_by = nil, --PHP/5.2.1
}

local function parse(k,v)
	local pv = headerparsers[k] and headerparsers[k](v) or v
	return assert(pv, 'invalid value "%s" for header "%s"', v, h)
end

return parse
