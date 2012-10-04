--2d path vertex pipeline
--[[
The vertex pipeline:
	path_t -> simplify -> elasticize -> transform -> flatten -> gen-stroke -> clip -> write()

A 2d path is a series of path commands and their arguments.
A path enters the pipeline as a flat list of {command1, arg1, ..., command2, arg1, ...}.
In transit, it is a series of invocations of a function write(command, arg1, ...) supplied by the consumer.
It exists the pipeline as a series of invocations of a function write(???) to be used by the rasterizer.

- inline affine transforms to be applied before flattening; they do not affect the current point
	- they may or may not affect stroke shape (think about how to express this)

- stroke generator
	- polygon offsetting (use clipper?)
	- line join types: miter, round, bevel
	- line cap types: butt, round, square, marker (another path?)
	- dash generator: dash array + offset; anything else?

- non-linear transforms
	- path-elasticize: split lines into beziers of fixed length
		- see what's faster: flattening a lot of tiny beziers or
		transforming a lot of polygon points (only if it looks good)?
	- transform functions: perspective, bilinear, envelope, twist, lens, etc.
	- other transformations from cartography? cylinder projection etc.

- bounding box
- hit testing
- polygon clipping

]]

local glue = require'glue'
local affine = require'trans_affine2d'
local path2d_arc = require'path2d_arc'
local path2d_bezier = require'path2d_bezier'
local path2d_shapes = require'path2d_shapes'
local path2d_glyph = require'path2d_glyph'
local path2d_stroke = require'path2d_stroke'

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

local function shape_protocol(decode, argc)
	return function(write, path, i)
		decode(write, unpack(path, i, i + argc - 1))
		return argc
	end
end

local shapes = {
	ellipse     = shape_protocol(path2d_shapes.ellipse_to_curves, 4),
	circle      = shape_protocol(path2d_shapes.circle_to_curves, 3),
	rect        = shape_protocol(path2d_shapes.rect_to_lines, 4),
	round_rect  = shape_protocol(path2d_shapes.round_rect_to_lines_and_curves, 5),
	star        = shape_protocol(path2d_shapes.star_to_lines, 7),
	rpoly       = shape_protocol(path2d_shapes.regular_poly_to_lines, 4),
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
		elseif shapes[s] then
			i = i + shapes[s](write, path, i)
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

local bezier_to_lines = path2d_bezier.bezier_to_lines_function()

--emit only (move, curve, close) commands for any path, with cpx,cpy.
--mt can be any transformation object, linear or non-linear.
local function path_elasticize(path, write, mt)
	path_simplify(path,
		function(s, x1, y1, x2, y2, x3, y3, x4, y4)
			if s == 'curve' then
				if mt then
					x1, y1 = mt:transform(x1, y1)
					x2, y2 = mt:transform(x2, y2)
					x3, y3 = mt:transform(x3, y3)
					x4, y4 = mt:transform(x4, y4)
				end
				bezier_to_lines(write, x1, y1, x2, y2, x3, y3, x4, y4)
			elseif s == 'move' or s == 'line' then
				if mt then
					x2, y2 = mt:transform(x2, y2)
				end
				write(s, x2, y2)
			elseif s == 'close' then
				write(s)
			end
		end)
end

--emit only (move, line, close) commands for any path, without cpx,cpy.
--mt can only be an affine transformation object.
local function path_flatten(path, write, mt)
	path_simplify(path,
		function(s, x1, y1, x2, y2, x3, y3, x4, y4)
			if s == 'curve' then
				if mt then
					x1, y1 = mt:transform(x1, y1)
					x2, y2 = mt:transform(x2, y2)
					x3, y3 = mt:transform(x3, y3)
					x4, y4 = mt:transform(x4, y4)
				end
				bezier_to_lines(write, x1, y1, x2, y2, x3, y3, x4, y4)
			elseif s == 'move' or s == 'line' then
				if mt then
					x2, y2 = mt:transform(x2, y2)
				end
				write(s, x2, y2)
			elseif s == 'close' then
				write(s)
			end
		end)
end

local function flat_path_writer()
	local path = {}
	local function write(s,...)
		glue.append(path,s,...)
	end
	return path, write
end

local function path_flatten_to_path(path, mt)
	local dpath, write = flat_path_writer()
	path_flatten(path, write, mt)
	return dpath
end

local function cairo_draw_flat_path(cr, path)
	local function write(s, x1, y1)
		if s == 'move' then
			cr:move_to(x1, y1)
		elseif s == 'line' then
			cr:line_to(x1, y1)
		elseif s == 'close' then
			cr:close_path()
		end
	end
	path_flatten(path, write)
end


--compute the control points between x1,y1 and x2,y2 where x0,y0 is the previous vertex and x3,y3 the next one.
--smooth_value is should be in range [0...1].
--taken verbatim from: http://www.antigrain.com/research/bezier_interpolation/
local function smooth_segment(smooth_value, x0, y0, x1, y1, x2, y2, x3, y3)
	local xc1 = (x0 + x1) / 2
	local yc1 = (y0 + y1) / 2
	local xc2 = (x1 + x2) / 2
	local yc2 = (y1 + y2) / 2
	local xc3 = (x2 + x3) / 2
	local yc3 = (y2 + y3) / 2

	local len1 = math.sqrt((x1-x0) * (x1-x0) + (y1-y0) * (y1-y0))
	local len2 = math.sqrt((x2-x1) * (x2-x1) + (y2-y1) * (y2-y1))
	local len3 = math.sqrt((x3-x2) * (x3-x2) + (y3-y2) * (y3-y2))

	local k1 = len1 / (len1 + len2)
	local k2 = len2 / (len2 + len3)

	local xm1 = xc1 + (xc2 - xc1) * k1
	local ym1 = yc1 + (yc2 - yc1) * k1

	local xm2 = xc2 + (xc3 - xc2) * k2
	local ym2 = yc2 + (yc3 - yc2) * k2

	ctrl1_x = xm1 + (xc2 - xm1) * smooth_value + x1 - xm1
	ctrl1_y = ym1 + (yc2 - ym1) * smooth_value + y1 - ym1

	ctrl2_x = xm2 + (xc2 - xm2) * smooth_value + x2 - xm2
	ctrl2_y = ym2 + (yc2 - ym2) * smooth_value + y2 - ym2

	return ctrl1_x, ctrl1_y, ctrl2_x, ctrl2_y
end

local function polygon_to_curve(t, smooth_value) --smooth a polygon to a path of bezier curves
	for i=1,8 do t[#t+1] = t[i] end --sorry for updating the input (need vararg.unpack_roll(t,i,j) function)
	local dt = {'move', t[3], t[4], 'curve'}
	for i=1,#t-8,2 do
		local cx1, cy1, cx2, cy2 = smooth_segment(smooth_value, unpack(t, i, i + 7))
		dt[#dt+1] = cx1
		dt[#dt+1] = cy1
		dt[#dt+1] = cx2
		dt[#dt+1] = cy2
		dt[#dt+1] = t[i+4]
		dt[#dt+1] = t[i+5]
	end
	for i=1,8 do t[#t] = nil end
	return dt
end

return {
	path_simplify = path_simplify,
	path_elasticize = path_elasticize,
	path_flatten = path_flatten,
	path_flatten_to_path = path_flatten_to_path,
	cairo_draw_flat_path = cairo_draw_flat_path,
	polygon_to_curve = polygon_to_curve,
}
