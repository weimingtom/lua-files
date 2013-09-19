--codedit cursor: caret-based navigation and editing
local editor = require'codedit_editor'
local glue = require'glue'
local str = require'codedit_str'

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

editor.cursor = {
	--navigation behavior
	restrict_eol = true, --don't allow caret past end-of-line
	restrict_eof = false, --don't allow caret past end-of-file
	land_home = true, --go home if cursor goes up past beginning-of-file
	word_chars = '^[a-zA-Z]', --to know how to jump through words
	--editing
	insert_mode = true, --insert or overwrite when typing characters
	auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
	tabs = 'indent', --never, indent, always
	tab_align_list = true, --align to the next word on the above line; incompatible with tabs = 'always'
	tab_align_args = true, --align to the char after '(' on the above line; incompatible with tabs = 'always'
	--rendering
	color = nil, --custom color
	caret_thickness = 2,
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

function cursor:move(line, col, remember_vcol, selecting, block_mode, keep_screen_location)

	--restrict the cursor according to current policy
	local restrict_eol = self.restrict_eol and (not selecting or not block_mode)
	local restrict_eof = self.restrict_eof
	if line < 1 then
		line, col = 1, 1
	elseif line > self.editor:last_line() then
		if restrict_eol then
			line = self.editor:last_line()
			col = self.editor:last_col(self.editor:last_line()) + 1
		elseif restrict.eof then
			line = self.editor:last_line()
		end
	elseif restrict_eol then
		col = clamp(col, 1, self.editor:last_col(line) + 1)
	end

	--store wanted vcol
	local vcol = self.editor:visual_col(line, col)
	if remember_vcol then
		self.vcol = vcol
	end

	if self.visible then
		--scroll to preserve its screen location
		if keep_screen_location then
			local vcol0 = self.editor:visual_col(self.line, self.col)
			local cx = (vcol - vcol0) * self.editor.charsize
			local cy = (line - self.line) * self.editor.linesize
			self.editor:scroll_by(cx, -cy)
		end
		--scroll to make it visible
		self.editor:make_visible(line, vcol)
	end

	--reset or extend selection
	if selecting then
		self.selection:move(line, col)
	else
		self.selection:reset(line, col)
	end

	--finally, set the cursor position
	self.line = line
	self.col = col
end

function cursor:move_horiz(cols, selecting, block_mode, ...)
	local line = self.line
	local col = self.col + cols
	if selecting and block_mode then
		--no jumping the next line when selecting blocks
	elseif col < 1 then
		line = line - 1
		if line < 1 then
			line, col = 1, 1
		elseif line <= self.editor:last_line() then
			col = self.editor:last_col(line) + 1
		else
			col = 1
		end
	elseif self.restrict_eol and
		(line > self.editor:last_line() or
			col > self.editor:last_col(line) + 1)
	then
		line = line + 1
		col = 1
	end
	self:move(line, col, true, selecting, block_mode, ...)
end

function cursor:move_vert(lines, selecting, block_mode, ...)
	local line = self.line + lines
	local col = self.col
	if selecting and block_mode then
		--no jumping cols when selecting blocks
	elseif line < 1 and self.land_home then
		line, col = 1, 1
	elseif line <= self.editor:last_line() then
		col = self.editor:real_col(line, self.vcol)
		if self.restrict_eol then
			col = clamp(col, 1, self.editor:last_col(line) + 1)
		end
	else
		col = self.vcol
	end
	self:move(line, col, false, selecting, block_mode, ...)
end

--cursor navigation/hi-level ---------------------------------------------------------------------------------------------

function cursor:move_left(cols, ...)  self:move_horiz(-(cols or 1), ...) end
function cursor:move_right(cols, ...) self:move_horiz(cols or 1, ...) end
function cursor:move_up(lines, ...)   self:move_vert(-(lines or 1), ...) end
function cursor:move_down(lines, ...) self:move_vert(lines or 1, ...) end

function cursor:move_left_word(selecting, ...)
	local s = self.editor:getline(self.line)
	if not s or self.col == 1 then
		return self:move_left(1, selecting, ...)
	elseif self.col <= self.editor:indent_col(self.line) then --skip indent
		return self:move_left(1/0, selecting, ...)
	end
	local col = str.char_index(s, str.prev_word_break(s, str.byte_index(s, self.col), self.word_chars))
	col = math.max(1, col) --if not found, consider it found at bol
	self:move_left(self.col - col, selecting, ...)
end

function cursor:move_right_word(selecting, ...)
	local s = self.editor:getline(self.line)
	if not s then
		return self:move_right(1, selecting, ...)
	elseif self.col > self.editor:last_col(self.col) then --skip indent
		return self:move(self.line + 1, self.editor:indent_col(self.line + 1), selecting, true, ...)
	end
	local col = str.char_index(s, str.next_word_break(s, str.byte_index(s, self.col), self.word_chars))
	self:move_right(col - self.col, selecting, ...)
end

function cursor:move_home(...)
	self:move(1, 1, false, ...)
end

function cursor:move_end(...)
	local line = self.editor:last_line()
	local col = self.editor:last_col(line) + 1
	self:move(line, col, false, ...)
end

function cursor:move_bol(...) --beginning of line
	self:move(self.line, 1, false, ...)
end

function cursor:move_eol(...) --end of line
	if self.line > self.editor:last_line() then return end
	self:move(self.line, self.editor:last_col(self.line) + 1, false, ...)
end

function cursor:move_up_page(selecting, block_mode)
	self:move_up(self.editor:pagesize(), selecting, block_mode, self.keep_on_page_change)
end

function cursor:move_down_page(selecting, block_mode)
	self:move_down(self.editor:pagesize(), selecting, block_mode, self.keep_on_page_change)
end

--cursor editing ---------------------------------------------------------------------------------------------------------

--extend the buffer to reach the cursor so we can edit there
function cursor:extend()
	if self.restrict_eof and self.restrict_eol then --cursor can't exceed the buffer, do nothing
		return
	end
	self.editor:extend(self.line, self.col)
end

--insert a string at cursor and move the cursor to after the string
function cursor:insert_string(s)
	local line, col = self.editor:insert_string(self.line, self.col, s)
	self:move(line, col, true)
end

--insert a string block at cursor and move the cursor to after the string
function cursor:insert_block(s)
	local line, col = self.editor:insert_block(self.line, self.col, s)
	self:move(line, col, true)
end

--pressing enter adds a new line, optionally copies the indent of the current line, and carries the cursor over.
function cursor:newline()
	self:extend()
	local landing_col = 1
	local indent = ''
	if self.auto_indent then
		landing_col = math.min(self.col, self.editor:indent_col(self.line))
		indent = self.editor:sub(self.line, 1, landing_col - 1)
	end
	local s1 = self.editor:sub(self.line, 1, self.col - 1)
	local s2 = indent .. self.editor:sub(self.line, self.col)
	self.editor:setline(self.line, s1)
	self.editor:insert_line(self.line + 1, s2)
	self:move(self.line + 1, landing_col, true)
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
	local with_tabs = self.tabs == 'indent' or self.tabs == 'always'
	if not self.selection:isempty() then
		self.selection:indent(with_tabs)
		self:move(self.selection.line2, 1, true)
	else
		self.editor:indent(self.line, with_tabs)
	end
end

--outdent selection or line
function cursor:outdent()
	if not self.selection:isempty() then
		self.selection:outdent()
		self:move(self.selection.line2, 1, true)
	else
		self.editor:outdent(self.line)
	end
end

--insert (or overstrike) a non-control char at cursor
function cursor:insert_char(c)
	assert(#c > 1 or c:byte(1) > 31)
	self:extend()
	local s = self.editor:getline(self.line)
	local s1 = str.sub(s, 1, self.col - 1)
	local s2 = str.sub(s, self.col + (self.insert_mode and 0 or 1))
	self.editor:setline(self.line, s1 .. c .. s2)
	self:move_right(str.len(c))
end

function cursor:remove_selection()
	self.selection:remove()
	self:move(self.selection.line1, self.selection.col1, true)
end

function cursor:delete_before()
	self:extend()
	if self.selection:isempty() then
		if self.col == 1 then
			if self.line > 1 then
				local s = self.editor:remove_line(self.line)
				self.line = self.line - 1
				local s0 = self.editor:getline(self.line)
				self.editor:setline(self.line, s0 .. s)
				self.col = str.len(s0) + 1
				self.vcol = self.editor:visual_col(self.line, self.col)
			end
		else
			local s = self.editor:getline(self.line)
			s = str.sub(s, 1, self.col - 2) .. str.sub(s, self.col)
			self.editor:setline(self.line, s)
			self:move_left()
		end
	else
		self:remove_selection()
	end
end

function cursor:delete_after()
	self:extend()
	if self.selection:isempty() then
		if self.col > self.editor:last_col(self.line) then
			if self.line < self.editor:last_line() then
				self.editor:setline(self.line, self.editor:getline(self.line) .. self.editor:remove_line(self.line + 1))
			end
		else
			local s = self.editor:getline(self.line)
			self.editor:setline(self.line, str.sub(s, 1, self.col - 1) .. str.sub(s, self.col + 1))
		end
	else
		self:remove_selection()
	end
end

if not ... then require'codedit_demo' end
