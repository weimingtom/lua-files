local player = require'cairo_player'
local bezier2 = require'path_bezier2_ai'
local glue = require'glue'

local scale = 1

function player:on_render(cr)

	scale = self:slider{id = 'scale',
		x = 10, y = 10, w = 400, h = 24, text = 'scale',
		i1 = 10, i0 = 0.01, step = 0.01, i = scale,
	}

	local function label(x, y, ...)
		cr:move_to(x, y)
		cr:select_font_face('Arial', 0, 0)
		cr:set_font_size(14)
		cr:text_path(string.format(...))
		cr:set_source_rgb(1,1,1)
		cr:fill()
	end

	local lines, dots
	local function write(cmd, x2, y2)
		lines = lines + 1
		cr:line_to(x2, y2)
		glue.append(dots, x2, y2)
	end
	local function bez(cpx,cpy,x2,y2,x3,y3)
		lines = 0
		dots = {}
		cr:move_to(cpx,cpy)
		glue.append(dots, cpx, cpy)
		bezier2(write, cpx, cpy, x2, y2, x3, y3, scale)
		cr:set_source_rgb(1,1,1)
		cr:set_line_width(2)
		cr:stroke()

		cr:set_source_rgb(0,0,1)
		cr:set_line_width(3)
		for i=1,#dots,2 do
			local x,y = dots[i], dots[i+1]
			cr:rectangle(x-1,y-1,2,2)
		end
		cr:fill()

		label(cpx, cpy - 10, 'segments: %d', lines)
	end

	cr:translate(100,100)
	bez(0,0,50,1000,100,0)

	cr:translate(200,0)
	bez(0,0,100,250,0,500)

	cr:translate(200,0)
	bez(0,0,0,250,0,500)

	cr:translate(200,0) --case of symmetrical bezier with cp1 == cpx
	bez(0,0,0,0,0,500)

	cr:translate(200,0)
	bez(0,0,0,300,0,500)
end

player:play()

