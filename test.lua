local player = require'cairopanel_player'
local glue = require'glue'
local arc = require'path_arc'
local shapes = require'path_shapes'

local i = 0
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()
	cr:set_line_width(1)
	cr:select_font_face('Arial', 0, 0)
	cr:set_font_size(14)

	local x0, y0 = self.mouse_x, self.mouse_y
	if not x0 then return end

	local function grid(x, y, w, h, size)
		for i=0,h,size do
			cr:move_to(0, i)
			cr:line_to(w, i)
		end
		for i=0,w,size do
			cr:move_to(i, 0)
			cr:line_to(i, h)
		end
	end

	local function drawing(x,y)
		local x0,y0 = cr:device_to_user(x0,y0)
		cr:translate(x,y)
		grid(.5, .5, 400, 400, 20)
		cr:set_source_rgb(1,1,1)
		cr:stroke()

		local function write(s,...)
			if s=='move' then cr:move_to(...)
			elseif s=='curve' then cr:curve_to(...)
			elseif s=='close' then cr:close_path()
			end
		end
		shapes.circle(write, 250, 250, 50)
		--cr:circle(250, 250, 50)

		cr:circle(x0, y0, 2)

		local d,x,y,t = arc.hit(x0, y0, 250, 250, 50, 0, math.pi*2)

		cr:move_to(x,y)
		cr:line_to(x0,y0)
	end

	cr:translate(100, 300)
	cr:rotate(-math.pi/4)
	cr:scale(2, 1)
	drawing(0,0)

	cr:identity_matrix()
	drawing(900, 0)


end

player:play()
