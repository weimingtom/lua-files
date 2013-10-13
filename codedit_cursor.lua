--codedit cursor object: caret-based navigation and editing
local glue = require'glue'
local str = require'codedit_str'

local cursor = {
	--navigation policies
	restrict_eol = true, --don't allow caret past end-of-line
	restrict_eof = false, --don't allow caret past end-of-file
	land_bof = true, --go at bof if cursor goes up past it
	land_eof = true, --go at eof if cursor goes down past it
	word_chars = '^[a-zA-Z]', --for jumping between words
	move_tabfuls = 'indent', --'indent', 'never'; where to move the cursor between tabfuls instead of individual spaces.
	--editing policies
	insert_mode = true, --insert or overwrite when typing characters
	auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
	insert_tabs = 'indent', --never, indent, always: where to insert a tab instead of enough spaces that make up a tab.
	insert_list_tabs = true,
	move_list_tabs = true,
	delete_tabfuls = 'indent', --never, indent, always: where to delete all the spaces that make up a tab at once.
	tab_align_list = true, --align to the next word on the above line; incompatible with tabs = 'always'
	tab_align_args = true, --align to the char after '(' on the above line; incompatible with tabs = 'always'
}

function cursor:new(editor, visible)
	self = glue.inherit({editor = editor, buffer = editor.buffer, visible = visible}, self)
	self.line = 1
	self.col = 1 --current real col
	self.vcol = 1 --wanted visual col, when navigating up/down
	self.editor.cursors[self] = true
	return self
end

function cursor:free()
	assert(self.editor.cursor ~= self) --can't delete the default, key-bound cursor
	self.editor.cursors[self] = nil
end

--cursor navigation ------------------------------------------------------------------------------------------------------

--move to a specific position, restricting the final position according to navigation policies
function cursor:move(line, col, keep_vcol)
	col = math.max(1, col)
	if line < 1 then
		line = 1
		if self.land_bof then
			col = 1
		elseif self.restrict_eol then
			col = math.min(col, self.buffer:last_col(line) + 1)
		end
	elseif line > self.buffer:last_line() then
		if self.restrict_eof then
			line = self.buffer:last_line()
			if self.land_eof then
				col = self.buffer:last_col(line) + 1
			end
		elseif self.restrict_eol then
			col = 1
		end
	elseif self.restrict_eol then
		col = math.min(col, self.buffer:last_col(line) + 1)
	end
	self.line = line
	self.col = col

	if not keep_vcol then
		--store the visual col of the cursor to be used as the wanted landing col by move_vert()
		self.vcol = self.buffer:visual_col(self.line, self.col)
	end
end

function cursor:prev_pos()
	if self.move_tabfuls == 'always' or
		(self.move_tabfuls == 'indent' and
		 self.buffer:indenting(self.line, self.col))
	then
		return self.buffer:prev_tabful_pos(self.line, self.col)
	else
		return self.buffer:prev_char_pos(self.line, self.col)
	end
end

function cursor:move_left()
	local line, col = self:prev_pos()
	self:move(line, col)
end

function cursor:next_pos(restrict_eol)
	if restrict_eol == nil then
		restrict_eol = self.restrict_eol
	end

	if self.move_list_tabs then
		local ls_vcol = self.buffer:next_list_aligned_vcol(self.line, self.col, self.restrict_eol)
		if ls_vcol then
			local col = self.buffer:real_col(self.line, ls_vcol)
			local ns_col = self.buffer:next_nonspace_col(self.line, self.col)
			col = math.min(ns_col or 1/0, col)
			return self.line, col
		end
	end

	if self.move_tabfuls == 'always' or
		(self.move_tabfuls == 'indent' and
		 self.buffer:indenting(self.line, self.col + 1))
	then
		return self.buffer:next_tabful_pos(self.line, self.col, restrict_eol)
	else
		return self.buffer:next_char_pos(self.line, self.col, restrict_eol)
	end
end

function cursor:move_right()
	local line, col = self:next_pos()
	self:move(line, col)
end

--navigate vertically, using the stored visual column as target column
function cursor:move_vert(lines)
	local line = self.line + lines
	local col = self.buffer:real_col(line, self.vcol)
	self:move(line, col, true)
end

function cursor:move_up()    self:move_vert(-1) end
function cursor:move_down()  self:move_vert(1) end

function cursor:move_home()  self:move(1, 1) end
function cursor:move_bol()   self:move(self.line, 1) end

function cursor:move_end()
	local line, col = self.buffer:clamp_pos(1/0, 1/0)
	self:move(line, col)
end

function cursor:move_eol()
	local line, col = self.buffer:clamp_pos(self.line, 1/0)
	self:move(line, col)
end

function cursor:move_up_page()
	self:move_vert(-self.editor:pagesize())
end

function cursor:move_down_page()
	self:move_vert(self.editor:pagesize())
end

function cursor:move_left_word()
	local line, col = self.buffer:prev_word_pos(self.line, self.col, self.word_chars)
	self:move(line, col)
end

function cursor:move_right_word()
	local line, col = self.buffer:next_word_pos(self.line, self.col, self.word_chars)
	self:move(line, col)
end

function cursor:move_to_selection(sel)
	self:move(sel.line2, sel.col2)
end

function cursor:move_to_coords(x, y)
	local line, vcol = self.editor:char_at(x, y)
	local col = self.buffer:real_col(line, vcol)
	self:move(line, col)
end

--cursor-based editing ---------------------------------------------------------------------------------------------------

--insert a string at cursor and move the cursor to after the string
function cursor:insert_string(s)
	local line, col = self.buffer:insert_string(self.line, self.col, s)
	self:move(line, col)
end

--insert a string block at cursor and move the cursor to after the string
function cursor:insert_block(s)
	local line, col = self.buffer:insert_block(self.line, self.col, s)
	self:move(line, col)
end

--insert or overwrite a char at cursor, depending on insert mode
function cursor:insert_char(c)
	if not self.insert_mode then
		self:delete_char(false)
	end
	self:insert_string(c)
end

--delete the text up to the next cursor position
function cursor:delete_pos(restrict_eol)
	local line2, col2 = self:next_pos(restrict_eol)
	self.buffer:remove_string(self.line, self.col, line2, col2)
end

--add a new line, optionally copying the indent of the current line, and carry the cursor over
function cursor:insert_newline()
	if self.auto_indent then
		self.buffer:extend(self.line, self.col)
		local indent = self.buffer:select_indent(self.line, self.col)
		self:insert_string('\n' .. indent)
	else
		self:insert_string'\n'
	end
end

--insert a tab character, expanding it according to tab expansion policies
function cursor:insert_tab()
	local use_tab =
		self.insert_tabs == 'always' or
			(self.insert_tabs == 'indent' and
			 self.buffer:indenting(self.line, self.col))

	if self.insert_list_tabs then
		local ls_vcol = self.buffer:next_list_aligned_vcol(self.line, self.col, self.restrict_eol)
		if ls_vcol then
			local line, col = self.buffer:insert_whitespace(self.line, self.col, ls_vcol, use_tab)
			self:move(line, col)
			return
		end
	end

	local line, col = self.buffer:indent(self.line, self.col, use_tab)
	self:move(line, col)
end

function cursor:outdent_line()
	if not self.buffer:getline(self.line) then
		self:move(self.line, self.col - 1)
		return
	end
	local old_sz = #self.buffer:getline(self.line)
	self.buffer:outdent_line(self.line)
	local new_sz = #self.buffer:getline(self.line)
	local col = self.col + new_sz - old_sz
	self:move(self.line, col)
end

function cursor:move_line_up()
	self.buffer:move_line(self.line, self.line - 1)
	self:move_up()
end

function cursor:move_line_down()
	self.buffer:move_line(self.line, self.line + 1)
	self:move_down()
end

--cursor scrolling -------------------------------------------------------------------------------------------------------

function cursor:make_visible()
	if not self.visible then return end
	local vcol = self.buffer:visual_col(self.line, self.col)
	self.editor:make_char_visible(self.line, vcol)
end


if not ... then require'codedit_demo' end

return cursor
