--2d path simplification: convert a complex path to a path containing only move, line, curve and close commands.
local command_argc = require'path_state'.command_argc
local path_commands = require'path_state'.commands
local next_state = require'path_state'.next_state
local reflect_point = require'path_point'.reflect
local reflect_scale_point = require'path_point'.reflect_scale
local arc_to_bezier3 = require'path_arc'.to_bezier3
local arc_3p_to_bezier3 = require'path_arc_3p'.to_bezier3
local svgarc_to_bezier3 = require'path_svgarc'.to_bezier3
local bezier3_control_points = require'path_bezier2'.bezier3_control_points
local bezier2_3point_control_point = require'path_bezier2'.bezier2_3point_control_point
local shapes = require'path_shapes'

local unpack, radians = unpack, math.rad

local function shape_writer(writer, argc)
	return function(write, path, i)
		writer(write, unpack(path, i + 1, i + argc))
	end
end

local shape_writers = {
	ellipse     = shape_writer(shapes.ellipse, 4),
	circle      = shape_writer(shapes.circle, 3),
	circle_3p   = shape_writer(shapes.circle_3p, 6),
	rect        = shape_writer(shapes.rectangle, 4),
	round_rect  = shape_writer(shapes.round_rectangle, 5),
	star        = shape_writer(shapes.star, 7),
	rpoly       = shape_writer(shapes.regular_polygon, 4),
}

local function path_simplify(write, path) --this is for drawing so avoid making garbage in here
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in path_commands(path) do
		if s == 'move' then
			write('move', path[i+1], path[i+2])
		elseif s == 'rel_move' then
			write('move', cpx + path[i+1], cpy + path[i+2])
		elseif s == 'close' then
			write('close')
		elseif s == 'line'then
			write('line', path[i+1], path[i+2])
		elseif s == 'rel_line' then
			write('line', cpx + path[i+1], cpy + path[i+2])
		elseif s == 'hline' then
			write('line', path[i+1], cpy)
		elseif s == 'rel_hline' then
			write('line', cpx + path[i+1], cpy)
		elseif s == 'vline' then
			write('line', cpx, path[i+1])
		elseif s == 'rel_vline' then
			write('line', cpx, cpy + path[i+1])
		elseif s == 'curve' then
			write('curve', unpack(path, i + 1, i + 6))
		elseif s == 'rel_curve' then
			write('curve', cpx + path[i+1], cpy + path[i+2], cpx + path[i+3], cpy + path[i+4],
								cpx + path[i+5], cpy + path[i+6])
		elseif s == 'symm_curve' then
			local x2, y2 = reflect_point(bx or cpx, by or cpy, cpx, cpy)
			write('curve', x2, y2, path[i+1], path[i+2], path[i+3], path[i+4])
		elseif s == 'rel_symm_curve' then
			local x2, y2 = reflect_point(bx or cpx, by or cpy, cpx, cpy)
			write('curve', x2, y2, cpx + path[i+1], cpy + path[i+2], cpx + path[i+3], cpy + path[i+4])
		elseif s == 'smooth_curve' then
			local x2, y2 = reflect_scale_point(bx or cpx, by or cpy, cpx, cpy, path[i+1])
			write('curve', x2, y2, path[i+2], path[i+3], path[i+4], path[i+5])
		elseif s == 'rel_smooth_curve' then
			local x2, y2 = reflect_scale_point(bx or cpx, by or cpy, cpx, cpy, path[i+1])
			write('curve', x2, y2, cpx + path[i+2], cpy + path[i+3], cpx + path[i+4], cpy + path[i+5])
		elseif s == 'quad_curve' then
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, path[i+1], path[i+2], path[i+3], path[i+4])
			write('curve', x2, y2, x3, y3, path[i+3], path[i+4])
		elseif s == 'rel_quad_curve' then
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, cpx + path[i+1], cpy + path[i+2],
																						cpx + path[i+3], cpy + path[i+4])
			write('curve', x2, y2, x3, y3, cpx + path[i+3], cpy + path[i+4])
		elseif s == 'quad_curve_3p' then
			xc, yc = bezier2_3point_control_point(cpx, cpy, path[i+1], path[i+2], path[i+3], path[i+4])
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, path[i+3], path[i+4])
			write('curve', x2, y2, x3, y3, path[i+3], path[i+4])
		elseif s == 'rel_quad_curve_3p' then
			xc, yc = bezier2_3point_control_point(cpx, cpy, cpx + path[i+1], cpy + path[i+2], cpx + path[i+3], cpy + path[i+4])
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, cpx + path[i+3], cpy + path[i+4])
			write('curve', x2, y2, x3, y3, cpx + path[i+3], cpy + path[i+4])
		elseif s == 'symm_quad_curve' then
			local xc, yc = reflect_point(qx or cpx, qy or cpy, cpx, cpy)
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, path[i+1], path[i+2])
			write('curve', x2, y2, x3, y3, path[i+1], path[i+2])
		elseif s == 'rel_symm_quad_curve' then
			local xc, yc = reflect_point(qx or cpx, qy or cpy, cpx, cpy)
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, cpx + path[i+1], cpy + path[i+2])
			write('curve', x2, y2, x3, y3, cpx + path[i+1], cpy + path[i+2])
		elseif s == 'smooth_quad_curve' then
			local xc, yc = reflect_scale_point(qx or cpx, qy or cpy, cpx, cpy, path[i+1])
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, path[i+2], path[i+3])
			write('curve', x2, y2, x3, y3, path[i+2], path[i+3])
		elseif s == 'rel_smooth_quad_curve' then
			local xc, yc = reflect_scale_point(qx or cpx, qy or cpy, cpx, cpy, path[i+1])
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, cpx + path[i+2], cpy + path[i+3])
			write('curve', x2, y2, x3, y3, cpx + path[i+2], cpy + path[i+3])
		elseif s:match'arc' then
			local command, segments
			if s == 'arc' or s == 'rel_arc' then
				local cx, cy, r, start_angle, sweep_angle = unpack(path, i + 1, i + 5)
				if s == 'rel_arc' then cx, cy = cpx + cx, cpy + cy end
				command, segments = arc_to_bezier3(cx, cy, r, radians(start_angle), radians(sweep_angle))
				write(cpx ~= nil and 'line' or 'move', segments[1], segments[2])
			elseif s == 'arc_3p' or s == 'rel_arc_3p' then
				local x2, y2, x3, y3 = unpack(path, i + 1, i + 4)
				if s == 'rel_arc_3p' then x2, y2, x3, y3 = cpx + x2, cpy + y2, cpx + x3, cpy + y3 end
				command, segments = arc_3p_to_bezier3(cpx, cpy, x2, y2, x3, y3)
			else
				local rx, ry, angle, large_arc_flag, sweep_flag, x2, y2 = unpack(path, i + 1, i + 7)
				if s == 'rel_svgarc' then x2, y2 = cpx + x2, cpy + y2 end
				command, segments = svgarc_to_bezier3(cpx, cpy, rx, ry, radians(angle), large_arc_flag, sweep_flag, x2, y2)
			end
			if command == 'line' then
				write('line', segments[3], segments[4])
			elseif command == 'negative_line' then
				write('move', segments[3], segments[4]) --we can't draw negative lines
			elseif command == 'curve' then
				for i=3,#segments,8 do
					write('curve', unpack(segments, i, i+6-1))
				end
			else
				assert(false, command)
			end
		elseif s == 'text' then
			write(s, path[i+1], path[i+2])
		elseif shape_writers[s] then
			shape_writers[s](write, path, i)
		elseif s == 'break' then
		else
			assert(false, s)
		end
		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(path, i, cpx, cpy, spx, spy, bx, by, qx, qy)
	end
end

if not ... then require'sg_cairo_demo' end

return path_simplify
