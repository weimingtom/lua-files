--2d path API including iterating, decoding, updating, etc.

--iterating commands

local argc = {
	--control commands
	move = 2,
	close = 0,
	['break'] = 0,
	--lines and curves
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
	--composite tied
	arc = 5,
	arc_3p = 4,
	svgarc = 7,
	--composite closed
	rect = 4,
	round_rect = 5,
	ellipse = 4,
	circle = 3,
	circle_3p = 6,
	star = 6,
	star_2p = 7,
	rpoly = 4,
	superformula = 10,
	text = 4,
	--transformations
	scale = 1,
	scale_x = 1,
	scale_y = 2,
	skew_x = 1,
	skew_y = 1,
	rotate = 1,
}

--all commands with arguments have relative counterparts with the same number of arguments.
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

--insert n elements at i, shifting elemens on the right of i (i inclusive) to the right.
local function table_insert(t, i, n)
	if n == 1 then --shift 1
		table.insert(t, i)
		return
	end
	for p = #t,i,-1 do --shift n
		t[p+n] = t[p]
	end
end

--remove n elements at i, shifting elements on the right of i (i inclusive) to the left.
local function table_remove(t, i, n)
	n = math.min(n, #t-i+1)
	if n == 1 then --shift 1
		table.remove(t, i)
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
	return s:match'^rel_'
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

--given current point and an unpacked command and its args, return the command in abs. form.
local function abs_cmd(cpx, cpy, s, ...)
	if is_abs(s) then return ... end
	s = abs_name(s)
	elseif s == 'move' or s == 'line' then
		local s, x2, y2 = ...
		return s, cpx + x2, cpy + y2
	elseif s == 'hline' tehn
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
	elseif s == 'arc'
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

--given current state and current abs. cmd, return the state of the next path command.
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
		_, bx, by, cpx, cpy
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
		local cx, cy, r, start_angle, sweep_angle = ...
		_, _, cpx, cpy = arc_endpoints(cx, cy, r, radians(start_angle), radians(sweep_angle))
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

local reflect_point = require'path_point'.reflect_point
local reflect_point_distance = require'path_point'.reflect_point_distance
local bezier2_3point_control_point = require'path_bezier2'._3point_control_point

local function is_line(s) return s == 'line' or s == 'hline' or s == 'vline' end
local function is_bezier2(s) return s:match'quad_curve' end
local function is_bezier3(s) return s == 'curve' or s == 'symm_curve' or s == 'smooth_curve' end
local function is_arc(s) return s == 'arc' or s == 'svgarc' or s == 'arc_3p' end
local shapes = require'path_shapes'
local function is_shape(s) return shapes[s] end

--given current state and an abs. drawing command, return the corresponding context-free drwaing command.
local function decode(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	if s == 'line' then
		return 'line', cpx, cpy, ...
	elseif s == 'hline' then
		return 'line', cpx, cpy, ..., cpy
	elseif s == 'vline' then
		return 'line', cpx, cpy, cpx, ...
	elseif s == 'curve' then
		return 'bezier3', cpx, cpy, ...
	elseif s == 'symm_curve' then
		local x2, y2 = reflect_point(bx, by, cpx, cpy)
		return 'bezier3', cpx, cpy, x2, y2, ...
	elseif s == 'smooth_curve' then
		local x2, y2 = reflect_point_distance(bx or qx, by or qy, cpx, cpy, (...))
		return 'bezier3', cpx, cpy, x2, y2, select(2, ...)
	elseif s == 'quad_curve' then
		return 'bezier2', cpx, cpy, ...
	elseif s == 'quad_curve_3p' then
		local x2, y2, x3, y3 = ...
		local x2, y2 = bezier2_3point_control_point(cpx, cpy, x2, y2, x3, y3)
		return 'bezier2', cpx, cpy, x2, y2, x3, y3
	elseif s == 'symm_quad_curve' then
		local x2, y2 = reflect_point(qx, qy, cpx, cpy)
		return 'bezier2', cpx, cpy, x2, y2, ...
	elseif s == 'smooth_quad_curve' then
		local x2, y2 = reflect_point_distance(bx or qx, by or qy, cpx, cpy, (...))
		return 'bezier2', cpx, cpy, x2, y2, select(2, ...)
	end
end

local function decode_shape(write, cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	local draw_shape = shapes[s]
	local function write1(s, ...)
		write(decode(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...))
		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	end
	draw_shape(write1, ...)
	return cpx, cpy, spx, spy, bx, by, qx, qy
end

--linearly transform a decoded primitive shape.
local function transform(mt, s, ...)
	local x1, y1 = ...
	x1, y1 = mt:transform_point(x1, y1)
	if s == 'line' then
		local x2, y2 = ...
		x2, y2 = mt:transform_point(x2, y2)
		return s, x1, y1, x2, y2
	elseif s == 'bezier2' then
		local x2, y2, x3, y3 = ...
		x2, y2 = mt:transform_point(x2, y2)
		x3, y3 = mt:transform_point(x3, y3)
		return s, x1, y1, x2, y2, x3, y3
	elseif s == 'bezier3' then
		local x2, y2, x3, y3, x4, y4 = ...
		x2, y2 = mt:transform_point(x2, y2)
		x3, y3 = mt:transform_point(x3, y3)
		x4, y4 = mt:transform_point(x4, y4)
		return s, x1, y1, x2, y2, x3, y3, x4, y4
	end
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

--measuring

local shapes = require'shapes'

local function decode(write, path)
	local cpx, cpy, spx, spy, bx, by, qx, qy
	local function write_command(s, ...)
		write(decode_command(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...))
		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(cpx, cpy, spx, spy, bx, by, qx, qy, s, ...)
	end
	for i,s in commands(path) do
		if shapes[s] then
			shapes[s](write_command, abs_cmd(cpx, cpy, cmd(path, i)))
		else
			write(decode_command(cpx, cpy, spx, spy, bx, by, qx, qy, abs_cmd(cpx, cpy, cmd(path, i))))
		end
		cpx, cpy, spx, spy, bx, by, qx, qy = next_state(path, i, cpx, cpy, spx, spy, bx, by, qx, qy)
	end
end


local bbox_functions = {
	line = require'path_line'.bounding_box,
	bezier2 = require'path_bezier2'.bounding_box,
	bezier3 = require'path_bezier3'.bounding_box,
}

local function bounding_box(path, mt)
	local x1, y1, x2, y2
	local function measure(s, ...)
		local x, y, w, h
		if bbox_functions[s] then
			x, y, w, h = bbox_functions[s](...)
		else
			simplify(write, s, ...)
		end
		x1 = min(x1 or 1/0, x)
		y1 = min(y1 or 1/0, y)
		x2 = max(x2 or -1/0, x+w)
		y2 = max(y2 or -1/0, y+h)
	end
	local write = measure
	if mt then
		function write(s, ...)
			measure(transform(mt, s, ...))
		end
	end
	decode(write, path)
	return x1, y1, x2-x1, y2-y1
end

local length_functions = {
	line = require'path_line'.length,
	bezier2 = require'path_bezier2'.length,
	bezier3 = require'path_bezier3'.length,
}

local function length(path, mt)
	local length = 0
	local function write(s, ...)
		if length_functions[s] then
			length = length + length_functions[s](...)
		else
			simplify(write, s, ...)
		end
	end
	decode(write, path)
	return length
end

local function local_time(t, path)
	--
	return i, path
end

local point_functions = {
	line = require'path_line'.point,
	bezier2 = require'path_bezier2'.point,
	bezier3 = require'path_bezier3'.point,
}

local function point(t, path)
	local x, y
	local function write(s, ...)
		if point_functions[s] then
			x, y = point_functions[s](...)
		else
			simplify(write, s, ...)
		end
	end
	decode(write, path)
end

local hit_functions = {
	line = require'path_line'.hit,
	bezier2 = require'path_bezier2'.hit,
	bezier3 = require'path_bezier3'.hit,
}

local function hit(path, mt)
	return d, x, y, t, i, local_t
	local function write(s, ...)
		if hit_functions[s] then
			d, x, y, t = hit_functions[s](...)
		else
			simplify(write, s, ...)
		end
	end
	decode(write, path)
end

--editing

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

--if not ... then require'path_demo' end

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
	--measuring
	bounding_box = bounding_box,
	length = length,
	point = point,
	hit = hit,
	--editing
	split = split,
}

