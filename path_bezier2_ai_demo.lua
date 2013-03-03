local player = require'cairopanel_player'
local bezier2 = require'path_bezier2_ai'
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
		cr:set_font_size(14)
		cr:text_path(string.format(...))
		cr:set_source_rgb(1,1,1)
		cr:fill()
	end

	local lines
	local function write(cmd, x2, y2)
		if cmd == 'move' then
			cr:move_to(x2, y2)
		elseif cmd == 'line' then
			lines = lines + 1
			cr:line_to(x2, y2)
		elseif cmd == 'close' then
			cr:close_path()
		end
	end

	local r = i
	local function bezier(write, x1, y1, x2, y2, x3, y3)
		lines = 0
		bezier2(write, x1, y1, x2, y2, x3, y3, r)
	end

	local function bez(cpx,cpy,...)
		cr:move_to(cpx,cpy)
		bezier(write, cpx, cpy, ...)
		cr:set_source_rgb(1,1,1)
		cr:set_line_width(2)
		cr:stroke()
		label(cpx, cpy - 10, 'segments: %d', lines)
	end

	label(100, 40, 'scale: %f', r)

	cr:translate(100,100)
	bez(0,0,50,1000,100,0)

	cr:translate(200,0)
	bez(0,0,100,250,0,500)

	cr:translate(200,0)
	bez(0,0,0,250,0,500)

	cr:translate(200,0) --case of smooth bezier with cp1 == cpx
	bez(0,0,0,0,0,500)

	cr:translate(200,0)
	bez(0,0,0,300,0,500)
end

player:play()

