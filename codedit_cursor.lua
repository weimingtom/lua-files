--codedit cursor: caret-based navigation and editing
local editor = require'codedit_editor'
local glue = require'glue'
local str = require'codedit_str'

editor.cursor = {
	--navigation behavior
	restrict_eol = true, --don't allow caret past end-of-line
	restrict_eof = false, --don't allow caret past end-of-file
	land_bof = true, --go at bof if cursor goes up past it
	land_eof = true, --go at eof if cursor goes down past it
	word_chars = '^[a-zA-Z]', --for jumping through words
	--editing
	insert_mode = true, --insert or overwrite when typing characters
	auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
	tabs = 'indent', --never, indent, always
	tab_align_list = true, --align to the next word on the above line; incompatible with tabs = 'always'
	tab_align_args = true, --align to the char after '(' on the above line; incompatible with tabs = 'always'
	--scrolling behavior
	keep_on_page_change = true, --preserve cursor position through page-up/page-down
}

function editor:create_cursor(visible)
	return self.cursor:new(self, visible)
end

local cursor = editor.cursor

function cursor:new(editor, visible)
	self = glue.inherit({editor = editor, visible = visible}, self)
	self.line = 1
	self.col = 1 --current real col
	self.vcol = 1 --wanted visual col, when navigating up/down
	self.editor.cursors[self] = true
	self.selection = self.editor:create_selection(visible)
	return self
end

function cursor:free()
	assert(self.editor.cursor ~= self) --can't delete the default, key-bound cursor
	self.editor.cursors[self] = nil
end

--cursor navigation ------------------------------------------------------------------------------------------------------

function cursor:move(line, col)
	col = math.max(1, col)
	if line < 1 then
		line = 1
		if self.land_bof then
			col = 1
		elseif self.restrict_eol then
			col = math.min(col, self.editor:last_col(line) + 1)
		end
	elseif line > self.editor:last_line() then
		if self.restrict_eof then
			line = self.editor:last_line()
			if self.land_eof then
				col = self.editor:last_col(line) + 1
			end
		elseif self.restrict_eol then
			col = 1
		end
	elseif self.restrict_eol then
		col = math.min(col, self.editor:last_col(line) + 1)
	end
	self.line = line
	self.col = col
end

function cursor:move_horiz(cols)
	local line, col = self.editor:near_pos(self.line, self.col, cols, self.restrict_eol)
	self:move(line, col)
end

function cursor:move_vert(lines)
	local line = self.line + lines
	local col = self.editor:real_col(line, self.vcol)
	self:move(line, col)
end

function cursor:move_left()  self:move_horiz(-1) end
function cursor:move_right() self:move_horiz(1) end
function cursor:move_up()    self:move_vert(-1) end
function cursor:move_down()  self:move_vert(1) end

function cursor:move_left_word()
	local s = self.editor:getline(self.line)
	if not s or self.col == 1 then
		return self:move_horiz(-1)
	elseif self.col <= self.editor:indent_col(self.line) then --skip indent
		return self:move_horiz(-1/0)
	end
	local col = str.char_index(s, str.prev_word_break(s, str.byte_index(s, self.col), self.word_chars))
	col = math.max(1, col) --if not found, consider it found at bol
	self:move_horiz(-(self.col - col))
end

function cursor:move_right_word()
	local s = self.editor:getline(self.line)
	if not s then
		return self:move_horiz(1)
	elseif self.col > self.editor:last_col(self.line) then --skip indent
		if self.line + 1 > self.editor:last_line() then
			return self:move(self.line + 1, 1)
		else
			return self:move(self.line + 1, self.editor:indent_col(self.line + 1))
		end
	end
	local col = str.char_index(s, str.next_word_break(s, str.byte_index(s, self.col), self.word_chars))
	self:move_horiz((col - self.col))
end

function cursor:move_home()
	self:move(1, 1)
end

function cursor:move_bol() --beginning of line
	self:move(self.line, 1)
end

function cursor:move_end()
	local line, col = self.editor:clamp_pos(1/0, 1/0)
	self:move(line, col)
end

function cursor:move_eol() --end of line
	local line, col = self.editor:clamp_pos(self.line, 1/0)
	self:move(line, col)
end

function cursor:move_up_page()
	local old_line = self.line
	self:move_vert(-self.editor:pagesize())
	if self.keep_on_page_change then
		self:scroll_preserve(old_line, self.line)
	end
end

function cursor:move_down_page()
	local old_line = self.line
	self:move_vert(self.editor:pagesize())
	if self.keep_on_page_change then
		self:scroll_preserve(old_line, self.line)
	end
end

function cursor:move_to_selection_end()
	self:move(self.selection.line2, self.selection.col2)
end

-- other ..............

function cursor:extend_selection()
	self.selection:extend(self.line, self.col)
end

function cursor:reset_selection()
	self.selection:reset(self.line, self.col)
end

function cursor:store_vcol()
	self.vcol = self.editor:visual_col(self.line, self.col)
end

function cursor:make_visible()
	if not self.visible then return end
	local vcol = self.editor:visual_col(self.line, self.col)
	self.editor:make_visible(self.line, vcol)
end


--scroll to preserve cursor's screen location
function cursor:scroll_preserve(old_line, cur_line)
	local cx, cy = self.editor:char_coords(cur_line - old_line + 1, 1)
	self.editor:scroll_by(0, -cy)
end

function cursor:select_all()
	self.selection:select_all()
	self:move_to_selection_end()
end

--cursor-based editing ---------------------------------------------------------------------------------------------------

--extend the buffer to reach the cursor so we can edit there
function cursor:extend()
	if self.restrict_eof and self.restrict_eol then --cursor can't exceed the buffer, do nothing
		return
	end
	self.editor:extend(self.line, self.col)
end

--insert a string at cursor and move the cursor to after the string
function cursor:insert_string(s)
	self:extend()
	local line, col = self.editor:insert_string(self.line, self.col, s)
	self:move(line, col, true)
end

--insert a string block at cursor and move the cursor to after the string
function cursor:insert_block(s)
	self:extend()
	local line, col = self.editor:insert_block(self.line, self.col, s)
	self:move(line, col, true)
end

--pressing enter adds a new line, optionally copies the indent of the current line, and carries the cursor over.
function cursor:newline()
	if self.auto_indent then
		local indent_col = self.editor:indent_col(self.line)
		if indent_col > 1 and self.col >= indent_col then --cursor is after the indent whitespace, we're auto-indenting
			local indent = self.editor:sub(self.line, 1, indent_col - 1)
			self.editor:undo_break()
			self:insert_string'\n'
			self.editor:undo_break()
			self:insert_string(indent)
			return
		end
	end
	self.editor:undo_break()
	self:insert_string'\n'
	self.editor:undo_break()
end

function cursor:expand_tab()
	if false and (self.tab_align_list or self.tab_align_args) then
		--look in the line above for the vcol of the first non-space char after at least one space or '(', starting at vcol
		if str.first_nonspace(s1) < #s1 then
			local vcol = self.editor:visual_col(self.line, self.col)
			local col1 = self.editor:real_col(self.line-1, vcol)
			local stage = 0
			local s0 = self.editor:getline(self.line-1)
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
				local vcol1 = self.editor:visual_col(self.line-1, col1)
				c = string.rep(' ', vcol1 - vcol)
			else
				c = string.rep(' ', self.editor.tabsize)
			end
		end
	elseif self.tabs == 'never' then
		return string.rep(' ', self.editor.tabsize)
	elseif self.tabs == 'indent' then
		local s = self.editor:getline(self.line)
		local s1 = str.sub(s, 1, self.col - 1)
		if str.first_nonspace(s1) <= #s1 then --we're inside the line
			return string.rep(' ', self.editor.tabsize)
		end
	end
	return '\t'
end

--insert tab at cursor or indent selection
function cursor:indent()
	if not self.selection:isempty() then
		local with_tabs = self.tabs == 'indent' or self.tabs == 'always'
		self.selection:indent(with_tabs)
		self:move_to_selection_end()
	else
		self:insert_string(self:expand_tab())
	end
end

--outdent selection or line
function cursor:outdent()
	if not self.selection:isempty() then
		self.selection:outdent()
		self:move_to_selection_end()
	else
		self:extend()
		local n = #self.editor:getline(self.line)
		self.editor:outdent_line(self.line)
		local col = self.col - (n - #self.editor:getline(self.line))
		self:move(self.line, col, true)
	end
end

--move selection or line up one line
function cursor:move_lines_up()
	if self.selection:isempty() then
		self.editor:move_line(self.line, self.line - 1)
		self:move_up()
	else
		self.selection:move_up()
		self:move_to_selection_end()
	end
end

--move selection or line down one line
function cursor:move_lines_down()
	if self.selection:isempty() then
		self.editor:move_line(self.line, self.line + 1)
		self:move_down()
	else
		self.selection:move_down()
		self:move_to_selection_end()
	end
end

--insert (or overstrike) a non-control char at cursor
function cursor:insert_char(s)
	if not self.insert_mode then
		self.editor:remove_string(self.line, self.col, self.line, self.col + str.len(s))
	end
	self:insert_string(s)
end

function cursor:remove_selection()
	self.selection:remove()
	self:move_to_selection_end()
end

function cursor:delete_prev_char()
	self:extend()
	if not self.selection:isempty() then
		self:remove_selection()
	else
		local line1, col1 = self.editor:left_pos(self.line, self.col)
		line1, col1 = self.editor:clamp_pos(line1, col1)
		self.editor:remove_string(line1, col1, self.line, self.col)
		self:move(line1, col1)
	end
end

function cursor:delete_char()
	self:extend()
	if not self.selection:isempty() then
		self:remove_selection()
	else
		local line2, col2 = self.editor:right_pos(self.line, self.col)
		line2, col2 = self.editor:clamp_pos(line2, col2)
		self.editor:remove_string(self.line, self.col, line2, col2)
	end
end


if not ... then require'codedit_demo' end
