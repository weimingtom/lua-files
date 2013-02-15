local player = require'cairopanel_player'
local bezier = require'path_bezier'
local glue = require'glue'

local i=1
function player:on_render(cr)
	i=i+1/i

	local function label(x, y, ...)
		cr:move_to(x, y)
		cr:select_font_face('Arial', 0, 0)
		cr:set_font_size(28)
		cr:text_path(string.format(...))
		cr:set_source_rgb(1,1,1)
		cr:fill()
	end

	--path writer
	local lines
	local function write(cmd, ...)
		if cmd == 'move' then
			cr:move_to(...)
		elseif cmd == 'line' then
			lines = lines + 1
			cr:line_to(...)
		elseif cmd == 'close' then
			cr:close_path()
		end
	end

	--init
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local r = i
	local bezier = function(write, x1, y1, x2, y2, x3, y3, x4, y4)
		lines = 0
		bezier(write, x1, y1, x2, y2, x3, y3, x4, y4, r)
	end

	local function bez(cpx,cpy,...)
		cr:move_to(cpx,cpy)
		bezier(write, cpx, cpy, ...)
		cr:set_source_rgb(1,1,1)
		cr:set_line_width(5)
		cr:stroke()
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
	bez(0,0,-100,0,500,0,400,0)

	reset()
	cr:translate(700,100)

	bez(0,0,-150,150,550,150,400,0)

	cr:translate(0,200)
	bez(0,0,-150,150,550,-150,400,0)

	cr:translate(0,200)
	bez(0,0,-150,150,250,-150,400,0)

	cr:translate(0,200)
	bez(0,0,0,-400,400,400,400,0)

	reset()
	cr:translate(1400, 100)
end

player:play()

