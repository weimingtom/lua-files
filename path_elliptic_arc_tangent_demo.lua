local player = require'cairo_player'
local path_cairo = require'path_cairo'
local tangent_vector = require'path_elliptic_arc'.tangent_vector

local i=1
local sign = 1
function player:on_render(cr)
	i=i+1
	cr:set_source_rgb(0,0,0); cr:paint()
	local draw = path_cairo(cr)

	sign = i % 720 > 360 and -1 or 1

	local cx, cy, rx, ry, start_angle, sweep_angle, rotation = 500, 200, 200, 100, 0, (i % 360)*sign, 30
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
