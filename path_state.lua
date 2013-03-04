--2d path validation and iteration and computation of the next state.
local glue = require'glue'
local arc_endpoints = require'path_arc'.endpoints
local reflect_point = require'path_point'.reflect
local reflect_scale_point = require'path_point'.reflect_scale
local bezier2_3point_control_point = require'path_bezier2'.bezier2_3point_control_point
local bezier3_control_points = require'path_bezier2'.bezier3_control_points
local radians = math.rad

local argc = {
	move = 2,
	rel_move = 2,
	close = 0,
	['break'] = 0,
	line = 2,
	rel_line = 2,
	hline = 1,
	rel_hline = 1,
	vline = 1,
	rel_vline = 1,
	curve = 6,
	rel_curve = 6,
	symm_curve = 4,
	rel_symm_curve = 4,
	smooth_curve = 5,
	rel_smooth_curve = 5,
	quad_curve = 4,
	rel_quad_curve = 4,
	quad_curve_3p = 4,
	rel_quad_curve_3p = 4,
	symm_quad_curve = 2,
	rel_symm_quad_curve = 2,
	smooth_quad_curve = 3,
	rel_smooth_quad_curve = 3,
	arc = 5,
	rel_arc = 5,
	arc_3p = 4,
	rel_arc_3p = 4,
	svgarc = 7,
	rel_svgarc = 7,
	text = 2,
}

local shapes_argc = {
	ellipse = 4,
	circle = 3,
	circle_3p = 6,
	rect = 4,
	round_rect = 5,
	star = 7,
	rpoly = 4,
}

local qx_needed = glue.index{'smooth_quad_curve', 'rel_smooth_quad_curve', 'symm_quad_curve', 'rel_symm_quad_curve'}
local bx_needed = glue.index{'smooth_curve', 'rel_smooth_curve', 'symm_curve', 'rel_symm_curve'}

glue.update(argc, shapes_argc)

local function nocp_command(s) --return true if this particular command requires no current point.
	return s == 'move' or s == 'arc' or shapes_argc[s]
end

--given an index in path pointing to a command string, return the index of the next command.
local function next_command(path, i)
	i = i and i + argc[path[i]] + 1 or 1
	if i > #path then return end
	return i, path[i]
end

--iterate path commands returning the index in path where the command is, and the command string.
local function commands(path)
	assert(#path == 0 or nocp_command(path[1]), 'no current point')
	return next_command, path
end

--return the state of the next path command given the state of the current path command.
--cpx, cpy is the current control point, needed for most commands.
--bx,by is the control point of the last cubic bezier, needed if the current path command is a smooth or symmetric cubic bezier.
--qx,qy is the control point of the last quad bezier, needed if the current path command is a smooth or symmetric quad bezier.
local function next_state(path, i, cpx, cpy, spx, spy, bx, by, qx, qy)
	local s = path[i]
	local qx1, qy1 = qx, qy
	bx, by, qx, qy = nil
	assert(cpx or nocp_command(s), 'no current point')
	if s == 'move' then
		cpx, cpy = path[i+1], path[i+2]
		spx, spy = cpx, cpy
	elseif s == 'rel_move' then
		cpx, cpy = cpx + path[i+1], cpy + path[i+2]
		spx, spy = cpx, cpy
	elseif s == 'close' then
		cpx, cpy = spx, spy
	elseif s == 'break' then
		cpx, cpy, spy, spy = nil
	elseif s == 'line' then
		cpx, cpy = path[i+1], path[i+2]
	elseif s == 'rel_line' then
		cpx, cpy = cpx + path[i+1], cpy + path[i+2]
	elseif s == 'hline' then
		cpx = path[i+1]
	elseif s == 'rel_hline' then
		cpx = cpx + path[i+1]
	elseif s == 'vline' then
		cpy = path[i+1]
	elseif s == 'rel_vline' then
		cpy = cpy + path[i+1]
	elseif s == 'curve' then
		bx, by = path[i+3], path[i+4]
		cpx, cpy = path[i+5], path[i+6]
	elseif s == 'rel_curve' then
		bx, by = cpx + path[i+3], cpy + path[i+4]
		cpx, cpy = cpx + path[i+5], cpy + path[i+6]
	elseif s == 'symm_curve' then
		bx, by = path[i+1], path[i+2]
		cpx, cpy = path[i+3], path[i+4]
	elseif s == 'rel_symm_curve' then
		bx, by = cpx + path[i+1], cpy + path[i+2]
		cpx, cpy = cpx + path[i+3], cpy + path[i+4]
	elseif s == 'smooth_curve' then
		bx, by = path[i+2], path[i+3]
		cpx, cpy = path[i+4], path[i+5]
	elseif s == 'rel_smooth_curve' then
		bx, by = cpx + path[i+2], cpy + path[i+3]
		cpx, cpy = cpx + path[i+4], cpy + path[i+5]
	elseif s == 'quad_curve' or s == 'rel_quad_curve' then
		qx, qy = path[i+1], path[i+2]
		local x3, y3 = path[i+3], path[i+4]
		if s == 'rel_quad_curve' then qx, qy, x3, y3 = cpx + qx, cpy + qy, cpx + x3, cpy + y3 end
		local _, nexts = next_command(path, i)
		if bx_needed[nexts] then
			bx, by = select(3, bezier3_control_points(cpx, cpy, qx, qy, x3, y3))
		end
		cpx, cpy = x3, y3
	elseif s == 'quad_curve_3p' or s == 'rel_quad_curve_3p' then
		local x0, y0, x3, y3 = path[i+1], path[i+2], path[i+3], path[i+4]
		if s == 'rel_quad_curve_3p' then x0, y0, x3, y3 = cpx + x0, cpy + y0, cpx + x3, cpy + y3 end
		local _, nexts = next_command(path, i)
		if qx_needed[nexts] or bx_needed[nexts] then
			qx, qy = bezier2_3point_control_point(cpx, cpy, x0, y0, x3, y3)
			if bx_needed[nexts] then
				bx, by = select(3, bezier3_control_points(cpx, cpy, qx, qy, x3, y3))
			end
		end
		cpx, cpy = x3, y3
	elseif s == 'symm_quad_curve' or s == 'rel_symm_quad_curve' then
		qx, qy = reflect_point(qx1 or cpx, qy1 or cpy, cpx, cpy)
		local x3, y3 = path[i+1], path[i+2]
		if s == 'rel_symm_quad_curve' then x3, y3 = cpx + x3, cpy + y3 end
		local _, nexts = next_command(path, i)
		if bx_needed[nexts] then
			bx, by = select(3, bezier3_control_points(cpx, cpy, qx, qy, x3, y3))
		end
		cpx, cpy = x3, y3
	elseif s == 'smooth_quad_curve' or s == 'rel_smooth_quad_curve' then
		local x3, y3 = path[i+2], path[i+3]
		if s == 'rel_smooth_quad_curve' then x3, y3 = cpx + x3, cpy + y3 end
		local _, nexts = next_command(path, i)
		if qx_needed[nexts] or bx_needed[nexts] then
			qx, qy = reflect_scale_point(qx1 or cpx, qy1 or cpy, cpx, cpy, path[i+1])
			if bx_needed[nexts] then
				bx, by = select(3, bezier3_control_points(cpx, cpy, qx, qy, x3, y3))
			end
		end
		cpx, cpy = x3, y3
	elseif s == 'arc' or s == 'rel_arc' then
		--TODO: for all arc commands, look at the next command and if it's a smooth curve, generate the arc and extract bx, by for it.
		local cx, cy, r, start_angle, sweep_angle = unpack(path, i + 1, i + 5)
		if s == 'rel_arc' then cx, cy = cpx + cx, cpy + cy end
		local x1, y1, x2, y2 = arc_endpoints(cx, cy, r, r, radians(start_angle), radians(sweep_angle))
		cpx, cpy = x2, y2
	elseif s == 'arc_3p' then
		cpx, cpy = path[i+3], path[i+4]
	elseif s == 'rel_arc_3p' then
		cpx, cpy = cpx + path[i+3], cpy + path[i+4]
	elseif s == 'svgarc' then
		cpx, cpy = path[i+6], path[i+7]
	elseif s == 'rel_svgarc' then
		cpx, cpy = cpx + path[i+6], cpy + path[i+7]
	elseif s == 'text' then
		--TODO
	elseif shapes_argc[s] then
		cpx, cpy, spx, spy = nil --shapes cannot be continued from
	else
		error(string.format('invalid command %s', s))
	end
	return cpx, cpy, spx, spy, bx, by, qx, qy
end

if not ... then require'sg_cairo_demo' end

return {
	command_argc = argc,
	next_command = next_command,
	commands = commands,
	next_state = next_state,
}

