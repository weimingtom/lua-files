--codedit margins
local glue = require'glue'

local margin = {
	side = 'left', --left, right
	w = 50,
	background_color = nil, --custom color
	text_color = nil, --custom color
}

function margin:new(editor, t, pos)
	self = glue.inherit(t or {}, self)
	self.editor = editor
	table.insert(editor.margins, pos or #editor.margins + 1, self)
	return self
end

function margin:free()
	for i=1,#self.editor.margins do
		if self.editor.margins[i] == self then
			table.remove(self.editor.margins, i)
			break
		end
	end
end

function margin:get_width()
	return self.w
end

function margin:coords(line)
	return self.editor:margin_coords(self, line)
end

function margin:draw_line(line, x, y) end --stub

function margin:draw_background()
	local color = self.background_color or 'margin_background'
	local x, y, w, h = self.editor:clip_rect()
	w = self:get_width()
	x = x - w
	self.editor:draw_rect(x, y, w, h, color)
end

function margin:draw_contents()
	local minline, maxline = self.editor:visible_lines()
	for line = minline, maxline do
		local x, y = self.editor:text_coords(line, 1)
		self:draw_line(line, x, y)
		y = y + self.editor.linesize
	end
end

function margin:draw()
	self:draw_background()
	self:draw_contents()
end

return margin

