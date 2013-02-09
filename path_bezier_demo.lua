local player = require'cairopanel_player'
local bezier = require'path_bezier'
local glue = require'glue'

function player:on_render(cr)

	--path writer
	local function write(cmd, ...)
		if cmd == 'move' then
			cr:move_to(...)
		elseif cmd == 'line' then
			cr:line_to(...)
		elseif cmd == 'curve' then
			cr:curve_to(...)
		elseif cmd == 'close' then
			cr:close_path()
		end
	end

	--init
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local bezier = bezier()
	local function bez(cpx,cpy,...)
		cr:move_to(cpx,cpy)
		bezier(write, cpx, cpy, ...)
		cr:set_source_rgb(1,1,1)
		cr:set_line_width(10)
		cr:stroke()
	end

	local function reset()
		cr:identity_matrix()
		cr:scale(.5, .5)
	end

	reset()

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

