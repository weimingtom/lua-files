--2D path API: supports lines, with horiz. and vert. variations, quadratic beziers and cubic beziers, with smooth
--and symmetrical variations, absolute and relative variations for all commands, circular arcs, 3-point circular arcs,
--svg-style elliptical arcs, text, and many composite shapes.
--supports affine transforms, bounding box, length-at-t, point-at-t, shortest-distance-to-point, splitting, editing.

local glue = require'glue'

local assert, unpack, select =
	   assert, unpack, select

--path command iteration -----------------------------------------------------------------------------

local argc = {
	--control commands
	move = 2,                       --x2, y2
	close = 0,
	--lines and curves
	line = 2,                       --x2, y2
	hline = 1,                      --x2
	vline = 1,                      --y2
	curve = 6,                      --x2, y2, x3, y3, x4, y4
	symm_curve = 4,                 --x3, y3, x4, y4
	smooth_curve = 5,               --len, x3, y3, x4, y4
	quad_curve = 4,                 --x2, y2, x3, y3
	quad_curve_3p = 4,              --xp, yp, x3, y3
	symm_quad_curve = 2,            --x3, y3
	smooth_quad_curve = 3,          --len, x3, y3
	--arcs
	arc = 5,                        --cx, cy, r, start_angle, sweep_angle
	line_arc = 5,                   --cx, cy, r, start_angle, sweep_angle
	elliptic_arc = 7,               --cx, cy, rx, ry, start_angle, sweep_angle, rotation
	line_elliptic_arc = 7,          --cx, cy, rx, ry, start_angle, sweep_angle, rotation
	arc_3p = 4,                     --xp, yp, x3, y3
	svgarc = 7,                     --rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2
	--closed shapes
	rect = 4,                       --x, y, w, h
	round_rect = 5,                 --x, y, w, h, r
	elliptic_rect = 6,              --x, y, w, h, rx, ry
	ellipse = 5,                    --cx, cy, rx, ry, rotation
	circle = 3,                     --cx, cy, r
	circle_3p = 6,                  --xp, yp, x3, y3
	star = 6,                       --cx, cy, x1, y1, r2, n
	star_2p = 7,                    --cx, cy, x1, y1, x2, y2, n
	rpoly = 5,                      --cx, cy, x1, y1, n
	superformula = 10,              --cx, cy, size, steps, a, b, m, n1, n2, n3
	--text
	text = 4,                       --x, y, {[family=s], [size=n]}, text
}

--all commands have relative-to-current-point counterparts with the same number of arguments.
local t = {}
for k,n in pairs(argc) do
	t['rel_'..k] = n
end
glue.update(argc, t)

--given an index in path pointing to a command string, return the index of the next command and the command name.
local function next_cmd(path, i)
	i = i and i + assert(argc[path[i]], 'invalid command') + 1 or 1
	if i > #path then return end
	return i, path[i]
end

--iterate over path commands receiving the index in path where the command is, and the command name.
local function commands(path)
	return next_cmd, path
end

--unpack the path command at index i and its args.
local function cmd(path, i)
	return unpack(path, i, i+assert(argc[path[i]], 'invalid command'))
end

--adding, replacing and removing path commands -----------------------------------------------------

local table_shift = glue.shift

--update table elements at i in place.
local function table_update(dt, i, ...)
	for k=1,select('#',...) do
		dt[i+k-1] = select(k,...)
	end
end

--update table elements at i in place with the contents of another table.
local function table_update_table(dt, i, t)
	for k=1,#t do
		dt[i+k-1] = t[k]
	end
end

--insert command at i, shifting elemetns as needed.
local function insert_cmd(path, i, s, ...)
	local n = select('#', ...)
	assert(n == argc[s], 'wrong argument count')
	table_shift(path, i, 1 + n)
	table_update(path, i, s, ...)
end

--replace command at i with a new command and args, shifting elements as needed.
local function replace_cmd(path, i, s, ...)
	local old = argc[path[i]]
	local new = select('#', ...)
	assert(new == argc[s], 'wrong argument count')
	table_shift(path, i+1, new-old)
	table_update(path, i, s, ...)
end

local function replace_cmd_t(path, i, s, t)
	local old = argc[path[i]]
	local new = #t
	table_shift(path, i+1, new-old)
	table_update_table(path, i, t)
end

--remove command at i, shifting elements as needed.
local function remove_cmd(path, i)
	table_shift(path, i, - (1 + argc[path[i]]))
end

--given a rel. or abs. command name and its args in abs. form, encode the command as abs. or rel. according to the name.
local function to_rel(cpx, cpy, rs, ...)
	return abs_cmd(-cpx, -cpy, rs, ...)
end

local function insert_rel_cmd(path, i, cpx, cpy, rs, ...)
	insert_cmd(path, i, to_rel(cpx, cpy, rs, ...))
end

local function replace_rel_cmd(path, i, cpx, cpy, rs, ...)
	replace_cmd(path, i, to_rel(cpx, cpy, rs, ...))
end

--path command decoding ----------------------------------------------------------------------------

local function is_rel(s) --check if the command is rel. or abs.
	return s:match'^rel_' or false
end

local function is_abs(s) --check if the command is rel. or abs.
	return not s:match'^rel_'
end

local function abs_name(s) --return the abs. variant for any command, be it abs. or rel.
	return s:match'^rel_(.*)' or s
end

local function rel_name(s) --return the rel. variant for any command, be it abs. or rel.
	return is_rel(s) and s or 'rel_'..s
end

--commands that start with a point and that point is the only argument that can be abs. or rel.
local only_x1y1 = glue.index{'arc', 'elliptic_arc', 'line_arc', 'line_elliptic_arc',
										'rect', 'round_rect', 'elliptic_rect', 'ellipse',
										'circle', 'superformula', 'text'}

--given current point and an unpacked command and its args, return the command in absolute form.
local function abs_cmd(cpx, cpy, s, ...)
	if is_abs(s) then return s, ... end
	assert(cpx and cpy, 'no current point')
	s = abs_name(s)
	if s == 'move' or s == 'line' then
		local x2, y2 = ...
		return s, cpx + x2, cpy + y2
	elseif s == 'close' then
		return s
	elseif s == 'hline' then
		return s, cpx + ...
	elseif s == 'vline' then
		return s, cpy + ...
	elseif s == 'curve' then
		local x2, y2, x3, y3, x4, y4 = ...
		return s, cpx + x2, cpy + y2, cpx + x3, cpy + y3, cpx + x4, cpy + y4
	elseif s == 'symm_curve' then
		local x3, y3, x4, y4 = ...
		return s, cpx + x3, cpy + y3, cpx + x4, cpy + y4
	elseif s == 'smooth_curve' then
		local len, x3, y3, x4, y4 = ...
		return s, len, cpx + x3, cpy + y3, cpx + x4, cpy + y4
	elseif s == 'quad_curve' or s == 'quad_curve_3p' then
		local x2, y2, x3, y3 = ...
		return s, cpx + x2, cpy + y2, cpx + x3, cpy + y3
	elseif s == 'symm_quad_curve' then
		local x3, y3 = ...
		return s, cpx + x3, cpy + y3
	elseif s == 'smooth_quad_curve' then
		local len, x3, y3 = ...
		return s, len, cpx + x3, cpy + y3
	elseif s == 'arc_3p' then
		local xp, yp, x2, y2 = ...
		return s, cpx + xp, cpy + yp, cpx + x2, cpy + y2
	elseif s == 'circle_3p' then
		local x1, y1, x2, y2, x3, y3 = ...
		return s, cpx + x1, cpy + y1, cpx + x2, cpy + y2, cpx + x3, cpy + y3
	elseif s == 'svgarc' then
		local rx, ry, rotation, large_arc_flag, sweep_flag, x2, y2 = ...
		return s, rx, ry, rotation, large_arc_flag, sweep_flag, cpx + x2, cpy + y2
	elseif only_x1y1[s] then
		local x, y = ...
		return s, cpx + x, cpy + y, select(3, ...)
	elseif s == 'star' then
		local cx, cy, x1, y1, r2, n = ...
		return s, cpx + cx, cpy + cy, cpx + x1, cpy + y1, r2, n
	elseif s == 'star_2p' then
		local cx, cy, x1, y1, x2, y2, n = ...
		return s, cpx + cx, cpy + cy, cpx + x1, cpy + y1, cpx + x2, cpy + y2, n
	elseif s == 'rpoly' then
		local cx, cy, x1, y1, n = ...
		return s, cpx + cx, cpy + cy, cpx + x1, cpy + y1, n
	elseif s == 'text' then
		local x, y, font, text = ...
		return s, cpx + x, cpy + y, font, text
	else
		error'invalid command'
	end
end

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local bezier2_3point_control_point = require'path_bezier2'._3point_control_point
local elliptic_arc_endpoints = require'path_elliptic_arc'.endpoints

--given current command in abs. form and current state, return the state of the next path command.
--cpx, cpy is the next "current point", needed by all relative commands and by most other commands.
--spx, spy is the starting point of the current subpath, needed by the "close" command.
--bx,by is the 2nd control point of the current command if it was a cubic bezier, needed by symmetric cubic beziers.
--qx,qy is the control point of the current command if it was a quad bezier, needed by symmetric quad beziers.
--smooth curves will use either bx,by or qx,qy, whichever is available, because they only need the angle from it.
--TODO: find a way to have a smooth curve from a line or an arc (express the tangent at the endpoint somehow).
local function next_state(cpx, cpy, spx, spy, bx1, by1, qx1, qy1, s, ...)
	local _, bx, by, qx, qy
	if s == 'move' then
		cpx, cpy = ...
		spx, spy = ...
	elseif s == 'line' then
		cpx, cpy = ...
	elseif s == 'close' then
		cpx, cpy = spx, spy
	elseif s == 'hline' then
		cpx = ...
	elseif s == 'vline' then
		cpy = ...
	elseif s == 'curve' then
		_, _, bx, by, cpx, cpy = ...
	elseif s == 'symm_curve' then
		bx, by, cpx, cpy = ...
	elseif s == 'smooth_curve' then
		_, bx, by, cpx, cpy = ...
	elseif s == 'quad_curve' then
		qx, qy, cpx, cpy = ...
	elseif s == 'quad_curve_3p' then
		qx, qy = bezier2_3point_control_point(cpx, cpy, ...)
		_, _, cpx, cpy = ...
	elseif s == 'symm_quad_curve' then
		qx, qy = reflect_point(qx1 or cpx, qy1 or cpy, cpx, cpy)
		cpx, cpy = ...
	elseif s == 'smooth_quad_curve' then
		qx, qy = reflect_point_distance(qx1 or bx1 or cpx, qy1 or by1 or cpy, cpx, cpy, (...))
		_, cpx, cpy = ...
	elseif s == 'arc' or s == 'line_arc' then
		local cx, cy, r, start_angle, sweep_angle = ...
		_, _, cpx, cpy = elliptic_arc_endpoints(cx, cy, r, r, start_angle, sweep_angle)
	elseif s == 'elliptic_arc' or s == 'line_elliptic_arc' then
		_, _, cpx, cpy = elliptic_arc_endpoints(...)
	elseif s == 'arc_3p' then
		_, _, cpx, cpy = ...
	elseif s == 'svgarc' then
		cpx, cpy = select(6, ...)
	else --closed composite shapes cannot be continued from
		cpx, cpy, spx, spy = nil
	end
	return cpx, cpy, spx, spy, bx, by, qx, qy
end

--return the state of the path command at an arbitrary index.
local function state_at(path, target_index)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in commands(path) do
		if i == target_index then
			return cpx, cpy, spx, spy, bx, by, qx, qy
		end
		cpx, cpy, spx, spy, bx, by, qx, qy =
			next_state(cpx, cpy, spx, spy, bx, by, qx, qy,
				abs_cmd(cpx, cpy,
					 cmd(path, i)))
	end
	error'invalid path index'
end

local svgarc_to_elliptic_arc = require'path_svgarc'.to_elliptic_arc
local arc3p_to_arc = require'path_arc_3p'.to_arc
local circle_3p_to_circle = require'path_circle_3p'.to_circle

--given a command in abs. form and current state, return the command in context-free form.
local function context_free_abs_cmd(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	if s == 'move' then
		return s, ...
	elseif s == 'line' or s == 'curve' or s == 'quad_curve' then
		return s, cpx, cpy, ...
	elseif s == 'close' then
		return s, cpx, cpy, spx, spy
	elseif s == 'hline' then
		return 'line', cpx, cpy, ..., cpy
	elseif s == 'vline' then
		return 'line', cpx, cpy, cpx, ...
	elseif s == 'symm_curve' then
		local x2, y2 = reflect_point(bx or cpx, by or cpy, cpx, cpy)
		return 'curve', cpx, cpy, x2, y2, ...
	elseif s == 'smooth_curve' then
		local x2, y2 = reflect_point_distance(bx or qx or cpx, by or qy or cpy, cpx, cpy, (...))
		return 'curve', cpx, cpy, x2, y2, select(2, ...)
	elseif s == 'quad_curve_3p' then
		local x2, y2, x3, y3 = ...
		local x2, y2 = bezier2_3point_control_point(cpx, cpy, x2, y2, x3, y3)
		return 'quad_curve', cpx, cpy, x2, y2, x3, y3
	elseif s == 'symm_quad_curve' then
		local x2, y2 = reflect_point(qx or cpx, qy or cpy, cpx, cpy)
		return 'quad_curve', cpx, cpy, x2, y2, ...
	elseif s == 'smooth_quad_curve' then
		local x2, y2 = reflect_point_distance(bx or qx or cpx, by or qy or cpy, cpx, cpy, (...))
		return 'quad_curve', cpx, cpy, x2, y2, select(2, ...)
	elseif s == 'arc_3p' then
		local xp, yp, x2, y2 = ...
		local cx, cy, r, start_angle, sweep_angle = arc3p_to_arc(cpx, cpy, xp, yp, x2, y2)
		if not cx then --invalid parametrization, arc is a line
			return 'line', cpx, cpy, x2, y2
		end
		return 'carc', cpx, cpy, nil, cx, cy, r, r, start_angle, sweep_angle, 0, x2, y2
	elseif s == 'svgarc' then
		local cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2 = svgarc_to_elliptic_arc(cpx, cpy, ...)
		if not cx then --invalid parametrization, arc is a line
			return 'line', cpx, cpy, select(6, ...)
		end
		return 'carc', cpx, cpy, nil, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2
	elseif s == 'arc' then
		local cx, cy, r, start_angle, sweep_angle = ...
		return 'carc', cpx, cpy, 'move', cx, cy, r, r, start_angle, sweep_angle, 0
	elseif s == 'line_arc' then
		local cx, cy, r, start_angle, sweep_angle = ...
		return 'carc', cpx, cpy, 'line', cx, cy, r, r, start_angle, sweep_angle, 0
	elseif s == 'elliptic_arc' then
		return 'carc', cpx, cpy, 'move', ...
	elseif s == 'line_elliptic_arc' then
		return 'carc', cpx, cpy, 'line', ...
	elseif s == 'circle' then
		local cx, cy, r = ...
		return 'ellipse', cx, cy, r, r, 0
	elseif s == 'circle_3p' then
		local cx, cy, r = circle_3p_to_circle(...)
		if not cx then --invalid parametrization, circle has zero radius
			cx, cy, r = 0, 0, 0
		end
		return 'ellipse', cx, cy, r, r, 0
	else --other commands are already in context-free canonical form.
		return s, ...
	end
end

--given an abs. path command and current state, decode it and pass it to a processor function and then
--return the next state. the processor will usually write its output using the supplied write function.
local function decode_abs_cmd(process, write, mt, i, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	process(write, mt, i, context_free_abs_cmd(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...))
	return next_state(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
end

--decode a path and process each command using a processor function.
--state is optional and can be used for concatenating paths.
local function decode_path(process, write, path, mt, cpx, cpy, spx, spy, bx, by, qx, qy)
	for i,s in commands(path) do
		cpx, cpy, spx, spy, bx, by, qx, qy =
			decode_abs_cmd(process, write, mt, i, cpx, cpy, spx, spy, bx, by, qx, qy,
					 abs_cmd(cpx, cpy,
						  cmd(path, i)))
	end
	return cpx, cpy, spx, spy, bx, by, qx, qy
end

--return a decoder function that decodes and processes an arbitrary path command every time it is called, preserving
--and advancing the state between calls. also returns a function for retrieving the state after the last call.
local function command_decoder(process, write, mt, i, cpx, cpy, spx, spy, bx, by, qx, qy)
	return function(s, ...)
		cpx, cpy, spx, spy, bx, by, qx, qy =
			decode_abs_cmd(process, write, mt, i, cpx, cpy, spx, spy, bx, by, qx, qy,
					 abs_cmd(cpx, cpy, s, ...))
	end, function()
		return cpx, cpy, spx, spy, bx, by, qx, qy
	end
end

--point transform helper --------------------------------------------------------------------------

local function transform_points(mt, ...)
	if not mt then return ... end
	local n = select('#', ...)
	if n == 2 then
		return mt(...)
	elseif n == 4 then
		local x1, y1, x2, y2 = ...
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
		return x1, y1, x2, y2
	elseif n == 6 then
		local x1, y1, x2, y2, x3, y3 = ...
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
		x3, y3 = mt(x3, y3)
		return x1, y1, x2, y2, x3, y3
	elseif n == 8 then
		local x1, y1, x2, y2, x3, y3, x4, y4 = ...
		x1, y1 = mt(x1, y1)
		x2, y2 = mt(x2, y2)
		x3, y3 = mt(x3, y3)
		x4, y4 = mt(x4, y4)
		return x1, y1, x2, y2, x3, y3, x4, y4
	end
	assert(false)
end

--path simplification -------------------------------------------------------------------------------

local simplify = {}

--the processor function for path simplification.
local function simplify_processor(write, mt, i, s, ...)
	simplify[s](write, mt, ...)
end

--given a path and optionally a transformation matrix, simplify a path to down to primitive commands.
--primitive commands are: move, close, line, curve, quad_curve.
local function simplify_path(write, path, mt)
	decode_path(simplify_processor, write, path, mt)
end

function simplify.move(write, mt, x2, y2)
	write('move', transform_points(mt, x2, y2))
end

function simplify.close(write, mt, cpx, cpy, spx, spy)
	if cpx ~= spx or cpy ~= spy then
		write('line', transform_points(mt, spx, spy))
	end
	write('close')
end

function simplify.line(write, mt, x1, y1, x2, y2)
	write('line', transform_points(mt, x2, y2))
end

function simplify.quad_curve(write, mt, x1, y1, x2, y2, x3, y3)
	write('quad_curve', transform_points(mt, x2, y2, x3, y3))
end

function simplify.curve(write, mt, x1, y1, x2, y2, x3, y3, x4, y4)
	write('curve', transform_points(mt, x2, y2, x3, y3, x4, y4))
end

local elliptic_arc_to_bezier3 = require'path_elliptic_arc'.to_bezier3

function simplify.carc(write, mt, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if connect then
		local x1, y1 = elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		write(connect, x1, y1)
	end
	elliptic_arc_to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
end

--note: if rx * ry is negative, the ellipse is drawn counterclockwise.
function simplify.ellipse(write, mt, cx, cy, rx, ry, rotation)
	if rx == 0 or ry == 0 then return end --invalid parametrization, skip it
	local sweep_angle = rx*ry >= 0 and 360 or -360
	local x1, y1 = elliptic_arc_endpoints(cx, cy, rx, ry, 0, sweep_angle, rotation)
	write('move', transform_points(mt, x1, y1))
	elliptic_arc_to_bezier3(write, cx, cy, rx, ry, 0, sweep_angle, rotation, x1, y1, mt)
	write('close')
end

local rect_to_lines = require'path_shapes'.rect_to_lines

function simplify.rect(write, mt, x1, y1, w, h)
	rect_to_lines(write, x1, y1, w, h, mt)
end

--these shapes can draw themselves but can't transform themselves so we must write custom simplify for them.
--shapes can draw themselves using only primitive commands, starting in an empty state.
--the ability to draw composites using arbitrary path commands can be enabled in the code below (see comments).
local simplify_no_transform = {
	round_rect    = require'path_shapes'.round_rect_to_bezier3,
	elliptic_rect = require'path_shapes'.elliptic_rect_to_bezier3,
	star          = require'path_shapes'.star_to_lines,
	star_2p       = require'path_shapes'.star_2p_to_lines,
	rpoly         = require'path_shapes'.rpoly_to_lines,
	superformula  = require'path_shapes'.superformula_to_lines,
	text          = require'path_text'.to_bezier3,
}

for s,simplify_nt in pairs(simplify_no_transform) do
	simplify[s] = function(write, mt, ...)
		if not mt then
			--we know that composite commands draw themselves with only primitive commands so we write them directly.
			--if composite commands could have written other types of commands, we would not have had this branch.
			simplify_nt(write, ...)
		else
			--composite commands don't need a state to start with, and they don't leave any state behind.
			--we can't access the initial state from here anyway, and we can't return the final state either.
			local decoder = command_decoder(simplify_processor, write, mt)
			simplify_nt(decoder, ...)
		end
	end
end

function simplify.text(write, mt, x, y, font, text)
	write('text', x, y, font, text)
end

--recursive path decoding -------------------------------------------------------------------------

--decode a path and process its commands using a conditional processor. the processor will be tried for each command.
--for commands for which the processor returns false, simplify the command and then process the resulted segments.
--processors for primitive commands must never return false otherwise infinite recursion occurs.
local function decode_recursive(process, write, path, mt)
	local cpx, cpy, spx, spy, bx, by, qx, qy

	local function recursive_processor(write, mt, i, s, ...)
		if process(write, mt, i, s, ...) == false then
			local decoder = command_decoder(recursive_processor, write, mt, i, cpx, cpy, spx, spy, bx, by, qx, qy)
			simplify_processor(decoder, nil, i, s, ...)
		end
	end

	for i,s in commands(path) do
		cpx, cpy, spx, spy, bx, by, qx, qy =
			decode_abs_cmd(recursive_processor, write, mt, i, cpx, cpy, spx, spy, bx, by, qx, qy,
					 abs_cmd(cpx, cpy,
						  cmd(path, i)))
	end
end

--path bounding box -------------------------------------------------------------------------------

local bbox = {}

local function bbox_processor(write, mt, i, s, ...)
	if not bbox[s] then return false end
	return bbox[s](write, mt, ...)
end

local min, max = math.min, math.max
local function bounding_box(path, mt)
	local straight = not mt or mt:is_straight()
	local x1, y1, x2, y2
	local function write(x, y, w, h)
		local ax1, ay1, ax2, ay2 = x, y, x+w, y+h

		if mt and straight then
			ax1, ay1 = mt(ax1, ay1)
			ax2, ay2 = mt(ax2, ay2)
		end

		x1 = min(x1 or  1/0, ax1, ax2)
		y1 = min(y1 or  1/0, ay1, ay2)
		x2 = max(x2 or -1/0, ax1, ax2)
		y2 = max(y2 or -1/0, ay1, ay2)
	end
	decode_recursive(bbox_processor, write, path, not straight and mt or nil)
	return x1, y1, x2-x1, y2-y1
end

local line_bbox       = require'path_line'.bounding_box
local curve_bbox      = require'path_bezier3'.bounding_box
local quad_curve_bbox = require'path_bezier2'.bounding_box
local arc_bbox        = require'path_arc'.bounding_box
local ellipse_bbox    = require'path_shapes'.ellipse_bbox
local rect_bbox       = require'path_shapes'.rect_bbox

function bbox.move() end
function bbox.text() end

function bbox.line(write, mt, x1, y1, x2, y2)
	write(line_bbox(transform_points(mt, x1, y1, x2, y2)))
end

bbox.close = bbox.line

function bbox.curve(write, mt, x1, y1, x2, y2, x3, y3, x4, y4)
	write(curve_bbox(transform_points(mt, x1, y1, x2, y2, x3, y3, x4, y4)))
end

function bbox.quad_curve(write, mt, x1, y1, x2, y2, x3, y3)
	write(quad_curve_bbox(transform_points(mt, x1, y1, x2, y2, x3, y3)))
end

function bbox.carc(write, mt, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if mt or rx ~= ry or rotation ~= 0 then return false end
	if connect == 'line' then
		local x1, y1 = elliptic_arc_endpoints(cx, cy, rx, rx, start_angle, sweep_angle)
		write(line_bbox(cpx, cpy, x1, y1))
	end
	write(arc_bbox(cx, cy, rx, start_angle, sweep_angle))
end

function bbox.ellipse(write, mt, cx, cy, rx, ry, rotation)
	if mt or rotation ~= 0 then return false end
	write(ellipse_bbox(cx, cy, rx, ry))
end

function bbox.rect(write, mt, x, y, w, h)
	if mt then return false end
	write(rect_bbox(x, y, w, h))
end

bbox.round_rect = bbox.rect
bbox.elliptic_rect = bbox.rect

--path length ------------------------------------------------------------------------------------

local len = {}

local function len_processor(write, mt, i, s, ...)
	if not len[s] then return false end
	return len[s](write, mt, ...)
end
local function length(path, mt)
	local total = 0
	local function write(len)
		total = total + len
	end
	decode_recursive(len_processor, write, path, mt and not mt:has_unity_scale() and mt or nil)
	return total
end

line_len       = require'path_line'.length
quad_curve_len = require'path_bezier2'.length
curve_len      = require'path_bezier3'.length
arc_len        = require'path_arc'.length
circle_len     = require'path_shapes'.circle_length
rect_len       = require'path_shapes'.rect_length
round_rect_len = require'path_shapes'.round_rect_length

function len.move() end
function len.text() end

function len.line(write, mt, x1, y1, x2, y2)
	write(line_len(1, transform_points(mt, x1, y1, x2, y2)))
end

len.close = len.line

function len.curve(write, mt, x1, y1, x2, y2, x3, y3, x4, y4)
	write(curve_len(1, transform_points(mt, x1, y1, x2, y2, x3, y3, x4, y4)))
end

function len.quad_curve(write, mt, x1, y1, x2, y2, x3, y3)
	write(quad_curve_len(1, transform_points(mt, x1, y1, x2, y2, x3, y3)))
end

function len.carc(write, mt, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if mt or rx ~= ry or rotation ~= 0 then return false end
	if connect == 'line' then
		local x1, y1 = elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle)
		write(line_len(1, cpx, cpy, x1, y1))
	end
	write(arc_len(1, cx, cy, rx, start_angle, sweep_angle))
end

function len.ellipse(write, mt, cx, cy, rx, ry)
	if mt or rx ~= ry then return false end
	write(circle_len(cx, cy, rx))
end

function len.rect(write, mt, x, y, w, h)
	if mt then return false end
	write(rect_len(x, y, w, h))
end

function len.round_rect(write, mt, x, y, w, h, r)
	if mt then return false end
	write(round_rect_len(x, y, w, h, r))
end

--path hit -------------------------------------------------------------------------------------------

local ht = {}

local function hit(x0, y0, path, mt)
	local mi, md, mx, my, mt_
	local function write(i, d, x, y, t)
		if not md or d < md then
			mi, md, mx, my, mt_ = i, d, x, y, t
		end
	end
	local function hit_processor(write, mt, i, s, ...)
		if not ht[s] then
			return false --signal decoder to recurse.
		end
		return ht[s](write, mt, i, x0, y0, ...)
	end
	decode_recursive(hit_processor, write, path, mt)
	return md, mx, my, mi, mt_
end

local distance2        = require'path_point'.distance2
local line_hit         = require'path_line'.hit
local quad_curve_hit   = require'path_bezier2_hit'
local curve_hit        = require'path_bezier3_hit'
local elliptic_arc_hit = require'path_elliptic_arc'.hit
local arc_hit          = require'path_arc'.hit

function ht.move(write, mt, i, x0, y0, x2, y2)
	x2, y2 = transform_points(mt, x2, y2)
	write(i, distance2(x0, y0, x2, y2), x2, y2, 0)
end

function ht.text() end

function ht.line(write, mt, i, x0, y0, x1, y1, x2, y2)
	write(i, line_hit(x0, y0, transform_points(mt, x1, y1, x2, y2)))
end

ht.close = ht.line

function ht.curve(write, mt, i, x0, y0, x1, y1, x2, y2, x3, y3, x4, y4)
	write(i, curve_hit(x0, y0, transform_points(mt, x1, y1, x2, y2, x3, y3, x4, y4)))
end

function ht.quad_curve(write, mt, i, x0, y0, x1, y1, x2, y2, x3, y3)
	write(i, quad_curve_hit(x0, y0, transform_points(mt, x1, y1, x2, y2, x3, y3)))
end

function ht.carc(write, mt, i, x0, y0, cpx, cpy, connect, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
	if connect == 'line' then
		local x1, y1 = elliptic_arc_endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		if mt then cpx, cpy = mt(cpx, cpy) end
		local d, x, y, t = line_hit(x0, y0, cpx, cpy, x1, y1)
		write(i, d, x, y, t/2)
		local d, x, y, t = elliptic_arc_hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		write(i, d, x, y, 0.5 + t/2)
	else
		write(i, elliptic_arc_hit(x0, y0, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt))
	end
end

--path split -------------------------------------------------------------------------------------

local line_split       = require'path_line'.split
local quad_curve_split = require'path_bezier2'.split
local curve_split      = require'path_bezier3'.split

local split = {}

function split.line(path, i, t, s, rs, cpx, cpy, ...)
	local x, y = select(3, line_split(t, cpx, cpy, ...))
	if s == 'line' then
		insert_rel_cmd(path, i, cpx, cpy, rs, x, y)
	elseif s == 'hline' then
		insert_rel_cmd(path, i, cpx, cpy, rs, x)
	elseif s == 'vline' then
		insert_rel_cmd(path, i, cpx, cpy, rs, y)
	elseif s == 'arc_3p' then
		--TODO
	elseif s == 'svgarc' then
		--TODO
	end
end

function split.quad_curve(path, i, t, s, rs, cpx, cpy, ...)
	local
		x11, y11, x12, y12, x13, y13,
		x21, y21, x22, y22, x23, y23 = quad_curve_split(t, cpx, cpy, ...)
	if s == 'quad_curve' then
		 insert_rel_cmd(path, i,     rs, cpx, cpy, rs, x12, y12, x13, y13)
		replace_rel_cmd(path, i + 8, rs, cpx, cpy, rs, x22, y22, x23, y23)
	elseif s == 'symm_curve' then
		 insert_rel_cmd(path, i,     rs, cpx, cpy, rs, x13, y13)
		replace_rel_cmd(path, i + 8, rs, cpx, cpy, rs, x23, y23)
	end
end

local function split_path(path, i, t)
	local cpx, cpy, spx, spy, bx, by, qx, qy = state_at(path, i)
	local function process(s, ...)
		local rs = path[i]
		local as = abs_cmd(rs)
		split[s](path, i, t, as, rs, ...)
	end
	process(context_free_abs_cmd(cpx, cpy, spx, spy, bx, by, qx, qy,
								abs_cmd(cpx, cpy,
									 cmd(path, i))))
end

--path reverse -----------------------------------------------------------------------------------

local function reverse_path(path)
	local t = {}
	local function save(write, _, i, s, ...)
		t[#t+1] = {i, s, ...}
	end
	decode_path(save, write, path)

	local p = {}
	for ti = #t,1,-1 do
		local i, s = unpack(t[ti])
		local rs, as = path[i], abs_cmd(path[i])

		if s == 'close' then
			--insert_rel_cmd(p, 'move', ...
		end
	end
end

--[[
--path global time -------------------------------------------------------------------------------

local is_timed = glue.index{'close', 'line', 'hline', 'vline', 'curve', 'symm_curve', 'smooth_curve', 'quad_curve',
									'quad_curve_3p', 'symm_quad_curve', 'smooth_quad_curve', 'carc', 'arc', 'elliptic_arc',
									'line_arc', 'line_elliptic_arc', 'arc_3p', 'svgarc'}

local t = {}
for k in pairs(is_timed) do
	t['rel_'..k] = true
end
glue.update(is_timed, t)

local function global_time(i, t, path)
	local count = 0
	local n --the number of the command at index i, relative to count.
	for ci,s in commands(path) do
		count = count + (is_timed[s] and 1 or 0)
		if ci == i then n = count end
	end
	assert(n, 'invalid command index')
	return (n - 1 + t)/count
end

local function local_time(t, path)
	t = math.min(math.max(t, 0), 1)
	local count = 0
	for _,s in commands(path) do
		count = count + (is_timed[s] and 1 or 0)
	end
	if count == 0 then return end --path has no timed commands: any t is invalid.
	local n, t = math.modf(count * t)
	n = n + 1
	if n > count then
		n, t = count, 1
	end
	local count = 0
	for i,s in commands(path) do
		count = count + (is_timed[s] and 1 or 0)
		if count == n then
			return i, t
		end
	end
	--the time range 0..1 covers the timed commands continuously, so a command must always be found.
	assert(false)
end
]]

--command conversions ----------------------------------------------------------------------------

--[[

local function to_curves(path, i)
	local spath = {}
	local function write(s, ...)
		glue.append(spath, ...)
	end
	local cpx, cpy, spx, spy, bx, by, qx, qy = state_at(path, i)
	simplify_cmd(write, nil, cpx, cpy, spx, spy, bx, by, qx, qy,
		 bezier2_to_bezier3(cpx, cpy,
				canonical_cmd(cpx, cpy, spx, spy, bx, by, qx, qy,
						abs_cmd(cpx, cpy,
							 cmd(path, i)))))
	replace_cmd_t(path, i, spath)
end

--given a command in canonical form and the current point, return a 'line' command that best approximates it.
local function to_line(cpx, cpy, spx, spy, s, ...)
	local x2, y2 = next_state(cpx, cpy, spx, spy, nil, nil, nil, nil, s, ...)
	if x2 then return 'line', x2, y2 end
end

local line_point = require'path_line'.point
local b3_to_b2 = require'path_bezier3'.to_bezier2

--given a command in canonical form and the current point, return a 'quad_curve' command that best approximates it.
local function to_quad_curve(cpx, cpy, s, ...)
	if s == 'quad_curve' then
		return s, ...
	elseif s == 'line' then
		local x2, y2 = line_point(0.5, cpx, cpy, ...)
		return 'quad_curve', x2, y2, ...
	elseif as == 'curve' then
		return 'quad_curve', select(3, b3_to_b2(cpx, cpy, ...))
	end
end

--given a command in canonical form and the current point, return a 'curve' command that best approximates it.
local function to_curve(cpx, cpy, s, ...)
	if s == 'curve' then
		return s, ...
	elseif s == 'line' then
		local x2, y2 = line_point(1/3, cpx, cpy, ...)
		local x3, y3 = line_point(2/3, cpx, cpy, ...)
		return 'curve', x2, y2, x3, y3, ...
	elseif s == 'quad_curve' then
		return 'curve', select(3, b2_to_b3(cpx, cpy, ...))
	end
end

--
local function to_smooth(cpx, cpy, bx, by, qx, qy, s, ...)
	if s == 'curve' then
		return 'smooth_curve', ...
	elseif s == 'quad_curve' then
		return 'smooth_quad_curve', ...
	end
end

local function to_symm(cpx, cpy, bx, by, qx, qy, s, ...)
	if s == 'curve' then
		return 'smooth_curve', ...
	elseif s == 'quad_curve' then
		return 'smooth_quad_curve', ...
	end
end

local function to_cusp(cpx, cpy, bx, by, qx, qy, s, ...)
	if s == 'curve' then
		return 'smooth_curve', ...
	elseif s == 'quad_curve' then
		return 'smooth_quad_curve', ...
	end
end

local function to_arc_3p() end
local function to_arc() end
local function to_svgarc() end

-- conversions table --------------------------------------------------------------

local conversions = {}

for _,s in ipairs{'line', 'curve', 'quad_curve', 'arc'} do
	--abs. commands can be made rel.
	conversions[s] = {
		['to absolute'] = toggle_rel,
	}

	--rel. commands can be made abs.
	conversions['rel_'..s] = {
		['to relative'] = toggle_rel,
	}
end

local line_conversions = {
	['to curve'] = to_curve,
}
glue.update(conversions.line,     line_conversions)
glue.update(conversions.rel_line, line_conversions)

local curve_conversions = {
	['to line'] = to_line,
}
glue.update(conversions.curve,     curve_conversions)
glue.update(conversions.rel_curve, curve_conversions)

local arc_conversions = {
	['to 3-point arc']  = to_arc_3p,
	['to elliptic arc'] = to_svgarc,
}
glue.update(conversions.arc,     arc_conversions)
glue.update(conversions.rel_arc, arc_conversions)

--TODO: composites can be converted to curves

--path transformation

--check if a command is transformable by an affine transformation.
local function is_transformable(s)

end
]]

if not ... then require'path_cairo_demo' end

return {
	--iterating
	argc = argc,
	next_cmd = next_cmd,
	commands = commands,
	cmd = cmd,
	--modifying
	insert = insert,
	replace = replace,
	remove = remove,
	--decoding
	is_rel = is_rel,
	abs_name = abs_name,
	abs_cmd = abs_cmd,
	simplify = simplify_path,
	--measuring
	bounding_box = bounding_box,
	length = length,
	length_at = length_at,
	local_time = local_time,
	global_time = global_time,
	point = point,
	hit = hit,
	--editing
	split = split_path,
}

