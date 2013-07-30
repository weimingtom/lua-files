--codedit: delimiting the lines and translating between virtual and real column numbers.
local lines = {}

--given a string and an index where a line begins, return that index plus the index of the last character in that line,
--excluding the line terminator, plus the index where the next line begins.
function lines.next(s, i)
	i = i or 1
	if i > #s then return end
	local j, nexti = s:find('\r?\n', i)
	if j then
		return nexti + 1, i, j - 1
	else
		return #s + 1, i, #s
	end
end

--line iterator<next_i, i, j> where i, j are the indices of the first and last character of the contents of the line.
--the last line may or may not end with a line terminator, it is included nevertheless.
function lines.lines(s, i)
	return lines.next, s
end

--given a line number, return the indices of the first and last character of the line.
--if line number is out of range, it is adjusted to fit the range of available lines.
function lines.pos(s, lnum)
	lnum = math.max(lnum, 1)
	local i, j, n = 1, 0, 0
	for _, i1, j1 in lines.lines(s) do
		n = n + 1
		i, j = i1, j1
		if n == lnum then break end
	end
	n = math.max(n, 1)
	return i, j, n
end

--count the tabs in the substring between two string indices (inclusive).
local function count_tabs(s, i, j)
	local n = 0
	while i <= j do
		i = s:find('\t', i, true)
		if not i or i > j then break end
		n = n + 1
		i = i + 1
	end
	return n
end

--given a physical cnum (column number) and tabsize, return the corresponding visual cnum.
function lines.view_cnum(s, i, j, cnum, tabsize)
	--local i, j = lines.pos(s, lnum)
	local max_cnum = math.min(cnum, j - i + 1)
	return count_tabs(s, i, i + max_cnum - 2) * (tabsize - 1) + cnum
end

--given a visual cnum and tabsize, return the corresponding physical cnum.
--if the visual cnum is over an expanded tab character, return the position on or after the tab, whichever is closer.
function lines.file_cnum(s, i, j, vcnum, tabsize)
	vcnum = math.max(vcnum, 1)
	--local i, j = lines.pos(s, lnum)
	local vcnum1 = 1
	local cnum = 0
	for i = i, j do
		cnum = cnum + 1
		local vcnum2 = vcnum1 + (s:byte(i) == 9 and tabsize or 1)
		if vcnum >= vcnum1 and vcnum <= vcnum2 then --vcnum is between the current and the next vcnum
			return cnum + (vcnum - vcnum1 > vcnum2 - vcnum and 1 or 0)
		end
		vcnum1 = vcnum2
	end
	return cnum + vcnum - vcnum1 + 1
end

if not ... then

require'unit'

test({lines.pos('', 5)}, {1, 0, 1})
test({lines.pos('', -5)}, {1, 0, 1})
test({lines.pos('x', 5)}, {1, 1, 1})
test({lines.pos('\nx', 5)}, {2, 2, 2})
test({lines.pos('\nabc\ndef\n', 3)}, {6, 8, 3})

test(count_tabs('abc', 1, 5), 0)
test(count_tabs('\t\tx', 1, 0), 0)
test(count_tabs('\t\tx', 2, 2), 1)
test(count_tabs('\t\tx', 1, 3), 2)

for cnum,vcnum in ipairs{1,4,5,8} do
	test(lines.view_cnum('\n\tA\tB', 2, cnum, 3), vcnum)
end

--tAtB (1234) -> sssAsssB (11123334 / 12345678) -> 112233445 + 6789...
for vcnum,cnum in ipairs{1,1,2,2,3,3,4,4,5,6,7,8,9} do
	test(lines.file_cnum('\n\tA\tB', 2, vcnum, 3), cnum)
end
--require'codedit_demo'

end

return lines
