local player = require'cairo_player'

function player:slider(t)
	local id, x, y, w, h, size, i, step = t.id, t.x, t.y, t.w, t.h or 24, t.size, t.i, t.step or 1
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

	local bar_w = i / size * w

	--drawing
	local cr = self.cr

	cr:rectangle(x, y, bar_w, h)
	self:setcolor'selected_bg'
	cr:fill()

	cr:rectangle(x, y, w, h)
	self:setcolor'faint_bg'
	cr:fill()

	cr:set_font_size(font_size)
	local text = string.format('%.1f', i)
	self:center_text(text, x, y, w, h)
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

	return i
end

if not ... then require'cairo_player_ui_demo' end
