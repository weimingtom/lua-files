local player = require'cairo_player'

local function clamp(i, i0, i1)
	return math.min(math.max(i, i0), i1)
end

local function lerp(x, x0, x1, y0, y1)
	return y0 + (x-x0) * ((y1-y0) / (x1 - x0))
end

local function snap(i, step)
	return i % step < step - i % step and i - i % step or i + step - i % step
end

function player:slider(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local font_size = t.font_size or h / 2
	local text = t.text

	local i0, i1, step = t.i0 or 0, t.i1 or 100, t.step or 1
	local i = t.i or i0

	if not self.active and self.lbutton and self:hotbox(x, y, w, h) then
		self.active = id
	elseif self.active == id then
		if self.lbutton then
			local w1 = clamp(self.mousex - x, 0, w)
			i = lerp(w1, 0, w, i0, i1)
		else
			self.active = nil
		end
	end
	i = snap(i, step)
	i = clamp(i, i0, i1)

	local w1 = lerp(i, i0, i1, 0, w)
	text = (text and (text .. ': ') or '') .. tostring(i)

	--drawing
	self:rect(x, y, w, h, 'faint_bg', 'normal_border')
	self:rect(x, y, w1, h, 'selected_bg')

	self:text_path(text, font_size, 'center', 'middle', x, y, w, h)
	self.cr:save()
	self.cr:clip()
		self:rect(x + w1, y, w, h, 'selected_bg')
		self:rect(x, y, w1, h, 'selected_fg')
	self.cr:restore()

	return i
end

if not ... then require'cairo_player_demo' end
