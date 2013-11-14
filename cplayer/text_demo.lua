local player = require'cplayer'
local glue = require'glue'

local x1, y1, x2, y2 = 10, 100, 260, 260
local halign = 'center'
local valign = 'center'
local font_size = 12

function player:on_render(cr)

	--text api
	halign = self:mbutton{id = 'halign', x = 10, y = 10, w = 250, h = 26, values = {'left', 'right', 'center'}, selected = halign}
	valign = self:mbutton{id = 'valign', x = 10, y = 40, w = 250, h = 26, values = {'top', 'bottom', 'center'}, selected = valign}
	font_size = self:slider{id = 'font_size', x = 10, y = 70, w = 250, h = 26, i0 = 1, i1 = 100, i = font_size}
	x1, y1 = self:dragpoint{id = 'p1', x = x1, y = y1}
	x2, y2 = self:dragpoint{id = 'p2', x = x2, y = y2}
	--
	self:rect(x1, y1, x2-x1, y2-y1)
	self:textbox(x1, y1, x2-x1, y2-y1, 'tttsssggg\nttt\nggg\nsss', 'Tahoma,'..font_size, nil, halign, valign)

end

return player:play()
