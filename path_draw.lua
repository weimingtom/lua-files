--path drawing via cairo for demos of the path_* modules.

local function path_draw(cr)
	local function write(s,...)
		if s == 'move' then cr:move_to(...)
		elseif s == 'line' then cr:line_to(...)
		elseif s == 'curve' then cr:curve_to(...)
		elseif s == 'close' then cr:close_path()
		end
	end

	local function hex_color(s)
		local r,g,b = tonumber(s:sub(2,3), 16), tonumber(s:sub(4,5), 16), tonumber(s:sub(6,7), 16)
		return r/255, g/255, b/255
	end

	local function draw(path,stroke_color,fill_color)
		path_simplify(write,path)
		if fill_color then
			cr:set_source_rgb(hex_color(fill_color))
			cr:fill_preserve()
		end
		cr:set_source_rgb(hex_color(stroke_color or '#ffffff'))
		cr:stroke()
	end

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

	return {

	}
end

return path_draw
