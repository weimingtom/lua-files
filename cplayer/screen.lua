--screen: window manager for rendering, hit-testing, reordering, and snapping overlapping windows
local player = require'cplayer'
local glue = require'glue'

local screen = {}

function screen:new(t)
	self = glue.inherit(t or {}, self)
	self.windows = {}
	return self
end

function screen:add(window, z_order)
	z_order = z_order or 0
	local index = #self.windows - z_order + 1
	index = math.min(math.max(index, 1), #self.windows + 1)
	table.insert(self.windows, index, window)
end

function screen:indexof(target_window)
	for i,window in ipairs(self.windows) do
		if window == target_window then
			return i
		end
	end
end

function screen:remove(window)
	table.remove(self.windows, self:indexof(window))
end

function screen:bring_to_front(window)
	self:remove(window)
	self:add(window, 0)
end

function screen:send_to_back(window)
	self:remove(window)
	self:add(window, 1/0)
end

function screen:render()

	if not self.player.active and self.player.lbutton then
		for i=#self.windows,1,-1 do
			local window = self.windows[i]
			if self.player:hotbox(window:window_box()) then
				self:bring_to_front(window)
				break
			end
		end
	end

	for i,window in ipairs(self.windows) do
		window:render()
	end
end

function screen:hotbox(target_window, x, y, w, h)
	for i=#self.windows,1,-1 do
		local window = self.windows[i]
		if window == target_window then
			return self.player:hotbox(x, y, w, h)
		elseif self.player:hotbox(window:window_box()) then
			break
		end
	end
	return false
end

local function near(x1, x2, d)
	return math.abs(x1 - x2) < d
end

local function overlap(x1, w1, x2, w2, d)
	return not (x1 + w1 < x2 or x2 + w2 < x1)
end

function screen:snap_pos(win0, d)
	d = d or 10
	for i,win in ipairs(self.windows) do
		if win ~= win0 then
			local x1, y1

			if near(win0.y, win.y + win.h, d) then
				y1 = win.y + win.h
			elseif near(win0.y + win0.h, win.y, d) then
				y1 = win.y - win0.h
			elseif near(win0.y, win.y, d) then
				y1 = win.y
			elseif near(win0.y + win0.h, win.y + win.h, d) then
				y1 = win.y + win.h - win0.h
			end

			if near(win0.x, win.x + win.w, d) then
				x1 = win.x + win.w
			elseif near(win0.x + win0.w, win.x, d) then
				x1 = win.x - win0.w
			elseif near(win0.x, win.x, d) then
				x1 = win.x
			elseif near(win0.x + win0.w, win.x + win.w, d) then
				x1 = win.x + win.w - win0.w
			end

			if (y1 and overlap(win0.x, win0.w, win.x, win.w, d)) or
				(x1 and overlap(win0.y, win0.h, win.y, win.h, d))
			then
				win0.x = x1 or win0.x
				win0.y = y1 or win0.y
			end
		end
	end
end

function screen:snap_size(win0, d)
	d = d or 10
	for i,win in ipairs(self.windows) do
		if win ~= win0 then
			local w1, h1

			if near(win0.y + win0.h, win.y, d) then
				h1 = win.y - win0.y
			end

			if near(win0.x + win0.w, win.x, d) then
				w1 = win.x - win0.x
			end

			if (w1 and overlap(win0.x, win0.w, win.x, win.w, d)) or
				(h1 and overlap(win0.y, win0.h, win.y, win.h, d))
			then
				win0.w = w1 or win0.w
				win0.h = h1 or win0.h
			end
		end
	end
end

function player:screen(t)
	return screen:new(t)
end

