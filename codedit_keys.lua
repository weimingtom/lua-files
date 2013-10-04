--codedit key bindings, command controller and key commands
local editor = require'codedit_editor'

editor.key_bindings = { --flag order is ctrl+alt+shift
	--navigation
	['ctrl+up']     = 'scroll_up',
	['ctrl+down']   = 'scroll_down',
	['left']        = 'move_left',
	['right']       = 'move_right',
	['alt+left']    = 'move_left_unrestricted',
	['alt+right']   = 'move_right_unrestricted',
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

function editor:perform_shortcut(shortcut, ctrl, alt, shift)
	local command = self.key_bindings[shortcut]
	if not command then return end
	self[command](self, ctrl, alt, shift)
end


if not ... then require'codedit_demo' end

