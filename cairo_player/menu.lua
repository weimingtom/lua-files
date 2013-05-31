local player = require'cairo_player'

function player:menu(t)
	local id = t.id
	local x = t.x or self.cpx
	local y = t.y or self.cpy
	local w, h, items = t.w, t.h, t.items
	local item_h = t.item_h or 24
	local selected = t.selected

	local clicked
	for i,item in ipairs(items) do
		if self:button{id = id..'_'..item, x = x, y = y, w = w, h = item_h,
								text = item, cut = 'both', selected = selected == item}
		then
			selected = item
			clicked = true
		end
		y = y + item_h
	end
	return selected, clicked
end

if not ... then require'cairo_player_ui_demo' end

