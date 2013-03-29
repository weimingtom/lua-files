local player = require'cairo_player'
local bezier3 = require'path_bezier3_ai'
local glue = require'glue'

local i=1
function player:on_render(cr)
	i=i+1/i
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local function label(x, y, ...)
		cr:move_to(x, y)
		cr:select_font_face('Arial', 0, 0)
		cr:set_font_size(28)
		cr:text_path(string.format(...))
		cr:set_source_rgb(1,1,1)
		cr:fill()
	end

	--path writer
	local lines, dots
	local function write(cmd, x2, y2)
		lines = lines + 1
		cr:line_to(x2, y2)
		glue.append(dots, x2, y2)
	end

	local r = i/100
	local function bez(cpx, cpy, x2, y2, x3, y3, x4, y4)

		--handle lines
		cr:move_to(cpx,cpy)
		cr:line_to(x2,y2)
		cr:move_to(x4,y4)
		cr:line_to(x3,y3)
		cr:set_source_rgb(0,1,0)
		cr:set_line_width(1)
		cr:stroke()

		--curve
		lines = 0
		dots = {}
		cr:move_to(cpx,cpy)
		bezier3(write, cpx, cpy, x2, y2, x3, y3, x4, y4, r)
		cr:set_source_rgb(1,1,1)
		cr:set_line_width(2)
		cr:stroke()

		--control points
		cr:rectangle(x2-3,y2-3,6,6)
		cr:rectangle(x3-3,y3-3,6,6)
		cr:set_source_rgb(1,0,0)
		cr:fill()

		--end points
		cr:rectangle(cpx-3,cpy-3,6,6)
		cr:rectangle(x4-3,y4-3,6,6)
		cr:set_source_rgb(1,0,1)
		cr:fill()

		--segment dots
		for i=1,#dots,2 do
			local x,y = dots[i], dots[i+1]
			cr:rectangle(x-2,y-2,4,4)
		end
		cr:set_source_rgb(0,0,1)
		cr:fill()

		label(cpx, cpy - 10, 'segments: %d', lines)
	end

	local function reset()
		cr:identity_matrix()
		cr:scale(.5, .5)
	end

	reset()

	label(100, 40, 'scale: %f', r)

	cr:translate(100,100)
	bez(0,0,150,150,250,150,400,0)

	cr:translate(0,200)
	bez(0,0,400,150,0,150,400,0)

	cr:translate(0,200)
	bez(0,0,500,150,-100,150,400,0)

	cr:translate(0,200)
	bez(0,0,-200,0,600,0,400,0)

	reset()
	cr:translate(700,100)

	bez(0,0,-150,150,550,150,400,0)

	cr:translate(0,200)
	bez(0,0,-150,150,550,-150,400,0)

	cr:translate(0,200)
	bez(0,0,-150,150,250,-150,400,0)

	cr:translate(0,200)
	bez(0,0,0,-400,400,400,400,0)

	--horizontal colinear

	reset()
	cr:translate(1400,100)
	bez(0,0,0,0,400,0,400,0) --control points == end points

	cr:translate(0,200)
	bez(0,0,0,0,200,0,400,0) --first control point == first end point

	cr:translate(0,200)
	bez(0,0,400,0,0,0,400,0) --control points == end points switched

	cr:translate(0,100)
	bez(10, 80, 10, 80, 310, 80, 110, 80)

	--vertical colinear

	reset()
	cr:translate(2000,100)

	bez(0,0,0,0,0,0,0,400) --control points == end points switched

	cr:translate(200,0)
	bez(0,0,0,100,0,200,0,400)

	cr:translate(200,0)
	bez(0,0,0,0,0,200,0,400)

	--long lines

	reset()
	cr:translate(100, 900)

	bez(0,0,-200,200,2500,-200,2700,0)

	cr:translate(0, 200)
	bez(0,0,0,-1,2700,-1,2700,0) --almost flat
end

player:play()

