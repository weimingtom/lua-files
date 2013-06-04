local player = require'cairo_player'

function player:slider(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local size, i, step, min = t.size, t.i, t.step or 1, t.min
	local font_size = t.font_size or h / 2
	local text = t.text

	if not self.active and self.lbutton and self:hotbox(x, y, w, h) then
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
	text = (text and (text .. ': ') or '') .. tostring(i)

	--drawing
	self:rect(x, y, w, h, 'faint_bg', 'normal_border')
	self:rect(x, y, bar_w, h, 'selected_bg')

	self:text_path(text, font_size, 'center', 'middle', x, y, w, h)
	self.cr:save()
	self.cr:clip()
		self:rect(x + bar_w, y, w, h, 'selected_bg')
		self:rect(x, y, bar_w, h, 'selected_fg')
	self.cr:restore()

	return i
end

if not ... then require'cairo_player_demo' end
