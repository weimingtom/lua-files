--convert a complex path into a path containing only move, line and close commands.

local glue = require'glue'
local bezier3_interpolate = require'path_bezier3_ai'
local bezier2_interpolate = require'path_bezier3_ai' --TODO: use this

--emit only (move, line, close) commands for any path, without cpx,cpy.
--mt can only be an affine transformation object.
local function path_flatten(path, write, mt)
	local x1, y1
	local function write(s, x2, y2, x3, y3, x4, y4)
		if s == 'curve' then
			if mt then
				x2, y2 = mt:transform(x2, y2)
				x3, y3 = mt:transform(x3, y3)
				x4, y4 = mt:transform(x4, y4)
			end
			bezier3_interpolate(write, x1, y1, x2, y2, x3, y3, x4, y4)
		elseif s == 'move' then
			if mt then x2, y2 = mt:transform(x2, y2) end
			x1, y1 = x2, y2
		elseif s == 'line' then
			if mt then x2, y2 = mt:transform(x2, y2) end
			write(s, x2, y2)
		elseif s == 'close' then
			write(s)
			x1, y1 = nil
		end
	end
	path_simplify(write, path)
end

local function flat_path_writer()
	local path = {}
	local function write(s,...)
		glue.append(path,s,...)
	end
	return write, path
end

local function path_flatten_to_path(path, mt)
	local write, dpath = flat_path_writer()
	path_flatten(path, write, mt)
	return dpath
end

local function cairo_draw_flat_path(cr, path)
	local function write(s, x1, y1)
		if s == 'move' then
			cr:move_to(x1, y1)
		elseif s == 'line' then
			cr:line_to(x1, y1)
		elseif s == 'close' then
			cr:close_path()
		end
	end
	path_flatten(path, write)
end

