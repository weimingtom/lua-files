local player = require'cplayer'
local glue = require'glue'

local toolbox = {}

function toolbox:new(t)
	self = glue.inherit(t, self)
	if t.screen then
		t.screen:add(self)
	end
	return self
end

function toolbox:hotbox(x, y, w, h)
	if self.screen then
		return self.screen:hotbox(self, x, y, w, h)
	else
		return self.player:hotbox(x, y, w, h)
	end
end

function toolbox:get_title()
	return self.title or self.id
end

function toolbox:get_margin()
	return self.margin or 4
end

function toolbox:window_box()
	local x, y, w, h = self.player:getbox(self)
	w = math.min(math.max(w, self.min_w or 0), self.max_w or 1/0)
	h = math.min(math.max(h, self.min_h or 0), self.max_h or 1/0)
	return x, y, w, h
end

function toolbox:titlebar_box()
	local titlebar_h = self.titlebar_h or 20
	local x, y, w, h = self:window_box()

	local tw, th = w - 1, titlebar_h - 1
	local tx, ty = x + 0.5, y + 0.5
	return tx, ty, tw, th
end

function toolbox:resize_corner_box()
	local resize_r = self.resize_r or 16
	local x, y, w, h = self:window_box()

	local rw, rh = resize_r, resize_r
	local rx = x + w - rw - 0.5
	local ry = y + h - rh - 0.5
	return rx, ry, rw, rh
end

function toolbox:draw_titlebar(hot)
	local tx, ty, tw, th = self:titlebar_box()
	local margin = self:get_margin()
	local title = self:get_title()
	local title_font = self.title_font or 'MS Sans Serif,8'

	if hot then
		self.player.cursor = 'move'
	end
	self.player:rect(tx, ty, tw, th, hot and 'hot_bg' or (self.bg_color or 'normal_bg'), 'normal_fg')
	self.player:textbox(tx + margin, ty, tw - 2*th - margin, th, title, title_font, nil, 'left', 'center')
end

function toolbox:draw_contents()
	local x, y, w, h = self:window_box()
	local tx, ty, tw, th = self:titlebar_box()

	self.player:rect(tx, ty + th, tw, h - th - 1, self.bg_color or 'faint_bg', 'normal_fg')

	if self.contents then
		self.cr:save()
		self.cr:translate(tx, ty + th)
		self:clip_rect(0, 0, tw, h - th - 1)
		self.contents(self)
		self.cr:restore()
	end
end

function toolbox:draw_resize_corner()
	local rx, ry, rw, rh = self:resize_corner_box()

	self.player.cursor = 'resize_nwse'
	self.player.cr:move_to(rx + rw, ry)
	self.player.cr:rel_line_to(0, rh)
	self.player.cr:rel_line_to(-rw, 0)
	self.player.cr:close_path()
	self.player:fillstroke('faint_bg', 'normal_fg')
end

function toolbox:draw_close_button()
	local tx, ty, tw, th = self:titlebar_box()
	local margin = self:get_margin()

	self.player:rect(tx + tw - th + margin, ty + margin, th - 2*margin, th - 2*margin, 'normal_bg', 'normal_fg')
	self.player.cr:move_to(tx + tw - th + margin, ty + margin)
	self.player.cr:rel_line_to(th - 2*margin, th - 2*margin)
	self.player.cr:move_to(tx + tw - th + th - 2*margin + margin, ty + margin)
	self.player.cr:rel_line_to(-(th - 2*margin), th - 2*margin)
	self.player:stroke'normal_fg'
end

function toolbox:draw_minimize_button()
	local tx, ty, tw, th = self:titlebar_box()
	local margin = self:get_margin()

	self.player:rect(tx + tw - 2*th + 2*margin, ty + th - margin - 4, th - 2*margin, 4, 'normal_bg', 'normal_fg')
end

function toolbox:render()
	local id = assert(self.id, 'id missing')

	local margin = self.margin or 4

	local title_hot = self:hotbox(self:titlebar_box())
	local resize_hot = self:hotbox(self:resize_corner_box())

	if not self.player.active and self.player.doubleclicked and title_hot then
		self.minimized = not self.minimized
	end

	if not self.player.active and self.player.lbutton then

		if title_hot then
			self.player.active = id
			local mx, my = self.player.cr:device_to_user(self.player.mousex, self.player.mousey)
			local x, y = self:window_box()
			self.player.ui.dx = mx - x
			self.player.ui.dy = my - y
			self.player.ui.action = 'move'
		elseif resize_hot and not self.minimized then
			self.player.active = id
			local mx, my = self.player.cr:device_to_user(self.player.mousex, self.player.mousey)
			local x, y, w, h = self:window_box()
			self.player.ui.dx = x + w - mx
			self.player.ui.dy = y + h - my
			self.player.ui.action = 'resize'
		end
	elseif self.player.active == id then
		local mx, my = self.player.cr:device_to_user(self.player.mousex, self.player.mousey)
		if self.player.lbutton then
			if self.player.ui.action == 'move' then
				self.x = mx - self.player.ui.dx
				self.y = my - self.player.ui.dy
				if self.screen then
					self.screen:snap_pos(self)
				end
			elseif self.player.ui.action == 'resize' then
				local x, y = self:window_box()
				self.w = mx + self.player.ui.dx - x
				self.h = my + self.player.ui.dy - y
				if self.screen then
					self.screen:snap_size(self)
				end
			end
		else
			self.player.active = nil
		end
	end

	self:draw_titlebar(title_hot)
	self:draw_minimize_button()
	self:draw_close_button()
	if not self.minimized then
		self:draw_contents()
	end
	if not self.minimized and (resize_hot or (self.player.active == id and self.player.ui.action == 'resize')) then
		self:draw_resize_corner()
	end
end

function player:toolbox(t)
	return toolbox:new(t)
end


if not ... then

local screen = player:screen()
local t1 = player:toolbox{id = 'toolbox example', x = 10, y = 10, w = 200, h = 200, screen = screen, bg_color = '#003366'}
local t2 = player:toolbox{id = 'another toolbox', x = 10, y = 250, w = 200, h = 200, screen = screen, bg_color = '#003366'}

player.continuous_rendering = false

function player:on_render(cr)
	screen.player = self
	t1.player = self
	t2.player = self
	screen:render()
end

player:play()

end
