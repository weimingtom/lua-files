local player = require'cairo_player'
local arc_to_bezier3 = require'path_arc'.to_bezier3
local arc_endpoints = require'path_arc'.endpoints

local i = 60
function player:on_render(cr)

	i = self:slider{
		id = 'angle',
		x = 10, y = 10, w = 200, h = 24, text = 'angle',
		size = 360,
		min = 0,
		i = i,
	}

	local function write(command, ...)
		cr:curve_to(...)
	end
	local function arc(...)
		local x1, y1 = arc_endpoints(...)
		cr:move_to(x1, y1)
		arc_to_bezier3(write, ...)
	end

	local a = i
	local function draw(x, y, cairo_arc, a1, a2, start_angle, sweep_angle)
		cr:set_source_rgba(0,1,0,0.3)
		cr:set_line_width(1)
		cairo_arc(cr, x, y, 100, math.rad(a1), math.rad(a2))
		cr:stroke()
		cr:new_path()
		cr:set_line_width(10)
		arc(x, y, 100, start_angle, sweep_angle)
		cr:stroke()
	end
	draw(300, 200, cr.arc, a, 2*a, a, a)
	draw(600, 200, cr.arc, 2*a, a, 2*a, 360 - a % 360)
	draw(300, 500, cr.arc_negative, -a, -2*a, -a, -a)
	draw(600, 500, cr.arc_negative, -2*a, -a, -2*a, -360 + a % 360)
end

player:play()

