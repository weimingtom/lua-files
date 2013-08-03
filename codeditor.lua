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

	if self.ctrl and self.key == 'S' then
		return buffer:save()
	end

	local c = cursor
	if self.lbutton then
		if not c.selecting then
			c.selecting = true
			c:mousefocus(self.mousex, self.mousey)
		else
			local line, vcol = c.view:cursor_at(self.mousex, self.mousey)
			local col = c.view:real_col(c.buffer.lines[c.line], vcol) - 1
			c.selection:move(line, col, true)
			c.line = c.selection.line2
			c.col = c.selection.col2
		end
	else
		c.selecting = false
	end

	view:render_selection(cursor.selection, self)
	view:render_buffer(buffer, self)
	view:render_cursor(cursor, self)

end

player:play()

