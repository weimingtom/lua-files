--codedit key bindings, command controller and key commands
local editor = require'codedit_editor'

editor.key_bindings = {
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
	['alt+up']      = 'move_up_page',
	['alt+down']    = 'move_down_page',
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
	--special selection
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

--cursor navigation

function editor:move_left()  self.cursor:move_left() end
function editor:move_right() self.cursor:move_right() end
function editor:move_up()    self.cursor:move_up() end
function editor:move_down()  self.cursor:move_down() end
function editor:move_left_word()  self.cursor:move_left_word() end
function editor:move_right_word() self.cursor:move_right_word() end
function editor:move_home()  self.cursor:move_home() end
function editor:move_end()   self.cursor:move_end() end
function editor:move_bol()   self.cursor:move_bol() end
function editor:move_eol()   self.cursor:move_eol() end
function editor:move_up_page()   self.cursor:move_up_page() end
function editor:move_down_page() self.cursor:move_down_page() end

function editor:select_left()  self.cursor:move_left(true) end
function editor:select_right() self.cursor:move_right(true) end
function editor:select_up()    self.cursor:move_up(true) end
function editor:select_down()  self.cursor:move_down(true) end
function editor:select_left_word()  self.cursor:move_left_word(true) end
function editor:select_right_word() self.cursor:move_right_word(true) end
function editor:select_home()  self.cursor:move_home(true) end
function editor:select_end()   self.cursor:move_end(true) end
function editor:select_bol()   self.cursor:move_bol(true) end
function editor:select_eol()   self.cursor:move_eol(true) end
function editor:select_up_page()   self.cursor:move_up_page(true) end
function editor:select_down_page() self.cursor:move_down_page(true) end

function editor:select_block_left()  self.cursor:move_left(true, true) end
function editor:select_block_right() self.cursor:move_right(true, true) end
function editor:select_block_up()    self.cursor:move_up(true, true) end
function editor:select_block_down()  self.cursor:move_down(true, true) end
function editor:select_block_left_word()  self.cursor:move_left_word(true, true) end
function editor:select_block_right_word() self.cursor:move_right_word(true, true) end
function editor:select_block_home()  self.cursor:move_home(true, true) end
function editor:select_block_end()   self.cursor:move_end(true, true) end
function editor:select_block_bol()   self.cursor:move_bol(true, true) end
function editor:select_block_eol()   self.cursor:move_eol(true, true) end
function editor:select_block_up_page()   self.cursor:move_up_page(true, true) end
function editor:select_block_down_page() self.cursor:move_down_page(true, true) end

--cursor editing

function editor:toggle_insert_mode() self.cursor.insert_mode = not self.cursor.insert_mode end
function editor:delete_prev_char() self.cursor:delete_prev_char() end
function editor:delete_char() self.cursor:delete_char() end
function editor:newline() self.cursor:newline() end

function editor:select_all()
	self.cursor:move_home()
	self.cursor:move_end(true)
end

function editor:indent()  self.cursor:indent() end
function editor:outdent() self.cursor:outdent() end
function editor:move_lines_up() self.cursor:move_lines_up() end
function editor:move_lines_down() self.cursor:move_lines_down() end

--key bindings -> commands

editor.undo_group_types = {
	delete_prev_char = 'delete',
	delete_char = 'delete',
	newline = 'insert',
	indent = 'indent',
	outdent = 'outdent',
	move_lines_up = 'move_lines_up',
	move_lines_down = 'move_lines_down',
	cut = 'cut',
	paste = 'paste',
	paste_block = 'paste',
}

function editor:save()
	self:normalize()
	self:save_file(self:contents())
end

--command controller with undo recording

function editor:perform(command)
	if not (command == 'undo' or command == 'redo') then
		self:start_undo_group(self.undo_group_types[command])
	end
	self[command](self)
end

function editor:perform_shortcut(shortcut)
	local command = self.key_bindings[shortcut]
	if not command then return end
	self:perform(command)
end

function editor:perform_char(char)
	self:start_undo_group'insert'
	self.cursor:insert_char(char)
end


if not ... then require'codedit_demo' end

