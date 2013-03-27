--2d path drawing using cairo.

local path = require'path'

local function draw_function(cr)
	local function write(s, ...)
		if s == 'move' then
			cr:move_to(...)
		elseif s == 'close' then
			cr:close_path()
		elseif s == 'line' then
			cr:line_to(...)
		elseif s == 'curve' then
			cr:curve_to(...)
		elseif s == 'text' then
			local font, s = ...
			cr:select_font_face(font.family or 'Arial', 0, 0)
			cr:set_font_size(font.size or 12)
			cr:text_path(s)
		end
	end
	local function draw(path_, mt)
		cr:new_path()
		path.simplify(write, path_, mt)
	end

	return draw
end

if not ... then
	local player = require'cairopanel_player'
	local mt = require'affine2d'()
	local b2_to_b3 = require'path_bezier2'.to_bezier3

	local i=0
	function player:on_render(cr)
		i=i+1
		cr:set_source_rgb(0,0,0)
		cr:paint()

		mt:identity()
		mt:scale(2,1)
		mt:translate(400,0)
		mt:rotate(45)

		local draw = draw_function(cr)
		local p = {
		'move', 200, 200,
		'rel_round_rect', 10, 10, 50, 50, 10,
		'move', 300, 300,
		'arc', 300, 300, 100, 0, 180,
		'arc_3p', 300, 200, 200, 200,
		'close',
		}
		draw(p, mt)
		cr:set_source_rgb(1,1,1)
		cr:stroke()

		local x0, y0 = self.mouse_x or 0, self.mouse_y or 0

		local function draw_cf(s,x1,y1,...)
			cr:move_to(x1,y1)
			if s == 'line' then cr:line_to(...)
			elseif s == 'curve' then cr:curve_to(...)
			elseif s == 'quad_curve' then cr:curve_to(select(3, b2_to_b3(x1,y1,...)))
			end
		end

		local d,x,y,i,t = path.hit(x0, y0, p, mt, draw_cf)

		cr:circle(x,y,3)
		cr:set_source_rgb(1,0,0)
		cr:stroke()
		cr:move_to(x,y+16)
		cr:text_path(string.format('i: %g, t: %g', i, t))
		cr:fill()
	end
	player:play()
end

return draw_function

