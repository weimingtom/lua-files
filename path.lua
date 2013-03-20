--2d path API including iterating, decoding, updating, converting, measuring, etc.

local assert, unpack, select, min, max =
	   assert, unpack, select, math.min, math.max

--iterating commands

local argc = {
	--control commands (current point)
	move = 2,
	close = 0,
	['break'] = 0,
	--lines and curves (primitives)
	line = 2,
	hline = 1,
	vline = 1,
	curve = 6,
	symm_curve = 4,
	smooth_curve = 5,
	quad_curve = 4,
	quad_curve_3p = 4,
	symm_quad_curve = 2,
	smooth_quad_curve = 3,
	--arcs (tied composites)
	arc = 5,
	arc_3p = 4,
	svgarc = 7,
	--axis-aligned shapes (closed composites)
	rect = 4,
	round_rect = 5,
	ellipse = 4,
	circle = 3,
	circle_3p = 6,
	star = 6,
	star_2p = 7,
	rpoly = 4,
	superformula = 10,
	--text (multiple closed composites)
	text = 4,
	--transformations
	scale = 1,
	scale_x = 1,
	scale_y = 2,
	skew_x = 1,
	skew_y = 1,
	rotate = 1,
}

--all commands with arguments have relative-to-current-point counterparts with the same number of arguments.
for k,n in pairs(argc) do
	if n > 0 then
		argc['rel_'..k] = n
	end
end

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
	return unpack(path, i, i+argc[path[i]])
end

--adding, replacing and removing commands

local tinsert, tremove = table.insert, table.remove

--insert n elements at i, shifting elemens on the right of i (i inclusive) to the right.
local function table_insert(t, i, n)
	if n == 1 then --shift 1
		tinsert(t, i)
		return
	end
	for p = #t,i,-1 do --shift n
		t[p+n] = t[p]
	end
end

--remove n elements at i, shifting elements on the right of i (i inclusive) to the left.
local function table_remove(t, i, n)
	n = min(n, #t-i+1)
	if n == 1 then --shift 1
		tremove(t, i)
		return
	end
	for p=i+n,#t do --shift n
		t[p-n] = t[p]
	end
	for p=#t,#t-n+1,-1 do --clean tail
		t[p] = nil
	end
end

--update table elements at i in place.
local function table_update(t, i, ...)
	for k=1,select('#',...) do
		t[i+k-1] = select(k,...)
	end
end

--insert command at i, shifting elemetns as needed.
local function insert(path, i, s, ...)
	table_insert(path, i, 1 + select('#',...))
	table_update(path, i, s, ...)
end

--replace command at i with a new command and args, shifting elements as needed.
local function replace(path, i, s, ...)
	local old = argc[path[i]]
	local new = select('#', ...)
	table_insert(path, i+1, max(0, new-old))
	table_remove(path, i+1, max(0, old-new))
	table_update(path, i, s, ...)
end

--remove command at i, shifting elements as needed.
local function remove(path, i)
	table_remove(path, i, 1 + argc[path[i]])
end

--path decoding

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

--given current point and an unpacked command and its args, return the command in absolute form.
local function abs_cmd(cpx, cpy, s, ...)
	if is_abs(s) then return s, ... end
	assert(cpx and cpy, 'no current point')
	s = abs_name(s)
	if s == 'move' or s == 'line' then
		local s, x2, y2 = ...
		return s, cpx + x2, cpy + y2
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
	elseif s == 'arc' then
		local cx, cy = ...
		return s, cpx + cx, cpy + cy, select(3, ...)
	elseif s == 'arc_3p' or s == 'circle_3p' then
		local x2, y2, x3, y3 = ...
		return s, cpx + x2, cpy + y2, cpx + x3, cpy + y3
	elseif s == 'svgarc' then
		local rx, ry, angle, large_arc_flag, sweep_flag, x2, y2 = ...
		return s, rx, ry, angle, large_arc_flag, sweep_flag, cpx + x2, cpy + y2
	elseif s == 'rect' then
		local x, y, w, h = ...
		return s, cpx + x, cpy + y, w, h
	elseif s == 'round_rect' then
		local x, y, w, h, r = ...
		return s, cpx + x, cpy + y, w, h, r
	elseif s == 'ellipse' then
		local cx, cy, rx, ry = ...
		return s, cpx + cx, cpy + cy, rx, ry
	elseif s == 'circle' then
		local cx, cy, r = ...
		return s, cpx + cx, cpy + cy, r
	elseif s == 'star' then
		local cx, cy, x1, y1, r2, n = ...
		return s, cpx + cx, cpy + cy, cpx + x1, cpy + y1, r2, n
	elseif s == 'star_2p' then
		local cx, cy, x1, y1, x2, y2, n = ...
		return s, cpx + cx, cpy + cy, cpx + x1, cpy + y1, cpx + x2, cpy + y2, n
	elseif s == 'rpoly' then
		local cx, cy, x1, y1, n = ...
		return s, cpx + cx, cpy + cy, cpx + x1, cpy + y1, n
	elseif s == 'superformula' then
		local cx, cy = ...
		return s, cpx + cx, cpy + cy, select(3, ...)
	elseif s == 'text' then
		local x1, y1 = ...
		return s, cpx + x1, cpy + y1, select(3, ...)
	else
		error'invalid command'
	end
end

--given a rel. or abs. command name and abs. args, encode the command as abs. or rel. according to the name.
local function to_rel(cpx, cpy, s, ...)
	return abs_cmd(-cpx, -cpy, s, ...)
end

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local bezier2_3point_control_point = require'path_bezier2'._3point_control_point
local arc_endpoints = require'path_arc'.endpoints

--given current state and current command in abs. form, return the state of the next path command.
--cpx, cpy is the next "current point", needed by all relative commands and by most other commands.
--spx, spy is the starting point of the current subpath, needed by the "close" command.
--bx,by is the 2nd control point of the current command if it was a cubic bezier, needed by symmetric cubic beziers.
--qx,qy is the control point of the current command if it was a quad bezier, needed by symmetric quad beziers.
--smooth curves will use either bx,by or qx,qy, whichever is available, because they only need the angle from it.
--NOTE! arcs should set bx,by if the next command is a smooth curve of any kind, but we don't set it here.
local function next_state(cpx, cpy, spx, spy, bx1, by1, qx1, qy1, s, ...)
	local _, bx, by, qx, qy
	if s == 'move' then
		cpx, cpy = ...
		spx, spy = ...
	elseif s == 'line' then
		cpx, cpy = ...
	elseif s == 'close' then
		cpx, cpy = spx, spy
	elseif s == 'break' then
		cpx, cpy, spy, spy = nil
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
	elseif s == 'arc' then
		_, _, cpx, cpy = arc_endpoints(...)
	elseif s == 'arc_3p' then
		_, _, cpx, cpy = ...
	elseif s == 'svgarc' then
		cpx, cpy = select(6,...)
	else --closed composite shapes cannot be continued from
		cpx, cpy, spx, spy = nil
	end
	return cpx, cpy, spx, spy, bx, by, qx, qy
end

--return the state of the path command at an arbitrary index.
local function state_at(path, di)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in commands(path) do
		if i == di then
			return cpx, cpy, spx, spy, bx, by, qx, qy
		end
		cpx, cpy, spx, spy, bx, by, qx, qy =
			next_state(cpx, cpy, spx, spy, bx, by, qx, qy, abs_cmd(cpx, cpy, cmd(path, i)))
	end
	error'invalid path index'
end

--check if a command is a primitive drawing command that can be decoded with decode_primitive().
local function is_primitive(s)
	return s == 'move' or s == 'rel_move' or s == 'close' or s:match'line$' or s:match'curve$' or false
end

--given current state and a primitive cmd in abs. form, return the corresponding context-free cmd and args.
--primitive context-free drawing commands are line, quad_curve and curve, and line cap commands are move and close.
local function decode_primitive(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	if s == 'move' or s == 'line' then
		return s, cpx, cpy, ...
	elseif s == 'close' then
		return 'line', cpx, cpy, spx, spy
	elseif s == 'hline' then
		return 'line', cpx, cpy, ..., cpy
	elseif s == 'vline' then
		return 'line', cpx, cpy, cpx, ...
	elseif s == 'curve' then
		return 'curve', cpx, cpy, ...
	elseif s == 'symm_curve' then
		local x2, y2 = reflect_point(bx, by, cpx, cpy)
		return 'curve', cpx, cpy, x2, y2, ...
	elseif s == 'smooth_curve' then
		local x2, y2 = reflect_point_distance(bx or qx, by or qy, cpx, cpy, (...))
		return 'curve', cpx, cpy, x2, y2, select(2, ...)
	elseif s == 'quad_curve' then
		return 'quad_curve', cpx, cpy, ...
	elseif s == 'quad_curve_3p' then
		local x2, y2, x3, y3 = ...
		local x2, y2 = quad_curve_3point_control_point(cpx, cpy, x2, y2, x3, y3)
		return 'quad_curve', cpx, cpy, x2, y2, x3, y3
	elseif s == 'symm_quad_curve' then
		local x2, y2 = reflect_point(qx, qy, cpx, cpy)
		return 'quad_curve', cpx, cpy, x2, y2, ...
	elseif s == 'smooth_quad_curve' then
		local x2, y2 = reflect_point_distance(bx or qx, by or qy, cpx, cpy, (...))
		return 'quad_curve', cpx, cpy, x2, y2, select(2, ...)
	else
		error 'invalid command'
	end
end

--given a context-free primitive drawing command, transform it with an affine transformation matrix.
local function transform_decoded(mt, s, ...)
	if not mt then return s, ... end
	if s == 'move' or s == 'line' then
		local x1, y1, x2, y2 = ...
		x1, y1 = mt:transform_point(x1, y1)
		x2, y2 = mt:transform_point(x2, y2)
		return s, x1, y1, x2, y2
	elseif s == 'quad_curve' then
		local x1, y1, x2, y2, x3, y3 = ...
		x1, y1 = mt:transform_point(x1, y1)
		x2, y2 = mt:transform_point(x2, y2)
		x3, y3 = mt:transform_point(x3, y3)
		return s, x1, y1, x2, y2, x3, y3
	elseif s == 'curve' then
		local x1, y1, x2, y2, x3, y3, x4, y4 = ...
		x1, y1 = mt:transform_point(x1, y1)
		x2, y2 = mt:transform_point(x2, y2)
		x3, y3 = mt:transform_point(x3, y3)
		x4, y4 = mt:transform_point(x4, y4)
		return s, x1, y1, x2, y2, x3, y3, x4, y4
	end
end

local function write_primitive(write_fcmd, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	if accept and not accept[s] then return end
	write_fcmd(i, transform_decoded(mt, decode_primitive(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)))
end

local composite_converters = {
	--arcs
	arc = require'path_arc'.to_bezier3,
	arc_3p = require'path_arc_3p'.to_bezier3,
	svgarc = require'path_svgarc'.to_bezier3,
	--closed shapes
	rect         = require'path_shapes'.rectangle,
	round_rect   = require'path_shapes'.round_rectangle,
	ellipse      = require'path_shapes'.ellipse,
	circle       = require'path_shapes'.circle,
	circle_2p    = require'path_shapes'.circle_2p,
	star         = require'path_shapes'.star,
	star_2p      = require'path_shapes'.star_2p,
	rpoly        = require'path_shapes'.regular_polygon,
	superformula = require'path_shapes'.superformula,
	--text
	text = require'path_text'.to_bezier3,
}

--check if a command is a composite drawing command that can be decoded with decode_composite().
local function is_composite(s)
	return composite_converters[abs_name(s)] and true or false
end

--given current state and a composite cmd in abs. form, return the corresponding context-free drawing cmd and args.
local function decode_composite(cpx, cpy, s, ...)
	if s == 'arc_3p' then
		return s, cpx, cpy, ...
	else
		return s, ...
	end
end

--given a composite command in abs. form and the current state, write out the context-free drawing commands for it.
local function write_composite(write_fcmd, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)

	--arcs are special: if there's a current point, we need to draw a line from there to the arc's starting point.
	if s == 'arc' then
		local x1, y1 = arc_endpoints(...)
		if cpx then
			write_fcmd(i, transform_decoded(mt, 'line', cpx, cpy, x1, y1))
		end
		cpx, cpy = x1, y1
	end

	--if there's no transformation, pass through accepted composites without decomposing them.
	if not mt and accept and accept[s] then
		write_fcmd(i, decode_composite(cpx, cpy, s, ...))
		return
	end

	local function write(s, ...)
		write_primitive(write_fcmd, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	end
	composite_converters[s](write, select(2, decode_composite(cpx, cpy, s, ...)))
end

--decode a path, optionally transforming it by an affine transform, and write it out as primitive context-free cmds.
--callstack for a primitive command:
--  next_cmd->is_primitive->cmd->abs_cmd->write_primitive->decode_primitive->transform_decoded->write_fcmd.
local function decode(write_fcmd, path, mt, accept)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in commands(path) do
		if is_primitive(s) then
			write_primitive(write_fcmd, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, abs_cmd(cpx, cpy, cmd(path, i)))
		elseif is_composite(s) then
			write_composite(write_fcmd, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, abs_cmd(cpx, cpy, cmd(path, i)))
		else
			error'invalid command'
		end
		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(cpx, cpy, spx, spy, bx, by, qx, qy, abs_cmd(cpx, cpy, cmd(path, i)))
	end
end


if not ... then

decode(print, {
	'move', 100, 100, 'rel_round_rect', 10, 10, 50, 50, 10, 'move', 0, 0,
	'arc', 10, 10, 50, 0, 120,
	'arc_3p', 20, 20, 0, 0,
	},
	nil,
	{move = true, close = true, line = true, curve = true, arc = true})

end

--path measuring

local bbox_functions = {
	line       = require'path_line'.bounding_box,
	bezier2    = require'path_bezier2'.bounding_box,
	bezier3    = require'path_bezier3'.bounding_box,
	arc        = require'path_arc'.bounding_box,
	arc_3p     = require'path_arc_3p'.bounding_box,
	ellipse    = require'path_shapes'.ellipse_bbox,
	circle     = require'path_shapes'.circle_bbox,
	rect       = require'path_shapes'.rectangle_bbox,
	round_rect = require'path_shapes'.round_rectangle_bbox,
}

local function bounding_box(path, mt)
	local x1, y1, x2, y2
	local function write(i, s, ...)
		local x, y, w, h = bbox_functions[s](...)
		x1 = min(x1 or 1/0, x)
		y1 = min(y1 or 1/0, y)
		x2 = max(x2 or -1/0, x+w)
		y2 = max(y2 or -1/0, y+h)
	end
	decode(write, path, mt, bbox_functions)
	return x1, y1, x2-x1, y2-y1
end

local length_functions = {
	line       = require'path_line'.length,
	bezier2    = require'path_bezier2'.length,
	bezier3    = require'path_bezier3'.length,
	arc        = require'path_arc'.length,
	arc_3p     = require'path_arc_3p'.length,
	circle     = require'path_shapes'.circle_length,
	rect       = require'path_shapes'.rectangle_length,
	round_rect = require'path_shapes'.round_rectangle_length,
}

local function length(path, mt)
	local length = 0
	local function write(i, s, ...)
		length = length + length_functions[s](...)
	end
	decode(write, path, mt, length_functions)
	return length
end

local function command_count(path)
	local count
	for i,s in commands(path) do
		count = count + 1
	end
	return count
end

local function global_time(i, t, path)
	local count = command_count(path)
	return (i-1+t)/count
end

local function local_time(t, path)
	local count = command_count(path)
	return i, path
end

local point_functions = {
	line    = require'path_line'.point,
	bezier2 = require'path_bezier2'.point,
	bezier3 = require'path_bezier3'.point,
	arc     = require'path_arc'.point,
	arc_3p  = require'path_arc_3p'.point,
}

local function point(t, path)
	local i,t = local_time(t, path)

	local function write(i, s, ...)
		point_functions[s](...)
	end
	decode(write, path)
end

local hit_functions = {
	line    = require'path_line'.hit,
	bezier2 = require'path_bezier2_hit',
	bezier3 = require'path_bezier3_hit',
	arc     = require'path_arc'.hit,
	arc_3p  = require'path_arc_3p'.hit,
}

local function hit(path, mt)
	local md, mx, my, mt, mi
	local function write(i, s, ...)
		local d, x, y, t = hit_functions[s](...)
		if not md or d < md then
			md, mx, my, mt, mi = d, x, y, t, i
		end
	end
	decode(write, path)
	return md, mx, my, mi, mt
end

--command conversions

local function to_line(cpx, cpy, s, ...)
	local as = abs_name(s)
	local ds = is_rel(s) and 'rel_line' or 'line'
	if as == 'curve' then
		local x4, y4 = select(6, abs_cmd(cpx, cpy, s, ...))
		return to_rel(cpx, cpy, ds, x4, y4)
	end
end

local line_point = require'path_line'.point
local bezier2_control_point = require'path_bezier3'.bezier2_control_point

local function to_bezier2(cpx, cpy, s, ...)
	local as = abs_name(s)
	local ds = is_rel(s) and 'rel_quad_curve' or 'quad_curve'
	if as == 'line' then
		local _, x3, y3 = abs_cmd(cpx, cpy, s, ...)
		local x2, y2 = line_point(0.5, cpx, cpy, x3, y3)
		return to_rel(cpx, cpy, ds, x2, y2, x3, y3)
	elseif as == 'curve' then
		local _, x2, y2, x3, y3, x4, y4 = abs_cmd(cpx, cpy, s, ...)
		local x2, y2 = bezier2_control_point(cpx, cpy, x2, y2, x3, y3, x4, y4)
		return to_rel(cpx, cpy, ds, x2, y2, x4, y4)
	end
end

local function to_bezier3(cpx, cpy, s, ...)
	local as = abs_name(s)
	local ds = is_rel(s) and 'rel_curve' or 'curve'
	if as == 'line' then
		local _, x4, y4 = abs_cmd(cpx, cpy, s, ...)
		local x2, y2 = line_point(1/3, cpx, cpy, x4, y4)
		local x3, y3 = line_point(2/3, cpx, cpy, x4, y4)
		return to_rel(cpx, cpy, ds, x2, y2, x3, y3, x4, y4)
	elseif s == 'quad_curve' then
		local _, x2, y2, x4, y4 = abs_cmd(cpx, cpy, s, ...)
		local x2, y2, x3, y3 = bezier3_control_points(cpx, cpy, x2, y2, x4, y4)
		return to_rel(cpx, cpy, ds, x2, y2, x3, y3, x4, y4)
	end
end

local function to_smooth() end
local function to_symm() end
local function to_cusp() end
local function to_arc_3p() end
local function to_arc() end
local function to_svgarc() end

--path transformation

--check if a command is transformable by an affine transformation.
local function is_transformable(s)

end

--path editing

local split_functions = {
	line = require'path_line'.split,
	bezier2 = require'path_bezier2'.split,
	bezier3 = require'path_bezier3'.split,
}

local function split(t, path)
	local function write(s, ...)

	end
	decode(write, path)
end

local function join(path)

end

if not ... then require'path_test' end

return {
	--iterating
	argc = argc,
	next_cmd = next_cmd,
	commands = comamnds,
	cmd = cmd,
	--modifying
	insert = insert,
	replace = replace,
	remove = remove,
	--decoding
	is_rel = is_rel,
	abs_name = abs_name,
	abs_cmd = abs_cmd,
	decode = decode,
	--measuring
	bounding_box = bounding_box,
	length = length,
	point = point,
	hit = hit,
	--editing
	split = split,
}

