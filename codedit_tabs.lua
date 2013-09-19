--codedit tab expansion: translating between visual columns and real columns based on a fixed tabsize.
--real columns map 1:1 to char indices, while visual columns represent screen columns after tab expansion.
local editor = require'codedit_editor'
local str = require'codedit_str'

editor.tabsize = 3 --nil means autodetect.

--how many spaces from a visual column to the next tabstop, for a specific tabsize.
local function tabstop_distance(vcol, tabsize)
	return math.floor((vcol + tabsize) / tabsize) * tabsize - vcol
end

--real column -> visual column, for a fixed tabsize.
--the real column can be past string's end, in which case vcol will expand to the same amount.
local function visual_col(s, col, tabsize)
	local col1 = 0
	local vcol = 1
	for i in str.byte_indices(s) do
		col1 = col1 + 1
		if col1 >= col then
			return vcol
		end
		vcol = vcol + (str.istab(s, i) and tabstop_distance(vcol - 1, tabsize) or 1)
	end
	vcol = vcol + col - col1 - 1 --extend vcol past eol
	return vcol
end

--visual column -> real column, for a fixed tabsize.
--if the target vcol is between two possible vcols, return the vcol that is closer.
local function real_col(s, vcol, tabsize)
	local vcol1 = 1
	local col = 0
	for i in str.byte_indices(s) do
		col = col + 1
		local vcol2 = vcol1 + (str.istab(s, i) and tabstop_distance(vcol1 - 1, tabsize) or 1)
		if vcol >= vcol1 and vcol <= vcol2 then --vcol is between the current and the next vcol
			return col + (vcol - vcol1 > vcol2 - vcol and 1 or 0)
		end
		vcol1 = vcol2
	end
	col = col + vcol - vcol1 + 1 --extend col past eol
	return col
end

function editor:tabstop_distance(vcol)
	return tabstop_distance(vcol, self.tabsize)
end

function editor:visual_col(line, col)
	local s = self:getline(line)
	if s then
		return visual_col(s, col, self.tabsize)
	else
		return col --outside eof visual columns and real columns are the same
	end
end

function editor:real_col(line, vcol)
	local s = self:getline(line)
	if s then
		return real_col(s, vcol, self.tabsize)
	else
		return vcol --outside eof visual columns and real columns are the same
	end
end

--real col on a line, that is vertically aligned to the same real col on a different line
function editor:aligned_col(target_line, line, col)
	return self:real_col(target_line, self:visual_col(line, col))
end

