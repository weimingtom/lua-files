local player = require'cairo_player'

function player:slider(t)
	local id, x, y, w, h, size, i, step, min = t.id, t.x, t.y, t.w, t.h or 24, t.size, t.i, t.step or 1, t.min
	x = x or self.cpx
	y = y or self.cpy
	local font_size = t.font_size or h / 2

	if not self.active and self.lbutton and self:hot(x, y, w, h) then
		self.active = id
	elseif self.active == id then
		if self.lbutton then
			local w1 = math.min(math.max(self.mousex - x, 0), w)
			i = w1 / w * size
			i = i % step < step - i % step and i - i % step or i + step - i % step
		else
			self.active = nil
		end
	end
	i = math.min(math.max(i, min or 0), size)

	local bar_w = i / size * w

	--drawing
	local cr = self.cr

	cr:rectangle(x, y, w, h)
	self:setcolor'faint_bg'
	cr:fill()

	cr:rectangle(x, y, bar_w, h)
	self:setcolor'selected_bg'
	cr:fill()

	cr:rectangle(x, y, w, h)
	self:setcolor'normal_border'
	cr:set_line_width(self.theme.border_width)
	cr:stroke()

	cr:set_font_size(font_size)
	local text = string.format('%.1f', i)
	self:aligntext(text, x, y, w, h, 'center', 'middle')
	cr:text_path(text)

	cr:save()
	cr:clip()
		cr:rectangle(x + bar_w, y, w, h)
		self:setcolor'selected_bg'
		cr:fill()

		cr:rectangle(x, y, bar_w, h)
		self:setcolor'selected_fg'
		cr:fill()
	cr:restore()

	self:advance(x, y, w, h)
	return i
end

if not ... then require'cairo_player_ui_demo' end
