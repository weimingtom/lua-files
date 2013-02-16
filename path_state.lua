--2d path validation and iteration with state (current point) computation
local glue = require'glue'
local arc = require'path_arc'
local reflect_point = require'path_math'.reflect_point
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
	smooth_curve = 4,
	rel_smooth_curve = 4,
	quad_curve = 4,
	rel_quad_curve = 4,
	smooth_quad_curve = 2,
	rel_smooth_quad_curve = 2,
	arc = 5,
	rel_arc = 5,
	elliptical_arc = 7,
	rel_elliptical_arc = 7,
	text = 2,
}

local shapes_argc = {
	ellipse = 4,
	circle = 3,
	rect = 4,
	round_rect = 5,
	star = 7,
	rpoly = 4,
}

glue.update(argc, shapes_argc)

local function nocp_command(s) --command requires no current point
	return s == 'move' or s == 'arc' or shapes_argc[s]
end

local function next_command(path, i)
	i = i and i + argc[path[i]] + 1 or 1
	if i > #path then return end
	return i, path[i]
end

local function commands(path)
	assert(#path == 0 or nocp_command(path[1]), 'no current point')
	return next_command, path
end

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
	elseif s == 'smooth_curve' then
		bx, by = path[i+1], path[i+2]
		cpx, cpy = path[i+3], path[i+4]
	elseif s == 'rel_smooth_curve' then
		bx, by = cpx + path[i+1], cpy + path[i+2]
		cpx, cpy = cpx + path[i+3], cpy + path[i+4]
	elseif s == 'quad_curve' then
		qx, qy = path[i+1], path[i+2]
		cpx, cpy = path[i+3], path[i+4]
	elseif s == 'rel_quad_curve' then
		qx, qy = cpx + path[i+1], cpy + path[i+2]
		cpx, cpy = cpx + path[i+3], cpy + path[i+4]
	elseif s == 'smooth_quad_curve' then
		qx, qy = reflect_point(qx1 or cpx, qy1 or cpy, cpx, cpy)
		cpx, cpy = path[i+1], path[i+2]
	elseif s == 'rel_smooth_quad_curve' then
		qx, qy = reflect_point(qx1 or cpx, qy1 or cpy, cpx, cpy)
		cpx, cpy = cpx + path[i+1], cpy + path[i+2]
	elseif s == 'arc' or s == 'rel_arc' then
		local cx, cy, r, start_angle, sweep_angle = unpack(path, i + 1, i + 5)
		if s == 'rel_arc' then cx, cy = cpx + cx, cpy + cy end
		local t = arc(cx, cy, r, r, radians(start_angle), radians(sweep_angle))
		if #t > 4 then bx, by = t[#t-3], t[#t-2] end
		cpx, cpy = t[#t-1], t[#t]
	elseif s == 'elliptical_arc' then
		cpx, cpy = path[i+6], path[i+7]
	elseif s == 'rel_elliptical_arc' then
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
	next_command = next_command,
	commands = commands,
	next_state = next_state,
}

