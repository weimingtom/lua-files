--string module for codedit by Cosmin Apreutesei (unlicensed).
--based on utf8 library, deals specifically with tabs, spaces, lines and words.
local utf8 = require'utf8'
local glue = require'glue'

local str = glue.update({}, utf8)

--tabs and whitespace ----------------------------------------------------------------------------------------------------

--check for an ascii char at a byte index without string creation
function str.isascii(s, i, c)
	return s:byte(i) == c:byte(1)
end

--check if the char at byte index i is a tab
function str.istab(s, i)
	return str.isascii(s, i, '\t')
end

--check if the char at byte index i is a space of any kind
function str.isspace(s, i)
	return str.isascii(s, i, ' ') or str.istab(s, i)
end

--byte index followed by char index of the first occurence of a non-space char (#s + 1 if none).
function str.first_nonspace(s)
	local n = 1
	for i in str.byte_indices(s) do
		if not str.isspace(s, i) then
			return i, n
		end
		n = n + 1
	end
	return #s + 1, n
end

--byte index of the last occurence of a non-space char.
function str.last_nonspace(s)
	local space_starts
	for i in str.byte_indices(s) do
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
	return s:sub(1, (str.last_nonspace(s)))
end

--number of tabs and of spaces in indentation
function str.indent_counts(s)
	local tabs, spaces = 0, 0
	for i in str.byte_indices(s) do
		if str.istab(s, i) then
			tabs = tabs + 1
		elseif str.isspace(s, i) then
			spaces = spaces + 1
		else
			break
		end
	end
	return tabs, spaces
end

--lines ------------------------------------------------------------------------------------------------------------------

--return the index where the next line starts (unimportant) and the indices of the line starting at a given index.
--the last line is the substring after the last line terminator to the end of the string (see tests).
function str.next_line_indices(s, i)
	i = i or 1
	if i == #s + 1 then --string ended with newline, or string is empty: iterate one more empty line
		return 1/0, i, i-1
	elseif i > #s then
		return
	end
	local j, next_i = s:match('^[^\r\n]*()\r?\n?()', i)
	if next_i > #s and j == next_i then --string ends without a newline, mark that by setting next_i to inf
		next_i = 1/0
	end
	return next_i, i, j-1
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

--words ------------------------------------------------------------------------------------------------------------------

function str.isword(s, i, word_chars)
	return s:find(word_chars, i) ~= nil
end

--find either:
	--1) 1..n spaces followed by a non-space
	--2) 1..n words or non-words follwed by 0..n spaces followed by a non-space
function str.next_word_break(s, start, word_chars)
	local expect = str.isspace(s, start) and 'space' or str.isword(s, start, word_chars) and 'word' or 'nonword'
	for i in str.byte_indices(s, start) do
		if expect == 'space' then
			if not str.isspace(s, i) then
				return i
			end
		elseif str.isspace(s, i) then
			expect = 'space'
		elseif expect ~= (str.isword(s, i, word_chars) and 'word' or 'nonword') then
			return i
		end
	end
end

--find backwards either:
	--1) 0..1 words or non-words followed by 1..n spaces followed by 0..n words or non-words
	--3) 2..n words or non-words
function str.prev_word_break(s, start, word_chars)
	local expect = str.isspace(s, start) and 'space' or str.isword(s, start, word_chars) and 'word' or 'nonword'
	local lasti = start
	for i in str.byte_indices_reverse(s, start) do
		if expect == 'space' then
			if not str.isspace(s, i) then
				expect = str.isword(s, i, word_chars) and 'word' or 'nonword'
			end
		elseif expect ~= (str.isspace(s, i) and 'space' or str.isword(s, i, word_chars) and 'word' or 'nonword') then
			if lasti == start then
				expect =
					str.isspace(s, i) and 'space' or
					str.isword(s, i, word_chars) and 'word' or 'nonword'
			else
				return lasti
			end
		end
		lasti = i
	end
	return lasti
end


--tests ------------------------------------------------------------------------------------------------------------------

if not ... then

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
	local dt = {}
	for _,s in str.lines(s) do
		i = i + 1
		assert(t[i] == s, i .. ': "' .. s .. '" ~= "' .. tostring(t[i]) .. '"')
		dt[i] = s
	end
	assert(i == #t, i .. ' ~= ' .. #t .. ': ' .. table.concat(dt, ', '))
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

--TODO: next_word_break, prev_word_break

end


if not ... then require'codedit_demo' end

return str

