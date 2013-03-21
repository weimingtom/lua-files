--2d path API: supports lines, with horiz. and vert. variations, quadratic beziers and cubic beziers, with smooth
--and symmetrical variations, absolute and relative variations for all commands, circular arcs, 3-point circular arcs,
--svg-style elliptical arcs, text, and composite shapes that can be composed of other primitive/composite shapes.
--supports affine transforms, bounding box, length-at-t, point-at-t, shortest-distance-to-point, splitting, editing.

local assert, unpack, select, min, max =
	   assert, unpack, select, math.min, math.max

-- iterating path commands ------------------------------------------------------------------------

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
local function table_update(dt, i, ...)
	for k=1,select('#',...) do
		dt[i+k-1] = select(k,...)
	end
end

local function table_update_t(dt, i, t)
	for k=1,#t do
		dt[i+k-1] = t[k]
	end
end

--insert command at i, shifting elemetns as needed.
local function insert_cmd(path, i, s, ...)
	local n = select('#', ...)
	assert(n == argc[s], 'wrong argument count')
	table_insert(path, i, 1 + n)
	table_update(path, i, s, ...)
end

--replace command at i with a new command and args, shifting elements as needed.
local function replace_cmd(path, i, s, ...)
	local old = argc[path[i]]
	local new = select('#', ...)
	assert(new == argc[s], 'wrong argument count')
	table_insert(path, i+1, max(0, new-old))
	table_remove(path, i+1, max(0, old-new))
	table_update(path, i, s, ...)
end

local function replace_cmd_t(path, i, s, t)
	local old = argc[path[i]]
	local new = #t
	table_insert(path, i+1, max(0, new-old))
	table_remove(path, i+1, max(0, old-new))
	table_update_t(path, i, s, t)
end

--remove command at i, shifting elements as needed.
local function remove_cmd(path, i)
	table_remove(path, i, 1 + argc[path[i]])
end

--decoding path commands -----------------------------------------------------------------------------

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
		local x2, y2 = ...
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

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local bezier2_3point_control_point = require'path_bezier2'._3point_control_point
local arc_endpoints = require'path_arc'.endpoints

--given current command in abs. form and current state, return the state of the next path command.
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

--given a command in abs. form, return the cmd in canonical form, reducing line and curve variations.
local function canonical_cmd(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	if s == 'hline' then
		return 'line', ..., cpy
	elseif s == 'vline' then
		return 'line', cpx, ...
	elseif s == 'symm_curve' then
		local x2, y2 = reflect_point(bx, by, cpx, cpy)
		return 'curve', x2, y2, ...
	elseif s == 'smooth_curve' then
		local x2, y2 = reflect_point_distance(bx or qx, by or qy, cpx, cpy, (...))
		return 'curve', x2, y2, select(2, ...)
	elseif s == 'quad_curve_3p' then
		local x2, y2, x3, y3 = ...
		local x2, y2 = bezier2_3point_control_point(cpx, cpy, x2, y2, x3, y3)
		return 'quad_curve', x2, y2, x3, y3
	elseif s == 'symm_quad_curve' then
		local x2, y2 = reflect_point(qx, qy, cpx, cpy)
		return 'quad_curve', x2, y2, ...
	elseif s == 'smooth_quad_curve' then
		local x2, y2 = reflect_point_distance(bx or qx, by or qy, cpx, cpy, (...))
		return 'quad_curve', x2, y2, select(2, ...)
	else --other commands are already in canonical form.
		return s, ...
	end
end

--given a canonical primitive command, transform its points with an affine transformation matrix.
local function transformed_cmd(mt, s, ...)
	if not mt then return s, ... end
	if s == 'move' or s == 'line' then
		return s, mt:transform_point(...)
	elseif s == 'quad_curve' then
		local x2, y2, x3, y3 = ...
		x2, y2 = mt:transform_point(x2, y2)
		x3, y3 = mt:transform_point(x3, y3)
		return s, x2, y2, x3, y3
	elseif s == 'curve' then
		local x2, y2, x3, y3, x4, y4 = ...
		x2, y2 = mt:transform_point(x2, y2)
		x3, y3 = mt:transform_point(x3, y3)
		x4, y4 = mt:transform_point(x4, y4)
		return s, x2, y2, x3, y3, x4, y4
	elseif s == 'close' or s == 'break' then
		return s
	else
		error'invalid command'
	end
end

local starts_with_cp = {move = 1, line = 1, curve = 1, quad_curve = 1, arc_3p = 1, svgarc = 1}

--given a cmd in canonical form and current state, return the cmd in context-free form.
local function context_free_cmd(cpx, cpy, spx, spy, s, ...)
	if starts_with_cp[s] then
		return s, cpx, cpy, ...
	else --other commands are already in context-free form.
		return s, ...
	end
end

--given a primitive command in context-free form, transform it using an affine transformation matrix.
local function transformed_context_free_cmd(mt, s, cpx, cpy, ...)
	if s == 'close' or s == 'break' then
		return s
	end
	if cpx and mt then cpx, cpy = mt:transform_point(cpx, cpy) end
	return s, cpx, cpy, select(2, transformed_cmd(mt, s, ...))
end

local decomposers = {
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

local function write_cmd(write, i, mt, accept, s, ...)
	if accept and not accept[s] then return end
	write(i, transformed_context_free_cmd(mt, s, ...))
end

local primitives = {move = 1, close = 1, ['break'] = 1, line = 1, curve = 1, quad_curve = 1}

local decode_cmd --forward decl.

--given a command in context-free form and the current state, decompose it into primitive, context-free commands.
local function decode_cmd_pass(write, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)

	--draw the connecting line of the 'close' command.
	if s == 'close' then
		write_cmd(write, i, mt, accept, 'line', cpx, cpy, spx, spy)
	end

	--write non-composite commands directly.
	if primitives[s] then
		write_cmd(write, i, mt, accept, s, ...)
		return
	end

	--arcs are special: if there's a current point, we need to draw a line from there to the arc's starting point.
	if s == 'arc' then
		local x1, y1 = arc_endpoints(...)
		if cpx then
			write_cmd(write, i, mt, accept, 'line', cpx, cpy, x1, y1)
		end
		cpx, cpy = x1, y1 --important: set current point to arc's starting point.
	end

	--pass through accepted composites without decomposing them.
	if accept and not mt and accept[s] then
		write(i, s, ...)
		return
	end

	--finally, we're left with composite commands which we decompose and decode recursively.
	local function write_recursive(s, ...)
		cpx, cpy, spx, spy, bx, by, qx, qy =
			decode_cmd(write, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	end
	decomposers[s](write_recursive, ...)
end

--given an arbitrary unpacked command and the current state, decompose it into primitive, context-free commands.
function decode_cmd(write, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)

	decode_cmd_pass(write, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy,
		context_free_cmd(cpx, cpy, spx, spy,
			canonical_cmd(cpx, cpy, spx, spy, bx, by, qx, qy,
					abs_cmd(cpx, cpy, s, ...))))

	return next_state(cpx, cpy, spx, spy, bx, by, qx, qy,
				abs_cmd(cpx, cpy, s, ...))
end

--decode a path, optionally transforming it by an affine transform, and write it out as primitive context-free cmds.
local function decode(write, path, mt, accept)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in commands(path) do
		cpx, cpy, spx, spy, bx, by, qx, qy =
			decode_cmd(write, i, mt, accept, cpx, cpy, spx, spy, bx, by, qx, qy, cmd(path, i))
	end
end

-- decoding paths for drawing ----------------------------------------------------------------

local b2_to_b3 = require'path_bezier2'.bezier2_to_bezier3

local function bezier2_to_bezier3(cpx, cpy, s, ...)
	if s == 'quad_curve' then
		return 'curve', select(3, b2_to_b3(cpx, cpy, ...))
	else
		return s, ...
	end
end

local simplify_cmd --forward decl.

--given a command in simplified form and the current state, decompose it into primitive commands.
local function simplify_cmd_pass(write, mt, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)

	--write non-composite commands directly.
	if primitives[s] then
		write(transformed_cmd(mt, s, ...))
		return
	end

	--arcs are special: we need to emit a move or a line to the arc's starting point.
	if s == 'arc' then
		local x1, y1 = arc_endpoints(...)
		write(transformed_cmd(mt, cpx and 'line' or 'move', x1, y1))
	end

	--finally, we're left with composite commands which we decompose and simplify recursively.
	local function write_recursive(s, ...)
		cpx, cpy, spx, spy, bx, by, qx, qy =
			simplify_cmd(write, mt, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	end
	decomposers[s](write_recursive, select(2, context_free_cmd(cpx, cpy, spx, spy, s, ...)))
end

--given an arbitrary unpacked command and the current state, decompose it into primitive commands.
function simplify_cmd(write, mt, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)

	simplify_cmd_pass(write, mt, cpx, cpy, spx, spy, bx, by, qx, qy,
	 bezier2_to_bezier3(cpx, cpy,
			canonical_cmd(cpx, cpy, spx, spy, bx, by, qx, qy,
					abs_cmd(cpx, cpy, s, ...))))

	return next_state(cpx, cpy, spx, spy, bx, by, qx, qy,
					abs_cmd(cpx, cpy, s, ...))
end

--decode a path, optionally transforming it by an affine transform, and write it out as primitive contextual cmds.
local function simplify(write, path, mt)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	for i,s in commands(path) do
		cpx, cpy, spx, spy, bx, by, qx, qy =
			simplify_cmd(write, mt, cpx, cpy, spx, spy, bx, by, qx, qy, cmd(path, i))
	end
end


if not ... then

local mt = require'trans_affine2d'.new()

decode(print, {
	'move', 100, 100, 'rel_round_rect', 10, 10, 50, 50, 10,
	'move', 0, 0,
	'arc', 10, 10, 50, 0, 120,
	'arc_3p', 20, 20, 0, 0,
	'close',
	'break',
	},
	mt,
	{move = true, close = true, line = true, curve = true, arc = true, ['break'] = true})

end

--path measuring

local glue = require'glue'

local bbox_functions = {
	line       = require'path_line'.bounding_box,
	quad_curve = require'path_bezier2'.bounding_box,
	curve      = require'path_bezier3'.bounding_box,
}

local bbox_functions_no_trans = glue.update({
	arc        = require'path_arc'.bounding_box,
	arc_3p     = require'path_arc_3p'.bounding_box,
	ellipse    = require'path_shapes'.ellipse_bbox,
	rect       = require'path_shapes'.rectangle_bbox,
	round_rect = require'path_shapes'.round_rectangle_bbox,
	circle     = require'path_shapes'.circle_bbox,
}, bbox_functions)

local function bounding_box(path, mt)
	local x1, y1, x2, y2
	local function write(i, s, ...)
		local x, y, w, h = bbox_functions[s](...)
		x1 = min(x1 or 1/0, x)
		y1 = min(y1 or 1/0, y)
		x2 = max(x2 or -1/0, x+w)
		y2 = max(y2 or -1/0, y+h)
	end
	decode(write, path, mt, mt and bbox_functions or bbox_functions_no_trans)
	return x1, y1, x2-x1, y2-y1
end

local length_functions = {
	line       = require'path_line'.length,
	quad_curve = require'path_bezier2'.length,
	curve      = require'path_bezier3'.length,
}

local length_functions_no_trans = glue.update({
	arc        = require'path_arc'.length,
	arc_3p     = require'path_arc_3p'.length,
	circle     = require'path_shapes'.circle_length,
	rect       = require'path_shapes'.rectangle_length,
	round_rect = require'path_shapes'.round_rectangle_length,
}, length_functions)

local function length(path, mt)
	local length = 0
	local function write(i, s, ...)
		length = length + length_functions[s](...)
	end
	decode(write, path, mt, mt and length_functions or length_functions_no_trans)
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
	line       = require'path_line'.point,
	quad_curve = require'path_bezier2'.point,
	curve      = require'path_bezier3'.point,
}

local point_functions_no_trans = glue.update({
	arc        = require'path_arc'.point,
	arc_3p     = require'path_arc_3p'.point,
}, point_functions)

local function point(t, path)
	local i,t = local_time(t, path)

	local function write(i, s, ...)
		point_functions[s](...)
	end
	decode(write, path)
end

local hit_functions = {
	line       = require'path_line'.hit,
	quad_curve = require'path_bezier2_hit',
	curve      = require'path_bezier3_hit',
}

local hit_functions_no_trans = glue.update({
	arc     = require'path_arc'.hit,
	arc_3p  = require'path_arc_3p'.hit,
}, hit_functions)

local function hit(x0, y0, path, mt_, draw)
	local md, mx, my, mt, mi
	local function write(i, s, ...)
		if draw then draw(s, ...) end
		local d, x, y, t = hit_functions[s](x0, y0, ...)
		if not md or d < md then
			md, mx, my, mt, mi = d, x, y, t, i
		end
	end
	decode(write, path, mt_, mt_ and hit_functions or hit_functions_no_trans)
	return md, mx, my, mi, mt
end

--command conversions ------------------------------------------------------------------

--given a rel. or abs. command name and its args in abs. form, encode the command as abs. or rel. according to the name.
local function to_rel(cpx, cpy, s, ...)
	return abs_cmd(-cpx, -cpy, s, ...)
end

local function replace_simplified(path, i)
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
	simplify = simplify,
	--measuring
	bounding_box = bounding_box,
	length = length,
	point = point,
	hit = hit,
	--editing
	split = split,
}

