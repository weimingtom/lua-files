--codedit key bindings and commands
local editor = require'codedit_editor'

editor.key_bindings = {
	--navigation
	['ctrl+up']     = 'line_up',
	['ctrl+down']   = 'line_down',
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
	['backspace']   = 'delete_before_cursor',
	['delete']      = 'delete_after_cursor',
	['return']      = 'newline',
	['tab']         = 'indent',
	['shift+tab']   = 'outdent',
	--copy/pasting
	['ctrl+X']      = 'cut',
	['ctrl+C']      = 'copy',
	['ctrl+V']      = 'paste',
	['ctrl+alt+V']  = 'paste_block',
	--saving
	['ctrl+S']      = 'save',
}

editor.commands = {}
local commands = editor.commands

--navigation

function commands:line_up()
	self:scroll_by(0, self.linesize)
	--TODO: move cursor into view
end

function commands:line_down()
	self:scroll_by(0, -self.linesize)
	--TODO: move cursor into view
end

--navigation/selection

function commands:move_left()  self.cursor:move_left() end
function commands:move_right() self.cursor:move_right() end
function commands:move_up()    self.cursor:move_up() end
function commands:move_down()  self.cursor:move_down() end
function commands:move_left_word()  self.cursor:move_left_word() end
function commands:move_right_word() self.cursor:move_right_word() end
function commands:move_home()  self.cursor:move_home() end
function commands:move_end()   self.cursor:move_end() end
function commands:move_bol()   self.cursor:move_bol() end
function commands:move_eol()   self.cursor:move_eol() end
function commands:move_up_page()   self.cursor:move_up_page() end
function commands:move_down_page() self.cursor:move_down_page() end

function commands:select_left()  self.cursor:move_left(1, true) end
function commands:select_right() self.cursor:move_right(1, true) end
function commands:select_up()    self.cursor:move_up(1, true) end
function commands:select_down()  self.cursor:move_down(1, true) end
function commands:select_left_word()  self.cursor:move_left_word(true) end
function commands:select_right_word() self.cursor:move_right_word(true) end
function commands:select_home()  self.cursor:move_home(true) end
function commands:select_end()   self.cursor:move_end(true) end
function commands:select_bol()   self.cursor:move_bol(true) end
function commands:select_eol()   self.cursor:move_eol(true) end
function commands:select_up_page()   self.cursor:move_up_page(true) end
function commands:select_down_page() self.cursor:move_down_page(true) end

function commands:select_block_left()  self.cursor:move_left(1, true, true) end
function commands:select_block_right() self.cursor:move_right(1, true, true) end
function commands:select_block_up()    self.cursor:move_up(1, true, true) end
function commands:select_block_down()  self.cursor:move_down(1, true, true) end
function commands:select_block_left_word()  self.cursor:move_left_word(true, true) end
function commands:select_block_right_word() self.cursor:move_right_word(true, true) end
function commands:select_block_home()  self.cursor:move_home(true, true) end
function commands:select_block_end()   self.cursor:move_end(true, true) end
function commands:select_block_bol()   self.cursor:move_bol(true, true) end
function commands:select_block_eol()   self.cursor:move_eol(true, true) end
function commands:select_block_up_page()   self.cursor:move_up_page(true, true) end
function commands:select_block_down_page() self.cursor:move_down_page(true, true) end

--editing

function commands:toggle_insert_mode()
	self.cursor.insert_mode = not self.cursor.insert_mode
end

function commands:delete_before_cursor()
	self.cursor:delete_before()
end

function commands:delete_after_cursor()
	self.cursor:delete_after()
end

function commands:newline() self.cursor:newline() end

function commands:select_all()
	self.cursor:move_home()
	self.cursor:move_end(true)
end

function commands:indent()  self.cursor:indent() end
function commands:outdent() self.cursor:outdent() end

function commands:cut()
	local s = self.cursor.selection:contents()
	self:set_clipboard(s)
	self.cursor.selection:remove()
end

function commands:copy()
	self:set_clipboard(self.cursor.selection:contents())
end

function commands:paste()
	local s = self:get_clipboard()
	self.cursor.selection:remove()
	self.cursor:insert_string(s)
end

function commands:paste_block()
	local s = self:get_clipboard()
	self.cursor.selection:remove()
	self.cursor:insert_block(s)
end

function commands:save()
	self:normalize()
	self:save_file(self:contents())
end

