--2d path simplification: convert a complex path to a path containing only move, line, curve and close commands.
local arc = require'path_arc'.arc
local svgarc = require'path_svgarc'
local shapes = require'path_shapes'

local type, unpack, assert, radians = type, unpack, assert, math.rad

local function opposite_point(x, y, cx, cy)
	return 2*cx-x, 2*cy-y
end

local function quad_control_points(x1, y1, x2, y2, x3, y3)
	return
		(x1 + 2 * x2) / 3, --c1x
		(y1 + 2 * y2) / 3, --c1y
		(x3 + 2 * x2) / 3, --c2x
		(y3 + 2 * y2) / 3  --c2y
end

local function shape_writer(writer, argc)
	return function(write, path, i)
		writer(write, unpack(path, i, i + argc - 1))
		return argc
	end
end

local shape_writers = {
	ellipse     = shape_writer(shapes.ellipse, 4),
	circle      = shape_writer(shapes.circle, 3),
	rect        = shape_writer(shapes.rect, 4),
	round_rect  = shape_writer(shapes.round_rect, 5),
	star        = shape_writer(shapes.star, 7),
	rpoly       = shape_writer(shapes.regular_poly, 4),
}

local function path_simplify(write, path, except)
	assert(type(path[1]) == 'string', 'path must start with a command')
	local spx, spy --starting point, for closing subpaths
	local cpx, cpy --current point
	local bx, by --last cubic bezier control point, for continuing smooth beziers
	local qx, qy --last quad bezier control point, for continuing smooth quad beziers
	local i = 1
	local s
	while i <= #path do
		if type(path[i]) == 'string' then --see if command changed
			s = path[i]; i = i + 1
		end
		local is_curve = false
		if except and except[s] then
			write(s, unpack(i, i + argc[s] - 1))
		elseif s == 'move' or s == 'rel_move' then
			local x, y = path[i], path[i+1]; i = i + 2
			if s == 'rel_move' then
				assert(cpx, 'no current point')
				x, y = cpx + x, cpy + y
			end
			write('move', x, y)
			cpx, cpy = x, y
			spx, spy = x, y
		elseif s == 'close' then
			assert(cpx, 'no current point')
			write('close')
			write('move', spx, spy)
			cpx, cpy = spx, spy
		elseif s == 'break' then
			write('move', cpx, cpy)
			spx, spy = cpx, cpy
		elseif s == 'line' or s == 'rel_line' then
			assert(cpx, 'no current point')
			local x, y = path[i], path[i+1]; i = i + 2
			if s == 'rel_line' then x, y = cpx + x, cpy + y end
			write('line', x, y)
			cpx, cpy = x, y
		elseif s == 'hline' or s == 'rel_hline' then
			assert(cpx, 'no current point')
			local x = path[i]; i = i + 1
			if s == 'rel_hline' then x = cpx + x end
			write('line', x, cpy)
			cpx = x
		elseif s == 'vline' or s == 'rel_vline' then
			assert(cpx, 'no current point')
			local y = path[i]; i = i + 1
			if s == 'rel_vline' then y = cpy + y end
			write('line', cpx, y)
			cpy = y
		elseif s:match'curve$' then
			assert(cpx, 'no current point')
			local x2, y2, x3, y3, x4, y4
			local xc, yc
			local rel, quad, smooth = s:match'^rel_', s:match'quad_', s:match'smooth_'
			if quad then
				if smooth then
					xc, yc = opposite_point(qx or cpx, qy or cpy, cpx, cpy)
					x4, y4 = path[i], path[i+1]
					i = i + 2
					if rel then x4, y4 = cpx + x4, cpy + y4 end
				else
					xc, yc, x4, y4 = path[i], path[i+1], path[i+2], path[i+3]
					i = i + 4
					if rel then xc, yc, x4, y4 = cpx + xc, cpy + yc, cpx + x4, cpy + y4 end
				end
				x2, y2, x3, y3 = quad_control_points(cpx, cpy, xc, yc, x4, y4)
			else
				if smooth then
					x2, y2 = opposite_point(bx or cpx, by or cpy, cpx, cpy)
					x3, y3, x4, y4 = path[i], path[i+1], path[i+2], path[i+3]
					i = i + 4
					if rel then x3, y3, x4, y4 = cpx + x3, cpy + y3, cpx + x4, cpy + y4 end
				else
					x2, y2, x3, y3, x4, y4 = path[i], path[i+1], path[i+2], path[i+3], path[i+4], path[i+5]
					i = i + 6
					if rel then x2, y2, x3, y3, x4, y4 = cpx + x2, cpy + y2, cpx + x3, cpy + y3, cpx + x4, cpy + y4 end
				end
			end
			write('curve', x2, y2, x3, y3, x4, y4)
			qx, qy = xc, yc
			bx, by = x3, y3
			cpx, cpy = x4, y4
			is_curve = true
		elseif s == 'arc' or s == 'rel_arc' then
			local cx, cy, r, start_angle, sweep_angle = path[i], path[i+1], path[i+2], path[i+3], path[i+4]
			i = i + 5
			if s == 'rel_arc' then
				assert(cpx, 'no current point')
				cx, cy = cpx + cx, cpy + cy
			end
			cpx, cpy, bx, by, qx, qy = arc(write, cx, cy, r, r, radians(start_angle), radians(sweep_angle), cpx ~= nil)
			is_curve = true
		elseif s == 'elliptical_arc' or s == 'rel_elliptical_arc' then
			assert(cpx, 'no current point')
			local rx, ry, angle, large_arc_flag, sweep_flag, x2, y2 = unpack(path, i, i + 7 - 1)
			i = i + 7
			if s == 'rel_elliptical_arc' then x2, y2 = cpx + x2, cpy + y2 end
			cpx, cpy, bx, by, qx, qy = svgarc(write, cpx, cpy, rx, ry, radians(angle), large_arc_flag, sweep_flag, x2, y2)
			is_curve = true
		elseif s == 'text' then
			assert(cpx, 'no current point')
			write(s, path[i], path[i+1])
			i = i + 2
		elseif shape_writers[s] then
			i = i + shape_writers[s](write, path, i)
			cpx, cpy, spx, spy = nil --shapes must be closed
		else
			error(string.format('unknown path command %s', s))
		end

		if not is_curve then bx, by, qx, qy = nil end --non-curves break smoothness
	end
end

if not ... then require'sg_cairo_test' end

return path_simplify
