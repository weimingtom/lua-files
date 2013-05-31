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
	local id = assert(t.id, 'id missing')
	local x = t.x or self.cpx
	local y = t.y or self.cpy
	local w = assert(t.w or     vertical and self.theme.scrollbar_width, 'w missing')
	local h = assert(t.h or not vertical and self.theme.scrollbar_width, 'h missing')
	local size = assert(t.size, 'size missing')
	local i = t.i or 0

	if t.autohide and
		((self.active and self.active ~= id) or
		(not self.active and not self:hot(x, y, w, h)))
	then
		return i
	end

	local bx, by, bw, bh = bar_box(x, y, w, h, size, i, vertical)
	local hot = self:hot(bx, by, bw, bh)

	if not self.active and self.lbutton and hot then
		self.active = id
		self.ui.grab = vertical and self.mousey - by or self.mousex - bx
	elseif self.active == id then
		if self.lbutton then
			if vertical then
				by = bar_offset_clamp(self.mousey - self.ui.grab, y, h, bh)
				i = view_offset(by, y, h, size)
			else
				bx = bar_offset_clamp(self.mousex - self.ui.grab, x, w, bw)
				i = view_offset(bx, x, w, size)
			end
		else
			self.active = nil
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

	self:advance(x, y, w, h)
	return i
end

function player:hscrollbar(t)
	return scrollbar(self, t, false)
end

function player:vscrollbar(t)
	return scrollbar(self, t, true)
end

function player:scrollbox(t)
	local id = t.id
	local x = t.x or self.cpx
	local y = t.y or self.cpy
	local w = assert(t.w, 'w missing')
	local h = assert(t.h, 'h missing')
	local vs = t.vscrollbar
	local hs = t.hscrollbar
	local vs_w = vs and not vs.autohide and (vs.w or self.theme.scollbar_width) or 0
	local hs_h = hs and not hs.autohide and (hs.h or self.theme.scollbar_width) or 0

	self:pushclip(x, y, w - vs_w, h - hs_h)
end

if not ... then require'cairo_player_ui_demo' end

