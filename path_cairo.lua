--2d path drawing using cairo.

local path = require'path'

local function draw_function(cr)
	local function write(i, s, cpx, cpy, ...)
		if s == 'move' then
			cr:move_to(...)
		elseif s == 'line' then
			cr:line_to(...)
		elseif s == 'curve' then
			cr:curve_to(...)
		elseif s == 'close' then
			cr:close_path()
		elseif s == 'text' then
			local font, s = ...
			cr:select_font_face(font.family or 'Arial', 0, 0)
			cr:set_font_size(font.size or 12)
			cr:text_path(s)
		end
	end
	local function draw(path_, mt)
		cr:new_path()
		path.decode(write, path_, mt)
	end

	return draw
end

if not ... then
	local player = require'cairopanel_player'
	function player:on_render(cr)
		cr:set_source_rgb(0,0,0)
		cr:paint()

		local draw = draw_function(cr)
		draw({
		'move', 100, 100, 'rel_round_rect', 10, 10, 50, 50, 10,
		'move', 0, 0,
		'arc', 100, 100, 200, 0, 90,
		'arc_3p', 20, 20, 0, 0,
		})
		cr:set_source_rgb(1,1,1)
		cr:stroke()
	end
	player:play()
end

return draw_function

