local player = require'cairopanel_player'
local glue = require'glue'
local distance2 = require'path_point'.distance2
local bezier3 = require'path_bezier3'
local path_simplify = require'path_simplify'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()
	cr:translate(200, 200)

	local function write(s, x2, y2, t2)
		--print(x2,t2)
		cr:line_to(x2,y2)
		local cpx,cpy = cr:get_current_point()
		cr:circle(x2,y2,2)
		cr:move_to(cpx,cpy)
	end
	cr:move_to(0,0)
	cr:circle(0,0,2)
	bezier3.to_lines(write, 0, 0, 500, 6, 500, 6, 1000, 0, 0.05)
	cr:set_source_rgb(1,1,1)
	cr:set_line_width(1)
	cr:stroke()
	--os.exit(1)

	--print(bezier3.point(.3, 0, 0, 500, 6, 500, 6, 1000, 0))
	--print(bezier3.split(.3, 0, 0, 500, 6, 500, 6, 1000, 0))
end

player:play()

