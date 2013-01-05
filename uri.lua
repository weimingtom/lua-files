local glue = require'glue'

--vocabulary

local function sortedpairs(t)
	local st = {}
	for k,v in pairs(t) do st[k] = v end
	table.sort(st)
	return pairs(st)
end

--formatting

--escape all characters except `unreserved`, `sub-delims` and the characters
--in the unreserved list, plus the characters in the reserved list
local function escape(s, reserved, unreserved)
	local function esc(c)
		return ('%%%02x'):format(c:byte())
	end
	s = s:gsub('[^A-Za-z0-9%-%._~!%$&\'%(%)%*%+,;=' .. (unreserved or '').. ']', esc)
	if reserved and reserved ~= '' then
		s = s:gsub('[' .. reserved .. ']', esc)
	end
	return s
end

local function format_args(t)
	local dt = {}
	for k,v in sortedpairs(t) do --order is not significant
		k = k:gsub(' ', '+')
		v = v:gsub(' ', '+')
		dt[#dt+1] = escape(k, '&=') .. '=' .. escape(v, '&')
	end
	return table.concat(dt, '&')
end

local function format_segments(t)
	local dt = {}
	for i=1,#t do
		dt[#dt+1] = escape(t[i], '/')
	end
	return table.concat(dt, '/')
end

--args override query; segments override path
local function format(t)
	local scheme = (t.scheme and escape(t.scheme) .. ':' or '')
	local pass = t.pass and ':' .. escape(t.pass) or ''
	local user = t.user and escape(t.user) .. pass .. '@' or ''
	local port = t.port and ':' .. escape(t.port) or ''
	local host = t.host and '//' .. user .. escape(t.host) .. port or ''
	local path = t.segments and format_segments(t.segments) or
						t.path and escape(t.path, '', '/') or ''
	local query = t.args and '?' .. format_args(t.args) or
						t.query and '?' .. escape((t.query:gsub(' ', '+'))) or ''
	local fragment = t.fragment and '#' .. escape(t.fragment) or ''
	return scheme .. host .. path .. query .. fragment
end

--parsing

local function unescape(s)
	return (s:gsub('%%(%x%x)', function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

--[segment[/segment...]]
local function parsepath(s)
	local t = {}
	for s in glue.gsplit(s, '/') do
		t[#t+1] = unescape(s)
	end
	return t
end

--var[=[val]]&|;...
--argument order is not retained neither are the values of duplicate keys
local function parsequery(s)
	local t = {}
	for s in glue.gsplit(s, '[&;]+') do
		local k,v = s:match'^([^=]*)=?(.*)$'
		k = unescape(k:gsub('+', ' '))
		v = unescape(v:gsub('+', ' '))
		if k ~= '' or v ~= '' then
			t[k] = v
		end
	end
	return t
end

--[scheme:](([//[user[:pass]@]host[:port][/path])|path)[?query][#fragment]
local function parse(s, t)
	t = t or {}
	s = s:gsub('#(.*)', function(s) t.fragment = unescape(s) return '' end)
	s = s:gsub('%?(.*)', function(s)
		t.query = unescape(s) --convenience field: unusable if args names/values contain & or =
		t.args = parsequery(s)
		return ''
	end)
	s = s:gsub('^([a-zA-Z%+%-%.]*):', function(s) t.scheme = unescape(s) return '' end)
	s = s:gsub('^//([^/]*)', function(s) t.host = unescape(s) return '' end)
	if t.host then
		t.host = t.host:gsub('^(.-)@', function(s) t.user = unescape(s) return '' end)
		t.host = t.host:gsub(':(.*)', function(s) t.port = unescape(s) return '' end)
		if t.user then
			t.user = t.user:gsub(':(.*)', function(s) t.pass = unescape(s) return '' end)
		end
	end
	if s ~= '' then
		t.segments = parsepath(s)
		t.path = unescape(s) --convenience field: unusable if path segments contain /
	end
	return t
end

if not ... then require 'uri_test' end

return {
	escape = escape,
	format = format,
	unescape = unescape,
	parse = parse,
}
