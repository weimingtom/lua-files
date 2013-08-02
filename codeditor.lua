local codedit = require'codedit'
local player = require'cairo_player'
local glue = require'glue'

local view = codedit.view:new{id = 'view', x = 0, y = 0, w = 0, h = 0}
local buffer = codedit.buffer:new()
local cursor = codedit.cursor:new{buffer = buffer, view = view}

function player:on_render(cr)

	if not self.loaded then
		buffer:load(glue.readfile('codedit.lua'))
		self.loaded = true
	end

	view.eol_markers = false
	view.w = self.w
	view.h = self.h

	cursor.keypressed = cursor.keypressed or function(key) return self:keypressed(key) end
	cursor:keypress(self.key, self.char, self.ctrl, self.shift)
	buffer:keypress(self.key, self.char, self.ctrl, self.shift)

	view:render_selection(cursor.selection, self)
	view:render_buffer(buffer, self)
	view:render_cursor(cursor, self)

end

player:play()

