--codedit key bindings, command controller and key commands
local editor = require'codedit_editor'

editor.key_bindings = { --flag order is ctrl+alt+shift
	--navigation
	['ctrl+up']     = 'scroll_up',
	['ctrl+down']   = 'scroll_down',
	['left']        = 'move_left',
	['right']       = 'move_right',
	['up']          = 'move_up',
	['down']        = 'move_down',
	['ctrl+left']   = 'move_left_word',
	['ctrl+right']  = 'move_right_word',
	['home']        = 'move_bol',
	['end']         = 'move_eol',
	['ctrl+home']   = 'move_home',
	['ctrl+end']    = 'move_end',
	['pageup']      = 'move_up_page',
	['pagedown']    = 'move_down_page',
	--navigation + selection
	['shift+left']       = 'select_left',
	['shift+right']      = 'select_right',
	['shift+up']         = 'select_up',
	['shift+down']       = 'select_down',
	['ctrl+shift+left']  = 'select_left_word',
	['ctrl+shift+right'] = 'select_right_word',
	['shift+home']       = 'select_bol',
	['shift+end']        = 'select_eol',
	['ctrl+shift+home']  = 'select_home',
	['ctrl+shift+end']   = 'select_end',
	['shift+pageup']     = 'select_up_page',
	['shift+pagedown']   = 'select_down_page',
	--navigation + block selection
	['alt+shift+left']       = 'select_block_left',
	['alt+shift+right']      = 'select_block_right',
	['alt+shift+up']         = 'select_block_up',
	['alt+shift+down']       = 'select_block_down',
	['ctrl+alt+shift+left']  = 'select_block_left_word',
	['ctrl+alt+shift+right'] = 'select_block_right_word',
	['alt+shift+home']       = 'select_block_bol',
	['alt+shift+end']        = 'select_block_eol',
	['ctrl+alt+shift+home']  = 'select_block_home',
	['ctrl+alt+shift+end']   = 'select_block_end',
	['alt+shift+pageup']     = 'select_block_up_page',
	['alt+shift+pagedown']   = 'select_block_down_page',
	--additional navigation
	['alt+up']      = 'move_up_page',
	['alt+down']    = 'move_down_page',
	--additional selection
	['ctrl+A']      = 'select_all',
	--editing
	['insert']      = 'toggle_insert_mode',
	['backspace']   = 'delete_prev_char',
	['delete']      = 'delete_char',
	['return']      = 'newline',
	['tab']         = 'indent',
	['shift+tab']   = 'outdent',
	['ctrl+shift+up']   = 'move_lines_up',
	['ctrl+shift+down'] = 'move_lines_down',
	['ctrl+Z']      = 'undo',
	['ctrl+Y']      = 'redo',
	--copy/pasting
	['ctrl+X']      = 'cut',
	['ctrl+C']      = 'copy',
	['ctrl+V']      = 'paste',
	['ctrl+alt+V']  = 'paste_block',
	--saving
	['ctrl+S']      = 'save',
}

--cursor-based navigation & selection

function editor:move_cursor_to_coords(x, y, mode)
	self:start_undo_group'move'
	self.cursor:move_to_coords(x, y)
	if mode == 'select' then
		self.selection:extend_to_cursor(self.cursor)
	else
		self.selection:reset_to_cursor(self.cursor)
	end
	self.cursor:make_visible()
end

function editor:move_cursor(direction, mode)
	self:start_undo_group'move'
	self.cursor['move_'..direction](self.cursor)
	if mode == 'select' then
		self.selection:extend_to_cursor(self.cursor)
	elseif mode == 'block_select' then
		self.selection:extend_to_cursor(self.cursor)
	else
		self.selection:reset_to_cursor(self.cursor)
	end
	self.cursor:make_visible()
end

function editor:move_left()  self:move_cursor('left') end
function editor:move_right() self:move_cursor('right') end
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

--cursor-based editing

function editor:toggle_insert_mode()
	self.cursor.insert_mode = not self.cursor.insert_mode
end

function editor:remove_selection()
	if self.selection:isempty() then return end
	self:start_undo_group'remove_selection'
	self.selection:remove()
	self.cursor:move_to_selection(self.selection)
end

function editor:insert_char(char)
	self:remove_selection()
	self:start_undo_group'insert_char'
	self.cursor:insert_char(char)
	self.selection:reset_to_cursor(self.cursor)
	self.cursor:make_visible()
end

function editor:delete_prev_char()
	if self.selection:isempty() then
		self:start_undo_group'delete_char'
		self.cursor:delete_prev_char()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:remove_selection()
	end
	self.cursor:make_visible()
end

function editor:delete_char()
	if self.selection:isempty() then
		self:start_undo_group'delete_char'
		self.cursor:delete_char()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:remove_selection()
	end
	self.cursor:make_visible()
end

function editor:newline()
	self:remove_selection()
	self:start_undo_group'insert_newline'
	self.cursor:insert_newline()
	self.selection:reset_to_cursor(self.cursor)
	self.cursor:make_visible()
end

function editor:indent()
	if self.selection:isempty() then
		self:start_undo_group'insert_tab'
		self.cursor:insert_tab()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:start_undo_group'indent_selection'
		self.selection:indent(self.tabs ~= 'always')
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:outdent()
	if self.selection:isempty() then
		self:start_undo_group'outdent_line'
		self.cursor:outdent_line()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:start_undo_group'outdent_selection'
		self.selection:outdent()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:move_lines_up()
	if self.selection:isempty() then
		self:start_undo_group'move_line_up'
		self.cursor:move_line_up()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:start_undo_group'move_selection_up'
		self.selection:move_lines_up()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:move_lines_down()
	if self.selection:isempty() then
		self:start_undo_group'move_line_down'
		self.cursor:move_line_down()
		self.selection:reset_to_cursor(self.cursor)
	else
		self:start_undo_group'move_selection_down'
		self.selection:move_lines_down()
		self.cursor:move_to_selection(self.selection)
	end
	self.cursor:make_visible()
end

function editor:save_file(s) end --stub

function editor:save()
	self:start_undo_group'normalize'
	self:normalize()
	self:save_file(self:contents())
end

function editor:perform_shortcut(shortcut, ctrl, alt, shift)
	local command = self.key_bindings[shortcut]
	if not command then return end
	self[command](self, ctrl, alt, shift)
end


if not ... then require'codedit_demo' end

