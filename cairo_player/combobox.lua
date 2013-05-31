local player = require'cairo_player'

function player:combobox(t)
	local id = t.id
	local x = t.x or self.cpx
	local y = t.y or self.cpy
	local w = t.w
	local h = t.h or 24
	local items, selected = t.items, t.selected
	local text = selected or 'pick...'

	local menu_h = 100

	local down = self.lbutton
	local hot = self:hot(x, y, w, h)

	if not self.active and hot and down then
		self.active = id
	elseif self.active == id then
		if hot and self.click then
			if not self.cmenu then
				local menu_id = id .. '_menu'
				self.cmenu = {id = menu_id, x = x, y = y + h, w = w, h = menu_h, items = items}
				self.active = nil
			else
				self.cmenu = nil
			end
		elseif not hot then
			self.active = nil
			self.cmenu = nil
		end
	end

	--drawing
	local cr = self.cr

	cr:rectangle(x, y, w, h)
	self:setcolor'faint_bg'
	cr:fill()

	self:aligntext(text, x, y, w, h, 'left', 'middle')
	self:setcolor'normal_fg'
	cr:show_text(text)

	return self.cmenu
end

if not ... then require'cairo_player_ui_demo' end

