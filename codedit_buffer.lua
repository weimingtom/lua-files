--codedit interface to the internal line buffer
local editor = require'codedit_editor'
local str = require'codedit_str'

--low-level line-based interface

function editor:getline(line)
	return self.lines[line]
end

function editor:last_line()
	return #self.lines
end

function editor:contents(lines)
	return table.concat(lines or self.lines, self.line_terminator)
end

function editor:invalidate()
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
end

function editor:insert_line(line, s)
	table.insert(self.lines, line, s)
	self:undo_command('remove_line', line)
	self:invalidate()
end

function editor:remove_line(line)
	local s = table.remove(self.lines, line)
	self:undo_command('insert_line', line, s)
	self:invalidate()
	return s
end

function editor:setline(line, s)
	self:undo_command('setline', line, self:getline(line))
	self.lines[line] = s
	self:invalidate()
end

--switch two lines with one another
function editor:move_line(line1, line2)
	local s1 = self:getline(line1)
	local s2 = self:getline(line2)
	if not s1 or not s2 then return end
	self:setline(line1, s2)
	self:setline(line2, s1)
end

--hi-level position-based interface

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

--position left of some char, unclamped
function editor:left_pos(line, col)
	if col > 1 then
		return line, col - 1
	elseif self:getline(line - 1) then
		return line - 1, self:last_col(line - 1) + 1
	else
		return line - 1, 1
	end
end

--position right of some char, unclamped
function editor:right_pos(line, col, restrict_eol)
	if not restrict_eol or (self:getline(line) and col < self:last_col(line) + 1) then
		return line, col + 1
	else
		return line + 1, 1
	end
end

--position some-chars distance from some char, unclamped
function editor:near_pos(line, col, chars, restrict_eol)
	local method = chars > 0 and self.right_pos or self.left_pos
	chars = math.abs(chars)
	while chars > 0 do
		line, col = method(self, line, col, restrict_eol)
		chars = chars - 1
	end
	return line, col
end

--clamp a char position to the available text
function editor:clamp_pos(line, col)
	if line < 1 then
		return 1, 1
	elseif line > self:last_line() then
		return self:last_line(), self:last_col(self:last_line()) + 1
	else
		return line, math.min(math.max(col, 1), self:last_col(line) + 1)
	end
end

--select the string between two subsequent positions in the text
function editor:select_string(line1, col1, line2, col2)
	local lines = {}
	if line1 == line2 then
		table.insert(lines, self:sub(line1, col1, col2 - 1))
	else
		table.insert(lines, self:sub(line1, col1))
		for line = line1 + 1, line2 - 1 do
			table.insert(lines, self:getline(line))
		end
		table.insert(lines, self:sub(line2, 1, col2 - 1))
	end
	return lines
end

--insert a multiline string at a specific position in the text, returning the position after the last character.
function editor:insert_string(line, col, s)
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

--functions involving tabsize

function editor:indent_line(line, with_tabs)
	self:insert_string(line, 1, with_tabs and '\t' or string.rep(' ', self.tabsize))
end

function editor:outdent_line(line)
	local s = self:getline(line)
	if str.istab(s, 1) then
		self:remove_string(line, 1, line, 2)
	else
		--no tab to remove, hunt for enough spaces that make for a tab
		local n = 0
		for i in str.byte_indices(s) do
			n = n + 1
			if n > self.tabsize or not str.isspace(s, i) then
				--found enough spaces to make a full tab, or a non-space char encountered
				break
			elseif str.istab(s, i) then
				--not enough spaces to make a tab, but a tab was found: replace the tab with spaces
				--and remove a full tab worth of spaces from he beginning of the line
				s = s:sub(1, i - 1) .. string.rep(' ', self.tabsize) .. s:sub(i + 1)
				s = s:sub(self.tabsize + 1)
				self:setline(line, s)
				return
			end
		end
		--line ended or the search was interrupted
		self:remove_string(line, 1, line, n)
	end
end


if not ... then require'codedit_demo' end
