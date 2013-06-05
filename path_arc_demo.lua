local player = require'cairo_player'
local arc_to_bezier3 = require'path_arc'.to_bezier3
local arc_endpoints = require'path_arc'.endpoints

local start_angle = 30
local sweep_angle = 180

local start_angle2 = 0
local sweep_angle2 = 0

function player:on_render(cr)

	start_angle = self:slider{
		id = 'start_angle',
		x = 10, y = 10, w = 200, h = 24, text = 'start angle',
		i0 = 0,
		i1 = 360,
		i = start_angle,
	}

	sweep_angle = self:slider{
		id = 'sweep_angle',
		x = 10, y = 40, w = 200, h = 24, text = 'sweep angle',
		i0 = -360,
		i1 = 360,
		i = sweep_angle,
	}

	local function write(command, ...)
		cr:curve_to(...)
	end
	local function arc(...)
		local x1, y1 = arc_endpoints(...)
		cr:move_to(x1, y1)
		arc_to_bezier3(write, ...)
	end

	local function draw(x, y, cairo_arc, start_angle, sweep_angle)
		cr:set_source_rgba(0,1,0,0.3)
		cr:set_line_width(1)
		cairo_arc(cr, x, y, 100, math.rad(start_angle), math.rad(start_angle + sweep_angle))
		cr:stroke()
		cr:new_path()
		cr:set_line_width(10)
		arc(x, y, 100, start_angle, sweep_angle)
		cr:stroke()
	end
	draw(300, 150, sweep_angle > 0 and cr.arc or cr.arc_negative, start_angle, sweep_angle)

	sweep_angle2 = sweep_angle2 + 2
	start_angle2 = start_angle2 + 1
	if sweep_angle2 > 360 then
		sweep_angle2 = -360
	end
	draw(600, 150, sweep_angle2 > 0 and cr.arc or cr.arc_negative, start_angle2, sweep_angle2)
end

player:play()

