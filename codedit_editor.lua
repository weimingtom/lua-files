--codedit main class
local glue = require'glue'
local buffer = require'codedit_buffer'
require'codedit_blocks'
require'codedit_undo'
require'codedit_detect'
require'codedit_normal'
local line_selection = require'codedit_selection'
local block_selection = require'codedit_blocksel'
local cursor = require'codedit_cursor'
local line_numbers_margin = require'codedit_line_numbers'

local editor = {
	--defaults
	tabsize = 3, --for tab expansion
	line_numbers = true,
	--subclasses
	buffer = buffer,
	line_selection = line_selection,
	block_selection = block_selection,
	cursor = cursor,
	line_numbers_margin = line_numbers_margin,
}

function editor:new(options)
	self = glue.inherit(options or {}, self)

	--line buffer
	self.buffer = self.buffer:new(self, self.text or '')

	--list of sub-objects for rendering
	self.selections = {} --{selections = true, ...}
	self.cursors = {} --{cursor = true, ...}
	self.margins = {} --{margin1, ...}

	--main cursor & selection objects
	self.cursor = self:create_cursor(true)
	self.line_selection = self:create_line_selection(true)
	self.block_selection = self:create_block_selection(false)
	self.selection = self.line_selection

	--scrolling
	self.scroll_x = 0
	self.scroll_y = 0

	--margins
	if self.line_numbers then
		self:create_line_numbers_margin()
	end

	return self
end

--object constructors

function editor:create_cursor(visible)
	return self.cursor:new(self, visible)
end

function editor:create_line_selection(visible)
	return self.line_selection:new(self, visible)
end

function editor:create_block_selection(visible)
	return self.block_selection:new(self, visible)
end

function editor:create_line_numbers_margin()
	self.line_numbers_margin:new(self)
end

--undo/redo integration

function editor:save_state(state)
	state.line1 = self.selection.line1
	state.line2 = self.selection.line2
	state.col1  = self.selection.col1
	state.col2  = self.selection.col2
	state.line  = self.cursor.line
	state.col   = self.cursor.col
	state.vcol  = self.cursor.vcol
end

function editor:load_state(state)
	self.selection.line1 = state.line1
	self.selection.line2 = state.line2
	self.selection.col1  = state.col1
	self.selection.col2  = state.col2
	self.cursor.line = state.line
	self.cursor.col  = state.col
	self.cursor.vcol = state.vcol
end

--undo/redo commands

function editor:undo() self.buffer:undo() end
function editor:redo() self.buffer:redo() end

--navigation & selection commands

function editor:_before_move_cursor(mode)
	self.buffer:start_undo_group'move'
	if mode == 'select' or mode == 'select_block' then
		if self.selection.block ~= (mode == 'select_block') then
			self.selection.visible = false
			local old_sel = self.selection
			if mode == 'select' then
				self.selection = self.line_selection
			else
				self.selection = self.block_selection
			end
			self.selection:set_to_selection(old_sel)
			self.selection.visible = true
		end
	else
		self.cursor.restrict_eol = nil
	end

	if mode == 'select' or mode == 'select_block' or mode == 'unrestricted' then
		local old_restrict_eol = self.cursor.restrict_eol
		self.cursor.restrict_eol = nil
		self.cursor.restrict_eol = self.cursor.restrict_eol and not self.selection.block and mode ~= 'unrestricted'
		if not old_restrict_eol and self.cursor.restrict_eol then
			self.cursor:move(self.cursor.line, self.cursor.col)
		end
	end
end

function editor:_after_move_cursor(mode)
	if mode == 'select' or mode == 'select_block' then
		self.selection:extend_to_cursor(self.cursor)
	else
		self.selection:reset_to_cursor(self.cursor)
	end
	self.cursor:make_visible()
end

function editor:move_cursor_to_coords(x, y, mode)
	self:_before_move_cursor(mode)
	self.cursor:move_to_coords(x, y)
	self:_after_move_cursor(mode)
end

function editor:move_cursor(direction, mode)
	self:_before_move_cursor(mode)
	self.cursor['move_'..direction](self.cursor)
	self:_after_move_cursor(mode)
end

function editor:move_left()  self:move_cursor('left') end
function editor:move_right() self:move_cursor('right') end
function editor:move_left_unrestricted()  self:move_cursor('left',  'unrestricted') end
function editor:move_right_unrestricted() self:move_cursor('right', 'unrestricted') end
function editor:move_up()    self:move_cursor('up') end
function editor:move_down()  self:move_cursor('down') end
function editor:move_left_word()  self:move_cursor('left_word') end
function editor:move_right_word() self:move_cursor('right_word') end
function editor:move_home()  self:move_cursor('home') end
function editor:move_end()   self:move_cursor('end') end
function editor:move_bol()   self:move_cursor('bol') end
function editor:move_eol()   self:move_cursor('eol') end
function editor:move_up_page()   self:move_cursor('up_page') end
function editor:move_down_page() self:move_cursor('down_page') end

function editor:select_left()  self:move_cursor('left', 'select') end
function editor:select_right() self:move_cursor('right', 'select') end
function editor:select_up()    self:move_cursor('up', 'select') end
function editor:select_down()  self:move_cursor('down', 'select') end
function editor:select_left_word()  self:move_cursor('left_word', 'select') end
function editor:select_right_word() self:move_cursor('right_word', 'select') end
function editor:select_home()  self:move_cursor('home', 'select') end
function editor:select_end()   self:move_cursor('end', 'select') end
function editor:select_bol()   self:move_cursor('bol', 'select') end
function editor:select_eol()   self:move_cursor('eol', 'select') end
function editor:select_up_page()   self:move_cursor('up_page', 'select') end
function editor:select_down_page() self:move_cursor('down_page', 'select') end

function editor:select_block_left()  self:move_cursor('left', 'select_block') end
function editor:select_block_right() self:move_cursor('right', 'select_block') end
function editor:select_block_up()    self:move_cursor('up', 'select_block') end
function editor:select_block_down()  self:move_cursor('down', 'select_block') end
function editor:select_block_left_word()  self:move_cursor('left_word', 'select_block') end
function editor:select_block_right_word() self:move_cursor('right_word', 'select_block') end
function editor:select_block_home()  self:move_cursor('home', 'select_block') end
function editor:select_block_end()   self:move_cursor('end', 'select_block') end
function editor:select_block_bol()   self:move_cursor('bol', 'select_block') end
function editor:select_block_eol()   self:move_cursor('eol', 'select_block') end
function editor:select_block_up_page()   self:move_cursor('up_page', 'select_block') end
function editor:select_block_down_page() self:move_cursor('down_page', 'select_block') end

function editor:select_all()
	self:move_cursor('home')
	self:move_cursor('end', 'select')
end

--editing commands

function editor:toggle_insert_mode()
	self.cursor.insert_mode = not self.cursor.insert_mode
end

function editor:remove_selection()
	if self.selection:isempty() then return end
	self.buffer:start_undo_group'remove_selection'
	self.selection:remove()
	self.cursor:move_to_selection(self.selection)
end

function editor:insert_char(char)
	self:remove_selection()
	self.buffer:start_undo_group'insert_char'
	self.cursor:insert_char(char)
	self.selection:reset_to_cursor(self.cursor)
	self.cursor:make_visible()
end

function editor:delete_prev_char()
	if self.selection:isempty() then
		self.buffer:start_undo_group'delete_char'
		self.cursor:delete_prev_char()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:remove_selection()
	end
	self.cursor:make_visible()
end

function editor:delete_char()
	if self.selection:isempty() then
		self.buffer:start_undo_group'delete_char'
		self.cursor:delete_char()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:remove_selection()
	end
	self.cursor:make_visible()
end

function editor:newline()
	self:remove_selection()
	self.buffer:start_undo_group'insert_newline'
	self.cursor:insert_newline()
	self.selection:reset_to_cursor(self.cursor)
	self.cursor:make_visible()
end

function editor:indent()
	if self.selection:isempty() then
		self.buffer:start_undo_group'insert_tab'
		self.cursor:insert_tab()
		self.selection:reset_to_cursor(self.cursor)
	else
		self.buffer:start_undo_group'indent_selection'
		self.selection:indent()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:outdent()
	if self.selection:isempty() then
		self.buffer:start_undo_group'outdent_line'
		self.cursor:outdent_line()
		self.selection:reset_to_cursor(self.cursor)
	else
		self.buffer:start_undo_group'outdent_selection'
		self.selection:outdent()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:move_lines_up()
	if self.selection:isempty() then
		self.buffer:start_undo_group'move_line_up'
		self.cursor:move_line_up()
		self.selection:reset_to_cursor(self.cursor)
	elseif self.selection.move_lines_up then --block selections don't have that
		self.buffer:start_undo_group'move_selection_up'
		self.selection:move_lines_up()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:move_lines_down()
	if self.selection:isempty() then
		self.buffer:start_undo_group'move_line_down'
		self.cursor:move_line_down()
		self.selection:reset_to_cursor(self.cursor)
	elseif self.selection.move_lines_down then --block selections don't have that
		self.buffer:start_undo_group'move_selection_down'
		self.selection:move_lines_down()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

--clipboard commands

--global clipboard over all editor instances on the same Lua state
local clipboard_contents = ''

function editor:set_clipboard(s)
	clipboard_contents = s
end

function editor:get_clipboard()
	return clipboard_contents
end

function editor:cut()
	if self.selection:isempty() then return end
	local s = self.selection:contents()
	self:set_clipboard(s)
	self.buffer:start_undo_group'cut'
	self.selection:remove()
	self.cursor:move_to_selection(self.selection)
end

function editor:copy()
	if self.selection:isempty() then return end
	self.buffer:start_undo_group'copy'
	self:set_clipboard(self.selection:contents())
end

function editor:paste(mode)
	local s = self:get_clipboard()
	if not s then return end
	self.buffer:start_undo_group'paste'
	self.selection:remove()
	self.cursor:move_to_selection(self.selection)
	if mode == 'block' then
		self.cursor:insert_block(s)
	else
		self.cursor:insert_string(s)
	end
	self.selection:reset_to_cursor(self.cursor)
end

function editor:paste_block()
	self:paste'block'
end

--save command

function editor:save_file(s) end --stub

function editor:save()
	if not self.buffer.changed.file then return end
	self.buffer:start_undo_group'normalize'
	self.buffer:normalize()
	self:save_file(self.buffer:contents())
end


if not ... then require'codedit_demo' end

return editor

