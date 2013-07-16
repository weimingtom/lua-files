--a dragpoint is a square point that you can drag around, use as a handle.
local player = require'cairo_player'

function player:dragpoint(t)
	local id = assert(t.id, 'id missing')
	local x = assert(t.x, 'x missing')
	local y = assert(t.y, 'y missing')
	local radius = t.radius or 5
	local threshold = t.threshold or radius + 2

	local down = self.lbutton
	local hot = self:hotbox(x-threshold, y-threshold, 2*threshold, 2*threshold)

	if not self.active and hot and down then
		self.active = id
	elseif self.active == id then
		if not down then
			self.active = nil
		else
			x, y = self.mousex, self.mousey
		end
	end

	self:rect(x-radius, y-radius, 2*radius, 2*radius,
				t.fill or self.active == id and 'selected_bg' or hot and 'hot_bg' or 'normal_bg')

	return x, y
end

