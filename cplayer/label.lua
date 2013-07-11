local player = require'cairo_player'

function player:label(t)
	local x = assert(t.x, 'x missing')
	local y = assert(t.y, 'y missing')
	local w = t.w or 1000
	local h = t.h or 1000
	local text = assert(t.text, 'text missing')
	self:text(text, t.font_size or 12, t.color or 'normal_fg',
				t.halign or 'left',
				t.valign or 'top', x, y, w, h)
end

