local player = require'cairopanel_player'
local glue = require'glue'
local shapes = require'path_shapes'

local i = 60
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local function write(s,...)
		if s == 'move' then cr:move_to(...)
		elseif s == 'line' then cr:line_to(...)
		elseif s == 'curve' then cr:curve_to(...)
		elseif s == 'close' then cr:close_path()
		end
	end

	cr:set_source_rgb(1,1,1)
	shapes.ellipse(write, 100, 100, 50, 20)
	cr:stroke()

	shapes.circle(write, 100, 100, 50)
	cr:stroke()

	shapes.rectangle(write, 50, 50, 100, 100)
	cr:stroke()

	shapes.round_rectangle(write, 50, 50, 100, 100, 20)
	cr:stroke()

	shapes.round_rectangle(write, 250, 50, 100, 100, 20, 40)
	cr:stroke()

	local n = math.floor(i/30)
	cr:translate(200, 300)

	shapes.regular_polygon(write, 0, 0, 30, -100, n)
	cr:stroke()

	cr:translate(300, 0)
	shapes.star(write, 0, 0, 0, -100, 30, n)
	cr:stroke()

	cr:translate(300, 0)
	shapes.star_2p(write, 0, 0, 0, -100, 0, -50, n)
	cr:stroke()

	cr:translate(-600, 300)
	shapes.swirl(write, 0, 0, 100, 2, 3)
	cr:stroke()
end

player:play()

