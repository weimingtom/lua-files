--codedit position-based interface to its internal line buffer
local editor = require'codedit_editor'
local str = require'codedit_str'

function editor:last_col(line)
	return str.len(self:getline(line))
end

function editor:indent_col(line)
	return select(2, str.first_nonspace(self:getline(line)))
end

function editor:isempty(line)
	return str.first_nonspace(self:getline(line)) > #self:getline(line)
end

function editor:sub(line, col1, col2)
	return str.sub(self:getline(line), col1, col2)
end

--extend the buffer up to (line,col-1) so we can edit there.
function editor:extend(line, col)
	while line > self:last_line() do
		self:insert_line(self:last_line() + 1, '')
	end
	local last_col = self:last_col(line)
	if col > last_col + 1 then
		self:setline(line, self:getline(line) .. string.rep(' ', col - last_col - 1))
	end
end

--insert a multiline string at a specific position in the text, returning the position after the last character.
function editor:insert_string(line, col, s)
	self:extend(line, col)
	local s1 = self:sub(line, 1, col - 1)
	local s2 = self:sub(line, col)
	s = s1 .. s .. s2
	local first_line = true
	for _,s in str.lines(s) do
		if first_line then
			self:setline(line, s)
			first_line = false
		else
			line = line + 1
			self:insert_line(line, s)
		end
	end
	return line, self:last_col(line) - #s2 + 1
end

--remove the string between two subsequent positions in the text.
--line2,col2 is the position right after (not of!) the last character to be removed.
function editor:remove_string(line1, col1, line2, col2)
	local s1 = self:sub(line1, 1, col1 - 1)
	local s2 = self:sub(line2, col2)
	for line = line2, line1 + 1, -1 do
		self:remove_line(line)
	end
	self:setline(line1, s1 .. s2)
end

--select the string between two subsequent positions in the text
function editor:select_string(line1, col1, line2, col2)
	local lines = {}
	if line1 == line2 then
		return self:sub(line1, col1, col2 - 1)
	else
		table.insert(lines, self:sub(line1, col1))
		for line = line1 + 1, line2 - 1 do
			table.insert(lines, self:getline(line))
		end
		table.insert(lines, self:sub(line2, 1, col2 - 1))
	end
	return lines
end

