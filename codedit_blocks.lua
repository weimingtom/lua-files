--codedit text blocks
local editor = require'codedit_editor'

--line segment on a line, that intersects with the rectangle formed by (line1, col1) and (line2, col2)
function editor:block_cols(line, line1, col1, line2, col2)
	local col1 = self:aligned_col(line, line1, col1)
	local col2 = self:aligned_col(line, line2, col2)
	--the aligned columns could end up switched because the visual columns of col1 and col2 could be switched.
	if col1 > col2 then
		col1, col2 = col2, col1
	end
	--restrict columns to the available text
	local last_col = self:last_col(line)
	col1 = math.min(math.max(col1, 1), last_col + 1)
	col2 = math.min(math.max(col2, 1), last_col + 1)
	return col1, col2
end

--select the rectangular block between two subsequent positions in the text as a multi-line string
function editor:select_block(line1, col1, line2, col2)
	local lines = {}
	for line = line1, line2 do
		local tcol1, tcol2 = self:block_cols(line, line1, col1, line2, col2)
		table.insert(lines, self:sub(line, tcol1, tcol2))
	end
	return lines
end

--insert a multi-line string as a rectangular block at some position in the text. return the position after the string.
function editor:insert_block(line1, col1, s)
	local line = line1
	local line2, col2
	local vcol = self:visual_col(line1, col1)
	for _,s in str.lines(s) do
		local col = self:real_col(line, vcol)
		line2, col2 = self:insert_string(line, col, s)
		line = line + 1
	end
	return line2, col2
end

--remove the rectangular block between two subsequent positions in the text
function editor:remove_block(line1, col1, line2, col2)
	for line = line1, line2 do
		local tcol1, tcol2 = self:block_cols(line, line1, col1, line2, col2)
		self:remove_string(line, tcol1, line, tcol2)
	end
end

