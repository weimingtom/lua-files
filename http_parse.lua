--http protocol parsing from rfc-2616
local glue = require'glue'
local uri = require'uri'
local b64 = require'libb64'
local http_date = require'http_date'
local re = require'lpeg.re' --for tokens()

--request/response line parsers

local function request_line(s)
	local method, uri, version = s:match'^([^ ]+) ([^ ]+) HTTP/(%d+%.%d+)$'
	return method, uri, version
end

local function response_line(s)
	local version, status, message = s:match'^HTTP/(%d+%.%d+) (%d%d%d) ?(.*)$'
	status = tonumber(status)
	return status, message, version
end

--headers parser

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

--simple value parsers

function name(s) --Some-Name -> some_name
	return (s:gsub('%-','_'):lower())
end

local function int(s) --"123" -> 123
	s = tonumber(s)
	return s and math.floor(s) == s and s or nil
end

local function unquote(s)
	return (s:gsub('\\([^\\])', '%1'))
end

local function qstring(s) --'"a\"c"' -> 'a"c'
	s = s:match'^"(.-)"$'
	if not s then return end
	return unquote(s)
end

--simple compound value parsers (no comments or quoted strings involved)

local date = http_date.parse
local url = uri.parse

local function namesplit(s)
	return glue.gsplit(s,' ?, ?')
end

local function nameset(s) --"a,b" -> {a=true, b=true}
	local t = {}
	for s in namesplit(s) do
		t[name(s)] = true
	end
	return t
end

local function namelist(s) --"a,b" -> {'a','b'}
	local t = {}
	for s in namesplit(s) do
		t[#t+1] = name(s)
	end
	return t
end

local function etag(s) --[ "W/" ] quoted-string -> {etag = s, weak = true|false}
	local weak_etag = s:match'^W/(.*)$'
	return {
		etag = qstring(weak_etag or s),
		weak = weak_etag and true or false,
	}
end

--http://www.ietf.org/rfc/rfc2617.txt
local function credentials(s) --basic b64<user:password>
	local scheme,s = s:match'^([^ ]+) (.*)$'
	if not scheme then return end
	scheme = name(scheme)
	if scheme == 'basic' then
		local user,pass = b64.decode_string(s):match'^([^:]*):(.*)$'
		return {scheme = scheme, user = user, pass = pass}
	elseif scheme == 'digest' then
		--TODO:
	end
end

--tokenized compound value parsers

local value_re = re.compile([[
	value         <- (quoted_string / comment / separator / token)* -> {}
	quoted_string <- ('"' {(quoted_pair / [^"])*} '"') -> unquote
	comment       <- {'(' (quoted_pair / comment / [^()])* ')'}
	separator     <- {[]()<>@,;:\"/[?={}]} / ' '
	token         <- {(!separator .)+}
	quoted_pair   <- '\' .
]], {
	unquote = unquote,
})

local function tokens(s) -- a,b, "a,b" ; (a,b) -> {a,",",b,",","a,b",";","(a,b)"}
	return value_re:match(s)
end

local function tfind(t, s, start, stop) --tfind({a1,...}, aN) -> N
	for i=start or 1,stop or #t do
		if t[i] == s then return i end
	end
end

local function tsplit(t, sep, start, stop) --{a1,...,aX,sep,aY,...,aZ} -> f; f() -> t,1,X; f() -> t,Y,Z
	start = start or 1
	stop = stop or #t
	local i,next_i = start,start
	return function()
		repeat
			if next_i > stop then return end
			i, next_i = next_i, (tfind(t, sep, next_i, stop) or stop+1)+1
		until next_i-1 - i > 0 --skip empty values
		return t, i, next_i-2
	end
end

local function kv(t, parsers, i, j) --k[=[v]] -> name(k), v|true|''
	local k,eq,v = unpack(t,i,j)
	k = name(k)
	if eq ~= '=' then v = true end
	if not v then v = '' end --the existence of '=' implies an empty value
	if parsers and parsers[k] then v = parsers[k](v) end
	return k,v
end

local function kvlist(t, sep, parsers, i, j) --k1[=[v1]]<sep>... -> {k1=v1|true|'',...}
	local dt = {}
	for t,ii,jj in tsplit(t,sep,i,j) do
		local k,v = kv(t,parsers,ii,jj)
		dt[k] = v
	end
	return dt
end

local function propertylist(s, parsers) --k1[=[v1]],... -> {k1=v1|true|'',...}
	return kvlist(tokens(s), ',', parsers)
end

local function valueparams(t, parsers, i, j) --value[;paramlist] -> t,i,j, params
	i,j = i or 1, j or #t
	local ii = tfind(t,';',i,j)
	local j_before_params = ii and ii-1 or j
	local params = ii and kvlist(t, ';', parsers, ii+1, j)
	return t,i,j_before_params, params
end

local function valueparamslist(s, parsers) --value1[;paramlist1],... -> {value1=custom_t1|true,...}
	local split = tsplit(tokens(s), ',')
	return function()
		local t,i,j = split()
		if not t then return end
		return valueparams(t, parsers, i, j)
	end
end

--propertylist and valueparamslist value parsers: parse(string | true) -> value | nil
local function no_value(b) return b == true or nil end
local function opt_int(s) return s == true or int(s) end
local function must_int(s) return s ~= true and int(s) or nil end
local function opt_nameset(s) return s == true or nameset(s) end

--header value lazy parser

local parse = {} --{header_name = parser(s) -> v}

local function parse_header(k,v)
	if parse[k] then return parse[k](v) end
	return v
end

local function parsed_headers(s) --parsed_headers(s) -> t; t.header_name -> parsed_value
	local t = headers(s)
	return glue.cache(function(k)
		return t[k] and parse_header(k,t[k])
	end)
end

--header values per http section 14

local accept_parse = {q = tonumber}

function parse.accept(s) --#( type "/" subtype ( ";" token [ "=" ( token | quoted-string ) ] )* )
	local dt = {}
	for t,i,j, params in valueparamslist(s, accept_parse) do
		local type_, slash, subtype = unpack(t,i,j)
		if slash ~= '/' then return end
		type_ = name(type_)
		subtype = name(subtype)
		params = params or {}
		dt[string.format('%s/%s', type_, subtype)] = params
	end
	return dt
end

local function accept_list(s) ----1#( ( token | "*" ) [ ";" "q" "=" qvalue ] )
	local dt = {}
	for t,i,j, params in valueparamslist(s, accept_parse) do
		dt[name(t[i])] = params or true
	end
	return dt
end

parse.accept_charset = accept_list
parse.accept_encoding = accept_list
parse.accept_language = accept_list

function parse.accept_ranges(s) -- "none" | 1#( "bytes" | token )
	if s == 'none' then return {} end
	return nameset(s)
end

parse.accept_datetime = date
parse.age = int --seconds
parse.allow = nameset --#method
parse.authorization = credentials

local cc_parse = {
	no_cache = no_value,          --"no-cache"
	no_store = no_value,          --"no-store"
	max_age = must_int,           --"max-age" "=" delta-seconds
	max_stale = opt_int,          --"max-stale" [ "=" delta-seconds ]
	min_fresh = must_int,         --"min-fresh" "=" delta-seconds
	no_transform = no_value,      --"no-transform"
	only_if_cached = no_value,    --"only-if-cached"
	public = no_value,            --"public"
	private = opt_nameset,        --"private" [ "=" <"> 1#field-name <"> ]
	no_cache = opt_nameset,       --"no-cache" [ "=" <"> 1#field-name <"> ]
	no_store = no_value,          --"no-store"
	no_transform = no_value,      --"no-transform"
	must_transform = no_value,    --"must-transform"
	must_revalidate = no_value,   --"must-revalidate"
	proxy_revalidate = no_value,  --"proxy-revalidate"
	max_age = must_int,           --"max-age" "=" delta-seconds
	s_maxage = must_int,          --"s-maxage" "=" delta-seconds
}

function parse.cache_control(s)
	return propertylist(s, cc_parse)
end

parse.connection = nameset --1#(connection-token)
parse.content_encoding = namelist --1#(content-coding)
parse.content_language = nameset --1#(language-tag)
parse.content_length = int
parse.content_location = url

function parse.content_md5(s)
	return glue.tohex(b64.decode_string(s))
end

function parse.content_range(s) --bytes <from>-<to>/<total> -> {from=,to=,total=,size=}
	local from,to,total = s:match'bytes (%d+)%-(%d+)/(%d+)'
	local t = {}
	t.from = tonumber(from)
	t.to = tonumber(to)
	t.total = tonumber(total)
	if t.from and t.to then t.size = t.to - t.from + 1 end
	return t
end

function parse.content_type(s) --type "/" subtype *( ";" name "=" value )
	local t,i,j, params = valueparams(tokens(s))
	if t[i+1] ~= '/' then return end
	params = params or {}
	params.media_type = name(table.concat(t,'',i,j))
	return params
end

parse.date = date
parse.etag = etag

local expect_parse = {['100_continue'] = no_value}

function parse.expect(s) --1#( "100-continue" | ( token "=" ( token | quoted-string ) ) )
	return propertylist(s, expect_parse)
end

parse.expires = date
parse.from = nil --email-address

function parse.host(s) --host [ ":" port ]
	local host, port = s:match'^(.-) ?: ?(.*)$'
	if not host then
		host, port = s, 80
	else
		port = int(port)
		if not port then return end
	end
	host = host:lower()
	return {host = host, port = port}
end

local function etags(s) -- "*" | 1#( [ "W/" ] quoted-string )
	if s == '*' then return '*' end
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local weak,slash,etag = unpack(t,i,j)
		local is_weak = weak == 'W' and slash == '/'
		etag = is_weak and etag or weak
		dt[#dt+1] = {etag = etag, weak = is_weak}
	end
	return dt
end

parse.if_match = etags
parse.if_modified_since = date
parse.if_none_match = etags

function parse.if_range(s) -- etag | date
	local is_etag = s:match'^W/' or s:match'^"'
	return is_etag and etag(s) or date(s)
end

parse.if_unmodified_since = date
parse.last_modified = date
parse.location = url
parse.max_forwards = int

local pragma_parse = {no_cache = no_value}

function parse.pragma(s) -- 1#( "no-cache" | token [ "=" ( token | quoted-string ) ] )
	return propertylist(s, pragma_parse)
end

local challenges = nameset --TODO

parse.proxy_authenticate = challenges
parse.proxy_authorization = credentials

function parse.range(s) --bytes=<from>-<to> -> {from=,to=,size=}
	local from,to = s:match'bytes=(%d+)%-(%d+)'
	local t = {}
	t.from = tonumber(from)
	t.to = tonumber(to)
	if t.from and t.to then t.size = t.to - t.from + 1 end
	return t
end

parse.referer = url

function parse.retry_after(s) --date | seconds
	return int(s) or date(s)
end

function parse.server(s) --1*( ( token ["/" version] ) | comment )
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local product, slash, version = unpack(t,i,j)
		if slash == '/' then
			dt[name(product)] = version or true
		end
	end
	return dt
end

local te_parse = {trailers = no_value, q = int}

function parse.te(s) --#( "trailers" | ( transfer-extension [ accept-params ] ) )
	local dt = {}
	for t,i,j, params in valueparamslist(s, te_parse) do
		dt[name(t[i])] = params or true
	end
	return dt
end

parse.trailer = nameset --1#header-name

local trenc_parse = {chunked = no_value}

function parse.transfer_encoding(s) --1# ( "chunked" | token *( ";" name "=" ( token | quoted-string ) ) )
	local dt = {params = {}}
	for t,i,j, params in valueparamslist(s, trenc_parse) do
		local k = name(t[i])
		dt[#dt+1] = k
		dt.params[k] = params
	end
	return dt
end

function parse.upgrade(s) --1#product
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local protocol,slash,version = unpack(t,i,j)
		dt[name(protocol)] = version or true
	end
	return dt
end

parse.user_agent = string.lower --1*( product | comment )

function parse.vary(s) --( "*" | 1#field-name )
	if s == '*' then return '*' end
	return nameset(s)
end

--[[ TODO:
      Via =  "Via" ":" 1#( received-protocol received-by [ comment ] )
      received-protocol = [ protocol-name "/" ] protocol-version
      protocol-name     = token
      protocol-version  = token
      received-by       = ( host [ ":" port ] ) | pseudonym
      pseudonym         = token
]]
function parse.via(t) --1.0 fred 1.1 nowhere.com (apache/1.1)
	return t
end

function parse.warning(s) --1#(code ( ( host [ ":" port ] ) | pseudonym ) text [date])
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local code, host, port, message, date
		if t[i+2] == ':' then
			code, host, port, message, date = unpack(t,i,j)
		else
			code, host, message, date = unpack(t,i,j)
		end
		dt[#dt+1] = {code = int(code), host = host:lower(), port = int(port), message = message}
	end
	return dt
end

parse.www_authenticate = challenges



parse.cookie = nil --TODO: kv';'


--non-standard request headers

parse.x_requested_with = nil --xmlhttprequest
function parse.dnt(s) return s == '1' end --means "do not track"
parse.x_forwarded_for = nil --client1 proxy1 proxy2
parse.link = nil --?
parse.p3p = nil
parse.refresh = nil --TODO: seconds; ... (not standard but supported)
parse.set_cookie = nil
parse.strict_transport_security = nil --eg. max_age=16070400; includesubdomains
parse.x_Forwarded_proto = nil --https|http
parse.x_powered_by = nil --PHP/5.2.1
parse.content_disposition = nil --http extension; TODO



--body parsing

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

local function body(headers, readline, readchunks, readall)
	local decoders = glue.update({}, decoders)
	decoders.chunked = body_chunks(readline, readchunks)
	local source
	if headers.content_length then
		source = readchunks(headers.content_length)
	else
		source = readall()
	end
	source = pipeline(source, headers.transfer_encoding)
	source = pipeline(source, headers.content_encoding)
	return source
end


if not ... then require'http_parse_test' end

return {
	reqwest_line = request_line,
	response_line = response_line,
	headers = headers,
	parsed_headers = parsed_headers,
	header_parsers = parse,
	body = body,
}

