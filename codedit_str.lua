--utf8 string API for codedit.
--TODO: reimplement next() for utf8.
local str = {}

--byte index of the next char after the char at byte index i
function str.next(s, i)
	i = i and i + 1 or 1
	if i > #s then return end
	return i
end

--iterate chars, returning the byte index where each char starts
function str.indices(s)
	return str.next, s
end

--number of chars in string
function str.len(s)
	local len = 0
	for _ in str.indices(s) do
		len = len + 1
	end
	return len
end

--sub based on char indices (also, i and j can't be negative)
function str.sub(s, start_ci, end_ci)
	assert(start_ci >= 1)
	assert(not end_ci or end_ci >= 0)
	if end_ci == 0 then return '' end
	local ci = 0
	local start_i, end_i
	for i in str.indices(s) do
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

--check for an ascii char at a byte index without string creation
function str.ischar(s, i, c)
	return s:byte(i) == c:byte(1)
end

--check if the char at byte index i is a tab
function str.istab(s, i)
	return str.ischar(s, i, '\t')
end

--check if the char at byte index i is a space of any kind
function str.isspace(s, i)
	return str.ischar(s, i, ' ') or str.istab(s, i)
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

--like string.find() but does not support anchors and only returns the byte index
function str.find(s, sub, start_ci, plain)
	start_ci = start_ci or 1
	for i in str.indices(s) do
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

--first occurence of a non-space char (#s + 1 if none); returns the byte index followed by the char index
function str.first_nonspace(s)
	local n = 1
	for i in str.indices(s) do
		if not str.isspace(s, i) then
			return i, n
		end
		n = n + 1
	end
	return #s + 1, n
end

--last occurence of a non-space char (0 if none); returns byte index
function str.last_nonspace(s)
	local space_starts
	for i in str.indices(s) do
		if str.isspace(s, i) then
			space_starts = space_starts or i
		else
			space_starts = nil
		end
	end
	return space_starts and space_starts - 1 or #s
end

--right trim of space and tab characters
function str.rtrim(s)
	return s:sub(1, str.last_nonspace(s))
end

--return the index where the next line starts (unimportant) and the indices of the line starting at a given index.
--the last line is the substring after the last line terminator to the end of the string (see tests).
function str.next_line_indices(s, i)
	i = i or 1
	if i == #s + 1 then
		return #s + 2, #s + 1, #s
	end
	if i > #s then
		return
	end
	local rni = s:find('\r\n', i, true) or #s + 2
	local ni = s:find('\n', i, true) or #s + 2
	local ri = s:find('\r', i, true) or #s + 2
	local j = math.min(rni, ni, ri) - 1
	local next_i = math.min(rni + 2, ni + 1, ri + 1 + (ri == rni and 1 or 0))
	return next_i, i, j
end

--iterate lines, returning the index where the next line starts (unimportant) and the indices of each line
function str.line_indices(s)
	return str.next_line_indices, s
end

--return the index where the next line starts (unimportant) and the contents of the line starting at a given index.
--the last line is the substring after the last line terminator to the end of the string (see tests).
function str.next_line(s, i)
	local _, i, j = str.next_line_indices(s, i)
	if not _ then return end
	return _, s:sub(i, j)
end

--iterate lines, returning the index where the next line starts (unimportant) and the contents of each line
function str.lines(s)
	return str.next_line, s
end

function str.line_count(s)
	local count = 0
	for _ in str.line_indices(s) do
		count = count + 1
	end
	return count
end

--byte index given char index
function str.byte_index(s, n0)
	if n0 < 1 then return 0 end
	local n = 1
	for i in str.indices(s) do
		if n == n0 then
			return i
		end
		n = n + 1
	end
	return #s + 1
end

--char index given byte index
function str.char_index(s, i0)
	if i0 < 1 then return 0 end
	local n = 1
	for i in str.indices(s) do
		if i == i0 then
			break
		end
		n = n + 1
	end
	return n
end

--byte index of the prev. char before the char at byte index i
function str.prev(s, i)
	if i == 1 then return end
	local lasti = 1
	for j in str.indices(s) do
		if j >= i then
			break
		end
		lasti = j
	end
	return lasti
end

function str.isword(s, i, word_chars)
	return s:find(word_chars, i) ~= nil
end

function str.next_word_break(s, start, word_chars)
	local isword = str.isword(s, start, word_chars)
	for i in str.next, s, start do
		if isword and str.isspace(s, i) then
			isword = false
		end
		if isword ~= str.isword(s, i, word_chars) then
			return i
		end
	end
	return #s + 1
end

function str.prev_word_break(s, start, word_chars)
	local prev = str.prev(s, start)
	if not prev then return 0 end
	local isword = str.isword(s, prev, word_chars)
	local skipspace = str.isspace(s, prev)
	if skipspace then
		isword = true
	end
	while true do
		local prev1 = str.prev(s, prev)
		if not prev1 then break end
		if skipspace and str.isspace(s, prev1) then
			--nothing
		elseif isword ~= str.isword(s, prev1, word_chars) then
			return prev
		end
		prev = prev1
	end
	return 0
end


if not ... then

assert(str.next('') == nil)
assert(str.next('a') == 1)
assert(str.next('ab', 1) == 2)
assert(str.next('ab', 2) == nil)

assert(str.len('') == 0)
assert(str.len('a') == 1)
assert(str.len('ab') == 2)

assert(str.sub('abc', 1, 2) == 'ab')
assert(str.sub('abc', 2, 5) == 'bc')
assert(str.sub('abc', 2, 0) == '')
assert(str.sub('abc', 2, 1) == '')
assert(str.sub('abc', 3, 3) == 'c')

assert(str.contains('abcde', 3, 'cd') == true)
assert(str.contains('abcde', 2, '') == true)
assert(str.contains('abcde', 7, '') == false)

assert(str.find('abcde', 'cd') == 3)
assert(str.find('abcde', '') == 1)

assert(str.find(' \t abc', '^[^\t ]') == 4)

assert(str.count('\n\r \n \r \r\n \n\r', '\n\r') == 2)
assert(str.count('', 'x') == 0)

assert(str.first_nonspace('') == 1)
assert(str.first_nonspace(' ') == 2)
assert(str.first_nonspace(' x') == 2)
assert(str.first_nonspace(' x ') == 2)
assert(str.first_nonspace('x ') == 1)

assert(str.last_nonspace('') == 0)
assert(str.last_nonspace(' ') == 0)
assert(str.last_nonspace('x') == 1)
assert(str.last_nonspace('x ') == 1)
assert(str.last_nonspace(' x ') == 2)

assert(str.rtrim('abc \t ') == 'abc')
assert(str.rtrim(' \t abc  x \t ') == ' \t abc  x')
assert(str.rtrim('abc') == 'abc')

local function assert_lines(s, t)
	local i = 0
	for _,s in str.lines(s) do
		i = i + 1
		assert(t[i] == s, i .. ': "' .. s .. '" ~= "' .. tostring(t[i]) .. '"')
	end
	assert(i == #t)
end
assert_lines('', {''})
assert_lines(' ', {' '})
assert_lines('x\ny', {'x', 'y'})
assert_lines('x\ny\n', {'x', 'y', ''})
assert_lines('x\n\ny', {'x', '', 'y'})
assert_lines('\n', {'', ''})
assert_lines('\n\r\n', {'','',''})
assert_lines('\r\n\n', {'','',''})
assert_lines('\n\r', {'','',''})
assert_lines('\n\r\n\r', {'','','',''})
assert_lines('\n\n\r', {'','','',''})

assert(str.line_count('') == 1)
assert(str.line_count('\n\n\r') == 4)

end


return str
