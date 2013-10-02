--codedit line buffer object
local glue = require'glue'
local str = require'codedit_str'
local tabs = require'codedit_tabs'

local buffer = {
	line_terminator = nil, --line terminator to use when saving. nil means autodetect.
	tabs = 'indent', --never, indent, always
}

function buffer:new(editor, text)
	self = glue.inherit({editor = editor}, self)
	self.line_terminator = self.line_terminator or self:detect_line_terminator(text)
	self.lines = {''} --can't have zero lines
	self.changed = {} --{flag = nil/true/false}; all flags are set to true whenever the buffer changes.
	self:insert_string(1, 1, text)
	self.changed.file = false --"file" is the default changed flag to use for saving.
	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil
	return self
end

--low-level line-based interface

function buffer:getline(line)
	return self.lines[line]
end

function buffer:last_line()
	return #self.lines
end

function buffer:contents(lines)
	return table.concat(lines or self.lines, self.line_terminator)
end

function buffer:invalidate()
	for k in pairs(self.changed) do
		self.changed[k] = true
	end
end

function buffer:insert_line(line, s)
	table.insert(self.lines, line, s)
	self:undo_command('remove_line', line)
	self:invalidate()
end

function buffer:remove_line(line)
	local s = table.remove(self.lines, line)
	self:undo_command('insert_line', line, s)
	self:invalidate()
	return s
end

function buffer:setline(line, s)
	self:undo_command('setline', line, self:getline(line))
	self.lines[line] = s
	self:invalidate()
end

--switch two lines with one another
function buffer:move_line(line1, line2)
	local s1 = self:getline(line1)
	local s2 = self:getline(line2)
	if not s1 or not s2 then return end
	self:setline(line1, s2)
	self:setline(line2, s1)
end

--hi-level position-based interface

function buffer:last_col(line)
	return str.len(self:getline(line))
end

function buffer:indent_col(line)
	return select(2, str.first_nonspace(self:getline(line)))
end

function buffer:isempty(line)
	return str.first_nonspace(self:getline(line)) > #self:getline(line)
end

function buffer:sub(line, col1, col2)
	return str.sub(self:getline(line), col1, col2)
end

--position left of some char, unclamped
function buffer:left_pos(line, col)
	if col > 1 then
		return line, col - 1
	elseif self:getline(line - 1) then
		return line - 1, self:last_col(line - 1) + 1
	else
		return line - 1, 1
	end
end

--position right of some char, unclamped
function buffer:right_pos(line, col, restrict_eol)
	if not restrict_eol or (self:getline(line) and col < self:last_col(line) + 1) then
		return line, col + 1
	else
		return line + 1, 1
	end
end

--position some-chars distance from some char, unclamped
function buffer:near_pos(line, col, chars, restrict_eol)
	local method = chars > 0 and self.right_pos or self.left_pos
	chars = math.abs(chars)
	while chars > 0 do
		line, col = method(self, line, col, restrict_eol)
		chars = chars - 1
	end
	return line, col
end

--clamp a char position to the available text
function buffer:clamp_pos(line, col)
	if line < 1 then
		return 1, 1
	elseif line > self:last_line() then
		return self:last_line(), self:last_col(self:last_line()) + 1
	else
		return line, math.min(math.max(col, 1), self:last_col(line) + 1)
	end
end

--select the string between two valid, subsequent positions in the text
function buffer:select_string(line1, col1, line2, col2)
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

--extend the buffer up to (line,col-1) so we can edit there.
function buffer:extend(line, col)
	while line > self:last_line() do
		self:insert_line(self:last_line() + 1, '')
	end
	local last_col = self:last_col(line)
	if col > last_col + 1 then
		self:setline(line, self:getline(line) .. string.rep(' ', col - last_col - 1))
	end
end

--insert a multiline string at a specific position in the text, returning the position after the last character.
function buffer:insert_string(line, col, s)
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

--remove the string between two valid, subsequent positions in the text.
--line2,col2 is the position right after (not of!) the last character to be removed.
function buffer:remove_string(line1, col1, line2, col2)
	line1, col1 = self:clamp_pos(line1, col1)
	line2, col2 = self:clamp_pos(line2, col2)
	local s1 = self:sub(line1, 1, col1 - 1)
	local s2 = self:sub(line2, col2)
	for line = line2, line1 + 1, -1 do
		self:remove_line(line)
	end
	self:setline(line1, s1 .. s2)
end

--editing based on tabsize and tabs option

function buffer:insert_tab(line, col)
	if self.tabs == 'never' or
		(self.tabs == 'indent' and self:getline(line) and col > self:indent_col(line))
	then
		return self:insert_string(line, col, string.rep(' ', self.editor.tabsize))
	else
		return self:insert_string(line, col, '\t')
	end
end

function buffer:remove_tab(line, col)
	if not self:getline(line) then return end
	local s = self:sub(line, col, 1/0)
	if str.istab(s, 1) then
		self:remove_string(line, col, line, col + 1)
		return
	end
	--no tab to remove, hunt for enough spaces that make for a tab
	local n = 0
	for i in str.byte_indices(s) do
		n = n + 1
		if n > self.editor.tabsize or not str.isspace(s, i) then
			--found enough spaces to make a full tab, or found a non-space char
			break
		elseif str.istab(s, i) then
			--not enough spaces to make a tab, but a tab was found: replace the tab with spaces
			--and remove a full tab worth of spaces from he beginning of the line
			s = s:sub(col, col + i - 2) .. string.rep(' ', self.editor.tabsize) .. s:sub(col + i)
			--s = s:sub(col + self.editor.tabsize)
			--self:setline(line, s)
			--self:remove_string(line, col + n
			return
		end
	end
	--line ended or the search was interrupted
	self:remove_string(line, col, line, col + n - 1)
end

function buffer:indent_line(line)
	return self:insert_tab(line, 1)
end

function buffer:outdent_line(line)
	return self:remove_tab(line, 1)
end

--[[
function buffer:delete_
	if self.auto_indent then
		local indent_col = self.buffer:indent_col(self.line)
		if indent_col > 1 and self.col >= indent_col then --cursor is after the indent whitespace, we're auto-indenting
			indent = self.buffer:sub(self.line, 1, indent_col - 1)
		end
	end


function buffer:
	if false and (self.tab_align_list or self.tab_align_args) then
		--look in the line above for the vcol of the first non-space char after at least one space or '(', starting at vcol
		if str.first_nonspace(s1) < #s1 then
			local vcol = self.buffer:visual_col(self.line, self.col)
			local col1 = self.buffer:real_col(self.line-1, vcol)
			local stage = 0
			local s0 = self.buffer:getline(self.line-1)
			for i in str.byte_indices(s0) do
				if i >= col1 then
					if stage == 0 and (str.isspace(s0, i) or str.isascii(s0, i, '(')) then
						stage = 1
					elseif stage == 1 and not str.isspace(s0, i) then
						stage = 2
						break
					end
					col1 = col1 + 1
				end
			end
			if stage == 2 then
				local vcol1 = self.buffer:visual_col(self.line-1, col1)
				c = string.rep(' ', vcol1 - vcol)
			else
				c = string.rep(' ', self.editor.tabsize)
			end
		end
	elseif self.tabs == 'never' then
		self:insert_string(string.rep(' ', self.editor.tabsize))
		return
	elseif self.tabs == 'indent' then
		if self.buffer:getline(self.line) and self.col > self.buffer:indent_col(self.line) then
			self:insert_string(string.rep(' ', self.editor.tabsize))
			return
		end
	end
	self:insert_string'\t'
]]

--tab expansion

function buffer:tabstop_distance(vcol)
	return tabs.tabstop_distance(vcol, self.editor.tabsize)
end

function buffer:visual_col(line, col)
	local s = self:getline(line)
	if s then
		return tabs.visual_col(s, col, self.editor.tabsize)
	else
		return col --outside eof visual columns and real columns are the same
	end
end

function buffer:real_col(line, vcol)
	local s = self:getline(line)
	if s then
		return tabs.real_col(s, vcol, self.editor.tabsize)
	else
		return vcol --outside eof visual columns and real columns are the same
	end
end

--real col on a line, that is vertically aligned to the same real col on a different line
function buffer:aligned_col(target_line, line, col)
	return self:real_col(target_line, self:visual_col(line, col))
end


if not ... then require'codedit_demo' end

return buffer
