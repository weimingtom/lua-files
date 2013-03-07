--2d path simplification: convert a complex path to a path containing only move, line, curve and close commands.

local glue = require'glue'

local command_argc = require'path_state'.command_argc
local path_commands = require'path_state'.commands
local next_state = require'path_state'.next_state

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance

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

local smooth_curve = glue.index{'smooth_curve', 'rel_smooth_curve', 'smooth_quad_curve', 'rel_smooth_quad_curve'}

--linerly interpolate a shape defined by a custom formula, and unite the points with lines.
local function interpolate(write, formula, steps, args)
	local step = 1/steps
	local i = step
	while i <= 1 do
		local x,y = formula(i, unpack(args))
		write('line',x,y)
		i = i + step
	end
	if i > 1 then
		local x,y = formula(1, unpack(args))
		write('line', x,y)
	end
end

local function path_simplify(write, path) --this is drawing code so avoid making garbage in here
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in path_commands(path) do
		local command, segments
		if s == 'move' then
			write('move', path[i+1], path[i+2])
		elseif s == 'rel_move' then
			write('move', cpx + path[i+1], cpy + path[i+2])
		elseif s == 'close' then
			write('close')
		elseif s == 'break' then
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
			local x2, y2 = reflect_point_distance(bx or qx or cpx, by or qy or cpy, cpx, cpy, path[i+1])
			write('curve', x2, y2, path[i+2], path[i+3], path[i+4], path[i+5])
		elseif s == 'rel_smooth_curve' then
			local x2, y2 = reflect_point_distance(bx or qx or cpx, by or qy or cpy, cpx, cpy, path[i+1])
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
			local xc, yc = reflect_point_distance(qx or bx or cpx, qy or by or cpy, cpx, cpy, path[i+1])
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, path[i+2], path[i+3])
			write('curve', x2, y2, x3, y3, path[i+2], path[i+3])
		elseif s == 'rel_smooth_quad_curve' then
			local xc, yc = reflect_point_distance(qx or bx or cpx, qy or by or cpy, cpx, cpy, path[i+1])
			local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, xc, yc, cpx + path[i+2], cpy + path[i+3])
			write('curve', x2, y2, x3, y3, cpx + path[i+2], cpy + path[i+3])
		elseif s == 'arc' or s == 'rel_arc' then
			local cx, cy, r, start_angle, sweep_angle = unpack(path, i + 1, i + 5)
			if s == 'rel_arc' then cx, cy = cpx + cx, cpy + cy end
			command, segments = arc_to_bezier3(cx, cy, r, radians(start_angle), radians(sweep_angle))
			write(cpx and 'line' or 'move', segments[1], segments[2])
		elseif s == 'arc_3p' or s == 'rel_arc_3p' then
			local x2, y2, x3, y3 = path[i+1], path[i+2], path[i+3], path[i+4]
			if s == 'rel_arc_3p' then x2, y2, x3, y3 = cpx + x2, cpy + y2, cpx + x3, cpy + y3 end
			command, segments = arc_3p_to_bezier3(cpx, cpy, x2, y2, x3, y3)
		elseif s == 'svgarc' or s == 'rel_svgarc' then
			local rx, ry, angle, large_arc_flag, sweep_flag, x2, y2 = unpack(path, i + 1, i + 7)
			if s == 'rel_svgarc' then x2, y2 = cpx + x2, cpy + y2 end
			command, segments = svgarc_to_bezier3(cpx, cpy, rx, ry, radians(angle), large_arc_flag, sweep_flag, x2, y2)
		elseif s == 'text' then
			write(s, path[i+1], path[i+2])
		elseif s == 'formula' then
			local formula, steps, args = path[i+1], path[i+2], path[i+3]
			local x1, y1 = formula(0, unpack(args))
			write(cpx and 'line' or 'move', x1, y1)
			interpolate(write, formula, steps, args)
		elseif shape_writers[s] then
			shape_writers[s](write, path, i)
		else
			print(s)
			ext[s].simplify(write, path, i, cpx, cpy, spx, spy, bx, by, qx, qy)
		end

		if command == 'line' then
			write('line', segments[3], segments[4])
		elseif command == 'negative_line' then
			write('move', segments[3], segments[4]) --we can't draw negative lines but we have to move the current point.
		elseif command == 'curve' then
			for i=3,#segments,8 do
				write('curve', unpack(segments, i, i+6-1))
			end
		end

		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(path, i, cpx, cpy, spx, spy, bx, by, qx, qy)

		--if the last command was an arc with curve segments and the next one is a smooth curve,
		--set bx,by to the 2nd control point of the last segment of the arc, which is the arc's tangent on its end point.
		--likewise if the command was an arc with a line segment, set bx,by to be that segment's first point.
		if (command == 'curve' or command == 'line') and smooth_curve[s] then
			bx, by = segments[#segments-3], segments[#segments-2]
		end
	end
end

if not ... then require'sg_cairo_demo' end

return path_simplify
