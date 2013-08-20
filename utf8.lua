--utf8 basics by Cosmin Apreutesei (unlicensed).
--byte indices are i's, char (codepoint) indices are ci's.
--invalid characters are counted as 1-byte chars so they don't get lost. validate/sanitize beforehand as needed,
--or reassign utf8.next to utf8.next_valid to change the behavior of the entire module to skip on invalid indices:
--   local utf8 = require'utf8'
--   utf8 = glue.update({utf8.next = utf8.next_valid}, utf8)

local str = {}

--byte index of the next char after the char at byte index i, followed by a isvalid flag.
--nil if indices go out of range. invalid characters are iterated as 1-byte chars.
function str.next_raw(s, i)
	if not i then
		return #s > 0 and 1 or nil
	end
	if i > #s then return end
	local c = s:byte(i)
	if c >= 0 and c <= 127 then
		i = i + 1
	elseif c >= 194 and c <= 223 then
		i = i + 2
	elseif c >= 224 and c <= 239 then
		i = i + 3
	elseif c >= 240 and c <= 244 then
		i = i + 4
	else --invalid
		return i + 1, false
	end
	if i > #s then return end
	return i, true
end

--next() is the generic iterator and can be replaced for different semantics. next_raw() must preserve its semantics.
str.next = str.next_raw

--iterate chars, returning the byte index where each char starts
function str.byte_indices(s, lasti)
	return str.next, s, lasti
end

--number of chars in string
function str.len(s)
	local len = 0
	for _ in str.byte_indices(s) do
		len = len + 1
	end
	return len
end

--byte index given char index. 0 if the index is < 0, #s + 1 if the index is outside the string.
function str.byte_index(s, target_ci)
	if target_ci < 1 then return 0 end
	local ci = 1
	for i in str.byte_indices(s) do
		if ci == target_ci then
			return i
		end
		ci = ci + 1
	end
	return #s + 1
end

--char index given byte index. 0 if the index is < 0, char index at #s + 1 if the index is outside the string.
function str.char_index(s, target_i)
	if target_i < 1 then return 0 end
	local ci = 1
	for i in str.byte_indices(s) do
		if i == target_i then
			break
		end
		ci = ci + 1
	end
	return ci
end

--byte index of the prev. char before the char at byte index i
function str.prev(s, i)
	if i == 1 then return end
	local lasti = 1
	for j in str.byte_indices(s) do
		if j >= i then
			break
		end
		lasti = j
	end
	return lasti
end

--sub based on char indices (which can't be negative)
function str.sub(s, start_ci, end_ci)
	assert(start_ci >= 1)
	assert(not end_ci or end_ci >= 0)
	if end_ci and end_ci < start_ci then
		return ''
	end
	local ci = 0
	local start_i, end_i
	for i in str.byte_indices(s) do
		ci = ci + 1
		if ci == start_ci then
			start_i = i
		end
		if ci == end_ci then
			end_i = i
		end
	end
	if not start_i then return '' end
	return s:sub(start_i, end_i)
end

--check if a string contains a substring at byte index i
function str.contains(s, i, sub)
	if i > #s then return false end
	for si = 1, #sub do
		if s:byte(i + si - 1) ~= sub:byte(si) then
			return false
		end
	end
	return true
end

--count the number of occurences of a substring in a string
function str.count(s, sub)
	assert(#sub > 0)
	local count = 0
	local i = 1
	while i do
		if str.contains(s, i, sub) then
			count = count + 1
			i = i + #sub
			if i > #s then i = nil end
		else
			i = str.next(s, i)
		end
	end
	return count
end

--like string.find() but does not support anchors and only returns the byte indexs.
--the pattern should start with the '^' anchor.
function str.find(s, sub, start_ci, plain)
	start_ci = start_ci or 1
	for i in str.byte_indices(s) do
		if i >= start_ci then
			if plain then
				if str.contains(s, i, sub) then
					return i
				end
			elseif s:find(sub, i) == i then
				return i
			end
		end
	end
end

--utf8 validation and sanitization

--check if there's a valid utf8 codepoint at byte index i
function str.isvalid(s, i)
	local c = s:byte(i)
	if not c then
		return false
	elseif c >= 0 and c <= 127 then --UTF8-1
		return true
	elseif c >= 194 and c <= 223 then --UTF8-2
		local c2 = s:byte(i + 1)
		return c2 and c2 >= 128 and c2 <= 191
	elseif c >= 224 and c <= 239 then --UTF8-3
		local c2 = s:byte(i + 1)
		local c3 = s:byte(i + 2)
		return c2 and c3 and
			((c == 224 and c2 >= 160 and c2 <= 191) or
			 (c == 237 and c2 >= 128 and c2 <= 159) or
			 (c2 >= 128 and c2 <= 191))
			 and c3 >= 128 and c3 <= 191
	elseif c >= 240 and c <= 244 then --UTF8-4
		local c2 = s:byte(i + 1)
		local c3 = s:byte(i + 2)
		local c4 = s:byte(i + 3)
		return c2 and c3 and c4 and
			((c == 240 and c2 >= 144 and c2 <= 191) or
			 (c == 244 and c2 >= 128 and c2 <= 143) or
			 (c2 >= 128 and c2 <= 191))
			 and c3 >= 128 and c3 <= 191
			 and c4 >= 128 and c4 <= 191
	else
		return false
	end
end

--byte index of the next valid utf8 char after the char at byte index i.
--nil if indices go out of range. invalid characters are skipped.
function str.next_valid(s, i)
	local valid
	i, valid = str.next_raw(s, i)
	while i and (not valid or not str.isvalid(s, i)) do
		i, valid = str.next(s, i)
	end
	return i
end

--iterate valid chars, returning the byte index where each char starts
function str.valid_byte_indices(s, lasti)
	return str.next_valid, s, lasti
end

--assert that a string only contains valid utf8 characters
function str.validate(s)
	for i, valid in str.byte_indices(s) do
		if not valid or not str.isvalid(s, i) then
			error(string.format('invalid utf8 char at #%d', i))
		end
	end
end


--TODO from here ---------------------------------------------------------------------------------------------------------

--replace characters in string based on a function f(s, i) -> replacement_string | nil
function str.replace(s, f)
	--
end

--change invalid utf8 chars with a replacement char
function str.sanitize(s, repl_char)
	--TODO: finish this (make replacing generic in str.replace)
	repl_char = repl_char or '�' --\uFFFD
	local t
	local firsti, lasti = 1, 0
	local i = 1
	repeat
		if not str.isvalid(s, i) then
			t = t or {}
			t[#t+1] = s:sub(firsti, lasti)
		end

		lasti = i
		i = str.next(s, i)
	until not i
	return t and table.concat(t) or s
end

--escape ascii control characters as \xXX and non-ascii utf8 characters to \uXXXX
--to escape using only \xXX or \ddd use a pretty printing library.
function str.escape(s)
    --TODO
	 if ord == nil then return nil end
    if ord < 32 then return string.format('\\x%02x', ord) end
    if ord < 126 then return string.char(ord) end
    if ord < 65539 then return string.format("\\u%04x", ord) end
    if ord < 1114111 then return string.format("\\u%08x", ord) end
end

--unescape \xXX and \uXXXX
function str.unescape(s)
	--TODO
end

function str.upper(s)
	--TODO
end

function str.lower(s)
	--TODO
end

if not ... then require 'utf8_test' end

return str

