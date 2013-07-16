local player = require'cairo_player'
local path_cairo = require'path_cairo'
local tangent_vector = require'path_arc'.tangent_vector

local angle = 0
local clockwise = true

function player:on_render(cr)

	angle = self:slider{id = 'angle',
		x = 10, y = 10, w = 200, h = 24, text = 'angle',
		i1 = 360, i0 = 0, i = angle}

	clockwise = self:togglebutton{id = 'sign',
		x = 220, y = 10, w = 80, h = 24, text = 'clockwise',
		selected = clockwise}

	local cx, cy, rx, ry, start_angle, sweep_angle, rotation = 500, 200, 200, 100, 0, (angle % 360)*(clockwise and 1 or -1), 30

	draw{'elliptic_arc', cx, cy, rx, ry, start_angle, sweep_angle, rotation}
	cr:set_source_rgb(1,1,1)
	cr:stroke()

	local px, py, tx, ty = tangent_vector(1, cx, cy, rx, ry, start_angle, sweep_angle, rotation)

	cr:circle(cx, cy, 5)
	cr:circle(px, py, 5)
	cr:circle(tx, ty, 5)
	cr:fill()

	cr:move_to(px, py)
	cr:line_to(tx, ty)
	cr:stroke()
end

player:play()
