local codedit = require'codedit'
local player = require'cairo_player'
local glue = require'glue'

local editors = {}
local loaded

--text = glue.readfile'x:/work/lua-files/csrc/freetype/src/truetype/ttinterp.c'
--text = glue.readfile'x:/work/lua-files/codedit.lua'
text = glue.readfile'c:/temp.c'

--player.continuous_rendering = false
player.show_magnifier = false

function player:on_render(cr)

	local editor_y = 40
	for i = 1, 1 do
		local w = math.floor(self.w / 2)
		local h = self.h - editor_y - 20
		local x = (i - 1) * w
		local editor = editors[i] or {id = 'code_editor_' .. i, x = x, y = editor_y, w = w, h = h,
												text = text, lexer = nil, eol_markers = false, minimap = false, line_numbers = true,
												font_file = 'x:/work/lua-files/media/fonts/FSEX300.ttf'}
		editor = self:code_editor(editor)
		editor.x = x
		editor.w = w
		editor.h = h

		editor.lexer = self:mbutton{
			id = 'lexer_' .. i,
			x = x, y = 10, w = 180, h = 26, values = {'none', 'cpp', 'lua'}, selected = editor.lexer or 'none'}
		editor.lexer = editor.lexer ~= 'none' and editor.lexer or nil

		editors[i] = editor
	end

	--[[
	v.tabsize = self:slider{id = 'tabsize', x = 10, y = 10, w = 80, h = 24, i0 = 1, i1 = 8, i = v.tabsize}
	v.linesize = self:slider{id = 'linesize', x = 10, y = 40, w = 80, h = 24, i0 = 10, i1 = 30, i = v.linesize}
	b.line_terminator = self:mbutton{id = 'term', x = 10, y = 70, w = 80, h = 24,
		values = {'\r\n', '\r', '\n'}, texts = {['\r\n'] = 'CRLF', ['\n'] = 'LF', ['\r'] = 'CR'},
		selected = b.line_terminator}
	v.eol_markers = self:togglebutton{id = 'eol markers', x = 10, y = 100, w = 80, h = 24, selected = v.eol_markers}
	]]
end

player:play()


