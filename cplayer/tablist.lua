local player = require'cairo_player'

function player:tablist(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local values = t.values
	local item_w = t.item_w or 80
	local item_h = t.item_h or 22
	local selected = t.selected

	for i,item in ipairs(values) do
		if self:button{id = id..'_'..item, x = x, y = y, w = item_w, h = item_h,
								text = item, cut = 'both', selected = selected == i}
		then
			selected = item
		end
		x = x + item_w
	end
	return selected
end


if not ... then require'cairo_player_demo' end

