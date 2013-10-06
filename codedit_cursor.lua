--codedit cursor object: caret-based navigation and editing
local glue = require'glue'
local str = require'codedit_str'

local cursor = {
	--navigation policies
	restrict_eol = true, --don't allow caret past end-of-line
	restrict_eof = false, --don't allow caret past end-of-file
	land_bof = true, --go at bof if cursor goes up past it
	land_eof = true, --go at eof if cursor goes down past it
	word_chars = '^[a-zA-Z]', --for jumping through words
	--editing policies
	insert_mode = true, --insert or overwrite when typing characters
	auto_indent = true, --pressing enter copies the indentation of the current line over to the following line
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

--navigate horizontally
function cursor:move_horiz(cols)
	local line, col = self.buffer:near_pos(self.line, self.col, cols, self.restrict_eol)
	self:move(line, col)
end

--navigate vertically, using the stored visual column as target column
function cursor:move_vert(lines)
	local line = self.line + lines
	local col = self.buffer:real_col(line, self.vcol)
	self:move(line, col, true)
end

function cursor:move_left()  self:move_horiz(-1) end
function cursor:move_right() self:move_horiz(1) end
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
	local line, col = self.buffer:left_word_pos(self.line, self.col)
	self:move(line, col)
end

function cursor:move_right_word()
	local line, col = self.buffer:right_word_pos(self.line, self.col)
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
		self.buffer:remove_string(self.line, self.col, self.line, self.col + str.len(c))
	end
	self:insert_string(c)
end

--delete the char at cursor
function cursor:delete_char()
	local line, col = self.buffer:right_pos(self.line, self.col, true)
	self.buffer:remove_string(self.line, self.col, line, col)
end

--delete the char before the cursor
function cursor:delete_prev_char()
	local line, col = self.buffer:left_pos(self.line, self.col)
	self.buffer:remove_string(line, col, self.line, self.col)
	self:move(line, col)
end

--add a new line, optionally copying the indent of the current line, and carry the cursor over
function cursor:insert_newline()
	local indent
	if self.auto_indent and self.buffer:getline(self.line) then
		local indent_col = self.buffer:indent_col(self.line)
		if indent_col > 1 and self.col >= indent_col then --cursor is after indentation, we're auto-indenting
			indent = self.buffer:sub(self.line, 1, indent_col - 1)
		end
	end
	self:insert_string'\n'
	if indent then
		self:insert_string(indent)
	end
end

--insert a tab character, expanding it according to tab expansion policies
function cursor:insert_tab()
	local line, col = self.buffer:insert_tab(self.line, self.col)
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
