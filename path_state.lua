--2d path validation and iteration and computation of the next state.

local glue = require'glue'

local arc_endpoints = require'path_arc'.endpoints
local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local bezier2_3point_control_point = require'path_bezier2'.bezier2_3point_control_point

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
	formula = 3,
}

--commands that do not require a current point
local nocp_commands = glue.index{'move', 'arc', 'rel_arc', 'formula'}

local shapes_argc = {
	ellipse = 4,
	circle = 3,
	circle_3p = 6,
	rect = 4,
	round_rect = 5,
	star = 7,
	rpoly = 4,
}

glue.update(argc, shapes_argc)
glue.update(nocp_commands, shapes_argc)

local ext = {}

local function nocp_command(s)
	return nocp_commands[s] or ext[s].nocp
end

--given an index in path pointing to a command string, return the index of the next command.
local function next_command(path, i)
	i = i and i + (argc[path[i]] or ext[path[i]].argc) + 1 or 1
	if i > #path then return end
	return i, path[i]
end

--iterate path commands returning the index in path where the command is, and the command string.
local function commands(path)
	assert(#path == 0 or nocp_command(path[1]), 'no current point')
	return next_command, path
end

--return the state of the next path command given the state of the current path command.
--cpx, cpy is the next "current point", needed by all relative commands and by most other commands.
--spx, spy is the starting point of the current subpath, needed by the "close" command.
--bx,by is the 2nd control point of the current command if it was a cubic bezier, needed by symmetric cubic beziers.
--qx,qy is the control point of the current command if it was a quad bezier, needed by symmetric quad beziers.
--smooth curves will use either bx,by or qx,qy, whichever is available, because they only need the angle from it.
--NOTE! arcs should set bx,by if the next command is a smooth curve of any kind, but we don't set it here.
local function next_state(path, i, cpx, cpy, spx, spy, bx1, by1, qx1, qy1)
	local s = path[i]
	local bx, by, qx, qy
	assert(cpx or nocp_command(s), 'no current point')
	if s == 'move' then
		cpx, cpy = path[i+1], path[i+2]
		spx, spy = cpx, cpy
	elseif s == 'rel_move' then
		cpx, cpy = cpx + path[i+1], cpy + path[i+2]
		spx, spy = cpx, cpy
	elseif s == 'line' then
		cpx, cpy = path[i+1], path[i+2]
	elseif s == 'rel_line' then
		cpx, cpy = cpx + path[i+1], cpy + path[i+2]
	elseif s == 'close' then
		cpx, cpy = spx, spy
	elseif s == 'break' then
		cpx, cpy, spy, spy = nil
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
	elseif s == 'quad_curve' then
		qx, qy = path[i+1], path[i+2]
		cpx, cpy = path[i+3], path[i+4]
	elseif s == 'rel_quad_curve' then
		qx, qy = cpx + path[i+1], cpy + path[i+2]
		cpx, cpy = cpx + path[i+3], cpy + path[i+4]
	elseif s == 'quad_curve_3p' then
		qx, qy = bezier2_3point_control_point(cpx, cpy, path[i+1], path[i+2], path[i+3], path[i+4])
		cpx, cpy = path[i+3], path[i+4]
	elseif s == 'rel_quad_curve_3p' then
		qx, qy = bezier2_3point_control_point(cpx, cpy, cpx + path[i+1], cpy + path[i+2], cpx + path[i+3], cpy + path[i+4])
		cpx, cpy = cpx + path[i+3], cpy + path[i+4]
	elseif s == 'symm_quad_curve' then
		qx, qy = reflect_point(qx1 or cpx, qy1 or cpy, cpx, cpy)
		cpx, cpy = path[i+1], path[i+2]
	elseif s == 'rel_symm_quad_curve' then
		qx, qy = reflect_point(qx1 or cpx, qy1 or cpy, cpx, cpy)
		cpx, cpy = cpx + path[i+1], cpy + path[i+2]
	elseif s == 'smooth_quad_curve' then
		qx, qy = reflect_point_distance(qx1 or bx1 or cpx, qy1 or by1 or cpy, cpx, cpy, path[i+1])
		cpx, cpy = path[i+2], path[i+3]
	elseif s == 'rel_smooth_quad_curve' then
		qx, qy = reflect_point_distance(qx1 or bx1 or cpx, qy1 or by1 or cpy, cpx, cpy, path[i+1])
		cpx, cpy = cpx + path[i+2], cpy + path[i+3]
	elseif s == 'arc' or s == 'rel_arc' then
		local cx, cy, r, start_angle, sweep_angle = unpack(path, i + 1, i + 5)
		if s == 'rel_arc' then cx, cy = cpx + cx, cpy + cy end
		cpx, cpy = select(3, arc_endpoints(cx, cy, r, radians(start_angle), radians(sweep_angle)))
	elseif s == 'arc_3p' then
		cpx, cpy = path[i+3], path[i+4]
	elseif s == 'rel_arc_3p' then
		cpx, cpy = cpx + path[i+3], cpy + path[i+4]
	elseif s == 'svgarc' then
		cpx, cpy = path[i+6], path[i+7]
	elseif s == 'rel_svgarc' then
		cpx, cpy = cpx + path[i+6], cpy + path[i+7]
	elseif s == 'text' then
		cpx, cpy, spx, spy = nil --text cannot be continued from
	elseif s == 'formula' then
		local formula, steps, args = path[i+1], path[i+2], path[i+3]
		cpx, cpy = formula(1, unpack(args))
	elseif shapes_argc[s] then
		cpx, cpy, spx, spy = nil --shapes cannot be continued from
	elseif ext[s] then
		return ext[s].next_state(path, i, cpx, cpy, spx, spy, bx1, by1, qx1, qy1)
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

