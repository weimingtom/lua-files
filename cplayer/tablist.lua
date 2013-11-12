local player = require'cplayer'
local glue = require'glue'

function player:tablist(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local values = t.values
	local item_w = t.item_w or 80
	local item_h = t.item_h
	local selected = t.selected

	for i,item in ipairs(values) do

		local id1 = id..'_'..i
		local x1, y1, w1, h1 = x, y, item_w, item_h

		if not self.active then
			self.ui.mx0 = nil
		end

		if self.active == id1 then

			if not self.ui.mx0 then
				self.ui.mx0 = self.mousex
				self.ui.my0 = self.mousey
			end

			local mx0, my0 = self.cr:device_to_user(self.ui.mx0, self.ui.my0)
			local mx, my = self.cr:device_to_user(self.mousex, self.mousey)
			x1 = x1 + mx - mx0
		end

		if self:button(glue.merge(
								{id = id1, x = x1, y = y1, w = w1, h = h1, immediate = true,
								text = item, cut = 'both', selected = selected == i}, t))
		then
			selected = i
		end
		x = x + w1
	end
	return selected
end


if not ... then require'cplayer_demo' end

