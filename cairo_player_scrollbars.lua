local player = require'cairo_player'

local function bar_size(x, w, size, i)
	return w^2 / size
end

local function bar_offset(x, w, size, i, bw)
	return x + i * (w - bw) / (size - w)
end

local function bar_offset_clamp(bx, x, w, bw)
	return math.min(math.max(bx, x), x + w - bw)
end

local function bar_segment(x, w, size, i)
	local bw = bar_size(x, w, size, i)
	local bx = bar_offset(x, w, size, i, bw)
	bx = bar_offset_clamp(bx, x, w, bw)
	return bx, bw
end

local function view_offset(bx, x, w, size)
	return (bx - x) / w * size
end

local function bar_box(x, y, w, h, size, i, vertical)
	local bx, by, bw, bh
	if vertical then
		by, bh = bar_segment(y, h, size, i)
		bx, bw = x, w
	else
		bx, bw = bar_segment(x, w, size, i)
		by, bh = y, h
	end
	return bx, by, bw, bh
end

local function scrollbar(self, t, vertical)
	local id, x, y, w, h, size, i, autohide = t.id, t.x, t.y, t.w, t.h, t.size, t.i, t.autohide

	if autohide and not self.active == id and not self:hot(x, y, w, h) then
		return i
	end

	local bx, by, bw, bh = bar_box(x, y, w, h, size, i, vertical)
	local hot = self:hot(bx, by, bw, bh)

	if not self.active and self.lbutton and hot then
		self.active = id
		self.grab = vertical and self.mousey - by or self.mousex - bx
	elseif self.active == id then
		if self.lbutton then
			if vertical then
				by = bar_offset_clamp(self.mousey - self.grab, y, h, bh)
				i = view_offset(by, y, h, size)
			else
				bx = bar_offset_clamp(self.mousex - self.grab, x, w, bw)
				i = view_offset(bx, x, w, size)
			end
		else
			self.active = nil
			self.grab = nil
		end
	end

	--drawing
	local cr = self.cr

	cr:rectangle(x, y, w, h)
	self:setcolor'faint_bg'
	cr:fill()

	cr:rectangle(bx, by, bw, bh)
	self:setcolor(self.active == id and 'selected_bg' or hot and 'hot_bg' or 'normal_bg')
	cr:fill()

	return i
end

function player:hscrollbar(t)
	return scrollbar(self, t, false)
end

function player:vscrollbar(t)
	return scrollbar(self, t, true)
end

if not ... then require'cairo_player_ui_demo' end

