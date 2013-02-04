--path2d simplification
local path2d_arc = require'path2d_arc'
local path2d_shapes = require'path2d_shapes'

local function opposite_point(x, y, cx, cy)
	return 2*cx-x, 2*cy-y
end

local function quad_curve_to_curve(write, x1, y1, x2, y2, x3, y3)
	write('curve',
		(x1 + 2 * x2) / 3,
		(y1 + 2 * y2) / 3,
		(x3 + 2 * x2) / 3,
		(y3 + 2 * y2) / 3,
		x3, y3)
end

local function shape_transform(decode, argc)
	return function(write, path, i)
		decode(write, unpack(path, i, i + argc - 1))
		return argc
	end
end

local shape_transforms = {
	ellipse     = shape_transform(path2d_shapes.ellipse_to_curves, 4),
	circle      = shape_transform(path2d_shapes.circle_to_curves, 3),
	rect        = shape_transform(path2d_shapes.rect_to_lines, 4),
	round_rect  = shape_transform(path2d_shapes.round_rect_to_lines_and_curves, 5),
	star        = shape_transform(path2d_shapes.star_to_lines, 7),
	rpoly       = shape_transform(path2d_shapes.regular_poly_to_lines, 4),
}

--emit only (move, line, curve, close) commands for any path, with cpx,cpy.
local function path_simplify(path, write)
	local spx, spy --starting point
	local cpx, cpy --current point
	local bx, by --last cubic bezier control point
	local qx, qy --last quad bezier control point
	local i = 1
	local s
	while i <= #path do
		if type(path[i]) == 'string' then --see if command changed
			s = path[i]; i = i + 1
		end
		if s == 'move' then
			cpx, cpy = path[i], path[i+1]
			spx, spy = cpx, cpy
			write('move', nil, nil, cpx, cpy)
			i = i + 2
		elseif s == 'rel_move' then
			assert(cpx, 'no current point')
			cpx, cpy = cpx + path[i], cpy + path[i+1]
			spx, spy = cpx, cpy
			write('move', nil, nil, cpx, cpy)
			i = i + 2
		elseif s == 'close' then
			assert(cpx, 'no current point')
			write('close', cpx, cpy, spx, spy)
			cpx, cpy = spx, spy
		elseif s == 'break' then --only useful for drawing a standalone arc
			assert(cpx, 'no current point')
			cpx, cpy, spx, spy = nil
		elseif s == 'line' then
			assert(cpx, 'no current point')
			write('line', cpx, cpy, path[i], path[i+1])
			cpx, cpy = path[i], path[i+1]
			i = i + 2
		elseif s == 'rel_line' then
			assert(cpx, 'no current point')
			write('line', cpx, cpy, cpx + path[i], cpy + path[i+1])
			cpx, cpy = cpx + path[i], cpy + path[i+1]
			i = i + 2
		elseif s == 'hline' then
			assert(cpx, 'no current point')
			write('line', cpx, cpy, path[i], cpy)
			cpx = path[i]
			i = i + 1
		elseif s == 'rel_hline' then
			assert(cpx, 'no current point')
			write('line', tcpx, tcpy, cpx + path[i], cpy)
			cpx = cpx + path[i]
			i = i + 1
		elseif s == 'vline' then
			assert(cpx, 'no current point')
			write('line', cpx, cpy, cpx, path[i])
			cpy = path[i]
			i = i + 1
		elseif s == 'rel_vline' then
			assert(cpx, 'no current point')
			write('line', cpx, cpy, cpx, cpy + path[i])
			cpy = cpy + path[i]
			i = i + 1
		elseif s == 'curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = path[i],   path[i+1]
			local x3, y3 = path[i+2], path[i+3]
			local x4, y4 = path[i+4], path[i+5]
			write('curve', x1, y1, x2, y2, x3, y3, x4, y4)
			bx, by = x3, y3
			cpx, cpy = x4, y4
			i = i + 6
		elseif s == 'rel_curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = cpx + path[i],   cpy + path[i+1]
			local x3, y3 = cpx + path[i+2], cpy + path[i+3]
			local x4, y4 = cpx + path[i+4], cpy + path[i+5]
			write('curve', x1, y1, x2, y2, x3, y3, x4, y4)
			bx, by = x3, y3
			cpx, cpy = x4, y4
			i = i + 6
		elseif s == 'smooth_curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = opposite_point(bx or cpx, by or cpy, cpx, cpy)
			local x3, y3 = path[i],   path[i+1]
			local x4, y4 = path[i+2], path[i+3]
			write('curve', x1, y1, x2, y2, x3, y3, x4, y4)
			bx, by = x3, y3
			cpx, cpy = x4, y4
			i = i + 4
		elseif s == 'rel_smooth_curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = opposite_point(bx or cpx, by or cpy, cpx, cpy)
			local x3, y3 = cpx + path[i],   cpy + path[i+1]
			local x4, y4 = cpx + path[i+2], cpy + path[i+3]
			write('curve', x1, y1, x2, y2, x3, y3, x4, y4)
			bx, by = x3, y3
			cpx, cpy = x4, y4
			i = i + 4
		elseif s == 'quad_curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = path[i],   path[i+1]
			local x3, y3 = path[i+2], path[i+3]
			quad_curve_to_curve(write, x1, y1, x2, y2, x3, y3)
			cpx, cpy = x3, y3
			qx, qy = x2, y2
			i = i + 4
		elseif s == 'rel_quad_curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = cpx + path[i],   cpy + path[i+1]
			local x3, y3 = cpx + path[i+2], cpy + path[i+3]
			quad_curve_to_curve(write, x1, y1, x2, y2, x3, y3)
			cpx, cpy = x3, y3
			qx, qy = x2, y2
			i = i + 4
		elseif s == 'smooth_quad_curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = opposite_point(qx or cpx, qy or cpy, cpx, cpy)
			local x3, y3 = path[i], path[i+1]
			quad_curve_to_curve(write, x1, y1, x2, y2, x3, y3)
			cpx, cpy = x3, y3
			qx, qy = x2, y2
			i = i + 2
		elseif s == 'rel_smooth_quad_curve' then
			assert(cpx, 'no current point')
			local x1, y1 = cpx, cpy
			local x2, y2 = opposite_point(qx or cpx, qy or cpy, cpx, cpy)
			local x3, y3 = cpx + path[i], cpy + path[i+1]
			quad_curve_to_curve(write, x1, y1, x2, y2, x3, y3)
			cpx, cpy = x3, y3
			qx, qy = x2, y2
			i = i + 2
		elseif s == 'elliptical_arc' then
			assert(cpx, 'no current point')
			local x1, y1, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2 = cpx, cpy, unpack(path, i, i + 7 - 1)
			path2d_arc.elliptical_arc_to_curves(write, x1, y1, rx, ry, math.rad(angle), large_arc_flag, sweep_flag, x2, y2)
			cpx, cpy = x2, y2
			i = i + 7
		elseif s == 'rel_elliptical_arc' then
			assert(cpx, 'no current point')
			local x1, y1, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2 = cpx, cpy, unpack(path, i, i + 7 - 1)
			x2, y2 = cpx + x2, cpx + y2
			path2d_arc.elliptical_arc_to_curves(write, x1, y1, rx, ry, math.rad(angle), large_arc_flag, sweep_flag, x2, y2)
			cpx, cpy = x2, y2
			i = i + 7
		elseif s == 'arc' then
			local cx, cy, r, a1, a2 = unpack(path, i, i + 5 - 1)
			cpx, cpy = path2d_arc.arc_to_curves_tied(write, cpx, cpy, cx, cy, r, r, math.rad(a1), math.rad(a2))
			i = i + 5
		elseif shape_transforms[s] then
			i = i + shape_transforms[s](write, path, i)
			cpx, cpy, spx, spy = nil
		else
			error('unknown path command %s', s)
		end

		if s ~= 'curve' and s ~= 'rel_curve' and s ~= 'smooth_curve' and s ~= 'rel_smooth_curve' then
			bx, by = nil
		end
		if s ~= 'quad_curve' and s ~= 'rel_quad_curve' and s ~= 'smooth_quad_curve' and s ~= 'rel_smooth_quad_curve' then
			qx, qy = nil
		end
	end
end

return path_simplify
