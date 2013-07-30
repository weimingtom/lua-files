local player = require'cairo_player'
local glue = require'glue'

function player:label(t)
	local x = assert(t.x, 'x missing')
	local y = assert(t.y, 'y missing')
	local w = t.w or 1000
	local h = t.h or 1000
	local font_size = t.font_size or 12
	local line_size = font_size * 1.5
	local text = assert(t.text, 'text missing')

	for text in glue.gsplit(text, '\n') do
		--TODO: align bottom with multiline text
		self:text(text, font_size, t.color or 'normal_fg',
					t.halign or 'left',
					t.valign or 'top', x, y, w, h)
		y = y + line_size
	end
end

