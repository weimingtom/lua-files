--codedit line buffer object
local glue = require'glue'
local str = require'codedit_str'
require'codedit_reflow'
local tabs = require'codedit_tabs'

local buffer = {
	line_terminator = nil, --line terminator to use when retrieving lines as a string. nil means autodetect.
	default_line_terminator = '\n', --line terminator to use when autodetection fails.
}

function buffer:new(editor, text)
	self = glue.inherit({
		editor = editor,  --for getstate/setstate
		view = editor,    --for tabsize
	}, self)
	self.line_terminator =
		self.line_terminator or
		self:detect_line_terminator(text) or
		self.default_line_terminator
	self.lines = {''} --can't have zero lines
	self.changed = {} --{<flag> = true/false}; you can add any flags, they will all be set to true when the buffer changes.
	if text then
		self:insert_string(1, 1, text) --insert text without undo stack
	end
	self.changed.file = false --"file" is the default changed flag to decide when to save.
	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil
	return self
end

--text analysis

--class method that returns the most common line terminator in a string, or nil for failure
function buffer:detect_line_terminator(s)
	local rn = str.count(s, '\r\n') --win lines
	local r  = str.count(s, '\r') --mac lines
	local n  = str.count(s, '\n') --unix lines (default)
	if rn > n and rn > r then
		return '\r\n'
	elseif r > n then
		return '\r'
	end
end

--detect indent type and tab size of current buffer
function buffer:detect_indent()
	local tabs, spaces = 0, 0
	for line = 1, self:last_line() do
		local tabs1, spaces1 = str.indent_counts(self:getline(line))
		tabs = tabs + tabs1
		spaces = spaces + spaces1
	end
	--TODO: finish this
end

--finding line boundaries

function buffer:last_line()
	return #self.lines
end

--selecting text at line boundaries

function buffer:getline(line)
	return self.lines[line]
end

function buffer:contents(lines)
	return table.concat(lines or self.lines, self.line_terminator)
end

--editing text at line boundaries

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

--finding (line,column) boundaries

--last column on a valid line
function buffer:last_col(line)
	return str.len(self:getline(line))
end

--the char position after the last char in the text
function buffer:end_pos()
	return self:last_line(), self:last_col(self:last_line()) + 1
end

--navigation at char boundaries

--position before some char, unclamped
function buffer:prev_char_pos(line, col)
	if col > 1 then
		return line, col - 1
	elseif self:getline(line - 1) then
		return line - 1, self:last_col(line - 1) + 1
	else
		return line - 1, 1
	end
end

--position after of some char, unclamped
function buffer:next_char_pos(line, col, restrict_eol)
	if not restrict_eol or (self:getline(line) and col < self:last_col(line) + 1) then
		return line, col + 1
	else
		return line + 1, 1
	end
end

--position that is a number of chars after or before some char, unclamped
function buffer:near_char_pos(line, col, chars, restrict_eol)
	local advance = chars > 0 and self.next_char_pos or self.prev_char_pos
	chars = math.abs(chars)
	while chars > 0 do
		line, col = advance(self, line, col, restrict_eol)
		chars = chars - 1
	end
	return line, col
end

--clamp a char position to the available text
function buffer:clamp_pos(line, col)
	if line < 1 then
		return 1, 1
	elseif line > self:last_line() then
		return self:end_pos()
	else
		return line, math.min(math.max(col, 1), self:last_col(line) + 1)
	end
end

--selecting text at char boundaries

--line slice between two columns on a valid line
function buffer:sub(line, col1, col2)
	return str.sub(self:getline(line), col1, col2)
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

--editing at char boundaries

--extend the buffer up to (line,col-1) with newlines and spaces so we can edit there.
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
--if the position is outside the text, the buffer is extended.
function buffer:insert_lines(line, col, lines)
	self:extend(line, col)
	local s1 = self:sub(line, 1, col - 1)
	local s2 = self:sub(line, col)
	if #lines == 1 then
		self:setline(line, s1 .. lines[1] .. s2)
	else
		for i,s in ipairs(lines) do
			if i == 1 then
				self:setline(line, s1 .. s)
			elseif i == #lines then
				self:setline(line + i - 1, s .. s2)
			else
				self:insert_line(line + i, s)
			end
		end
	end
	line = line + #lines - 1
	return line, self:last_col(line) - #s2 + 1
end

--insert a multiline string at a specific position in the text, returning the position after the last character.
--if the position is outside the text, the buffer is extended.
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

--remove the string between two arbitrary, subsequent positions in the text.
--line2,col2 is the position after the last character to be removed.
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

--tab expansion (adding the concept of visual columns and tabstops)

function buffer:tab_width(vcol)               return tabs.tab_width(vcol, self.view.tabsize) end
function buffer:next_tabstop(vcol)            return tabs.next_tabstop(vcol, self.view.tabsize) end
function buffer:prev_tabstop(vcol)            return tabs.prev_tabstop(vcol, self.view.tabsize) end
function buffer:tabs_and_spaces(vcol1, vcol2) return tabs.tabs_and_spaces(vcol1, vcol2, self.view.tabsize) end

--real col -> visual col. outside eof visual columns and real columns coincide.
function buffer:visual_col(line, col)
	local s = self:getline(line)
	if s then
		return tabs.visual_col(s, col, self.view.tabsize)
	else
		return col
	end
end

--visual col -> real col. outside eof visual columns and real columns coincide.
function buffer:real_col(line, vcol)
	local s = self:getline(line)
	if s then
		return tabs.real_col(s, vcol, self.view.tabsize)
	else
		return vcol
	end
end

--the real col on a line that is vertically aligned to the same real col on a different line.
function buffer:aligned_col(target_line, line, col)
	return self:real_col(target_line, self:visual_col(line, col))
end

--navigation at tabstop boundaries

function buffer:prev_tabstop_col(line, col)
	local vcol = self:visual_col(line, col)
	local ts_vcol = self:prev_tabstop(vcol)
	return self:real_col(line, ts_vcol)
end

function buffer:next_tabstop_col(line, col)
	local vcol = self:visual_col(line, col)
	local ts_vcol = self:next_tabstop(vcol)
	return self:real_col(line, ts_vcol)
end

--editing based on tab expansion

--insert a tab or spaces from a char position up to the next tabstop.
--return the cursor at the tabstop, where the indented text is.
function buffer:indent(line, col, use_tab)
	if use_tab then
		return self:insert_string(line, col, '\t')
	else
		local vcol = self:visual_col(line, col)
		return self:insert_string(line, col, string.rep(' ', self:tab_width(vcol)))
	end
end

function buffer:indent_line(line, use_tab)
	return self:indent(line, 1, use_tab)
end

--insert whitespace (tabs and spaces or just spaces, depending on the use_tabs flag)
--from a char position up to (but excluding) a visual col on the same line.
function buffer:insert_whitespace(line, col, vcol2, use_tabs)
	local vcol1 = self:visual_col(line, col)
	if vcol2 <= vcol1 then
		return line, col
	end
	local tabs, spaces
	if use_tabs then
		tabs, spaces = self:tabs_and_spaces(vcol1, vcol2)
	else
		tabs, spaces = 0, vcol2 - vcol1
	end
	return self:insert_string(line, col, string.rep('\t', tabs) .. string.rep(' ', spaces))
end

--finding non-space boundaries

function buffer:first_nonspace_col(line)
	local s = self:getline(line)
	return s and str.first_nonspace(s)
end

function buffer:next_nonspace_col(line, col)
	local s = self:getline(line)
	return s and str.next_nonspace(s, col)
end

function buffer:prev_nonspace_col(line, col)
	local s = self:getline(line)
	return s and str.prev_nonspace(s, col)
end

--check if a line is either invalid, empty or made entirely of whitespace
function buffer:isempty(line)
	return not self:first_nonspace_col(line)
end

--check if a position is before the first non-space char, that is, in the indentation area.
function buffer:indenting(line, col)
	local ns_col = self:first_nonspace_col(line)
	return not ns_col or col <= ns_col
end

--navigation at tabful boundaries. a tabful is the whitespace between two tabstops.

--tabful position before some char, unclamped.
--the prev. tabful position is either:
--the prev. tabstop or,
	--(the char after the prev. non-space char or,
	--one char before the current char,
	--whichever comes first),
--whichever comes last.
function buffer:prev_tabful_pos(line, col)
	if col > 1 then
		local ts_col = self:prev_tabstop_col(line, col)
		local ns_col = self:prev_nonspace_col(line, col)
		if not ns_col then
			col = ts_col
		else
			local sp_col = math.min(ns_col + 1, col - 1)
			col = math.max(ts_col, sp_col)
		end
		assert(col >= 1)
		return line, col
	end
	return self:prev_char_pos(line, col)
end

--tabful position after of some char, unclamped.
--the next tabful position is either:
	--the next tabstop or,
		--(the next non-space char after the prev. char or,
		--one char after the current char,
		--whichever comes last),
	--whichever comes first.
function buffer:next_tabful_pos(line, col, restrict_eol)
	if not restrict_eol or (self:getline(line) and col <= self:last_col(line)) then
		local ts_col = self:next_tabstop_col(line, col)
		local ns_col = self:next_nonspace_col(line, col - 1)
		if not ns_col then
			col = ts_col
		else
			local sp_col = math.max(ns_col, col + 1) --next non-space char or next char, whichever is last
			col = math.min(ts_col, sp_col) --next tabstop or next sp_col, whichever is first
		end
		if restrict_eol then
			line, col = self:clamp_pos(line, col)
		end
		return line, col
	end
	return self:next_char_pos(line, col, restrict_eol)
end

--editing based on tabfuls

--remove the space up to the next tabstop or non-space char, in other words, remove a tabful.
function buffer:outdent(line, col)
	local s = self:getline(line)
	if not s then return end
	local i = str.byte_index(s, col)
	if not i or not str.isspace(s, i) then return end

	local line2, col2 = self:next_tabful_pos(line, col, false)
	self:remove_string(line, col, line, col2)
end

function buffer:outdent_line(line)
	self:outdent(line, 1)
end

--navigation at word boundaries

--position of the prev. word break based on semantics of str.prev_word_break()
function buffer:prev_word_pos(line, col, word_chars)
	if line < 1 or col <= 1 then
		return self:prev_char_pos(line, col)
	elseif line > self:last_line() then
		return self:end_pos()
	elseif col > self:last_col(line) + 1 then
		return line, self:last_col(line) + 1
	else
		local s = self:getline(line)
		local prev_col = str.prev_word_break(s, col, word_chars)
		if not prev_col then
			return self:prev_char_pos(line, col)
		end
		return line, prev_col
	end
end

--position of the next word break based on semantics of str.next_word_break()
function buffer:next_word_pos(line, col, word_chars)
	local s = self:getline(line)
	if not s or col > self:last_col(line) then
		return self:next_char_pos(line, col, true)
	end
	local next_col = str.next_word_break(s, col, word_chars)
	if not next_col then
		return self:next_char_pos(line, col)
	end
	return line, next_col
end

--navigatioo at list boundaries

--the idea is to align the cursor with the text on the above line, like this:
--	 more text        even more text
--  from here     -->_ to here
--the conditions are: not indenting and there's a line above, and that line
--has a word after at least two visual spaces starting at vcol.
function buffer:next_list_aligned_vcol(line, col, restrict_eol)
	if line > 1 and not self:indenting(line, col) then
		local above_col = self:aligned_col(line - 1, line, col)
		local ns_col = self:next_nonspace_col(line - 1, above_col)
		return ns_col and self:visual_col(line - 1, ns_col)
	end
end

--paragraph-level editing

--text reflowing. return the position after the last inserted character.
function buffer:reflow(line1, col1, line2, col2, line_width, align, wrap)
	local lines = self:select_string(line1, col1, line2, col2)
	local lines = str.reflow(lines, line_width, align, wrap)
	self:remove_string(line1, col1, line2, col2)
	return self:insert_string(line1, col1, self:contents(lines))
end


if not ... then require'codedit_demo' end

return buffer
