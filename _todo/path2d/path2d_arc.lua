--2d arc and elliptical arc to bezier conversion
--from agg/src/agg_bezier_arc.cpp: arc_to_bezier()

local glue = require'glue'
local affine = require'trans_affine2d'

local function arc_segment_to_curve(write, cx, cy, rx, ry, start_angle, sweep_angle)
	local x0 = math.cos(sweep_angle / 2)
	local y0 = math.sin(sweep_angle / 2)
	local tx = (1 - x0) * 4 / 3
	local ty = y0 - tx * x0 / y0

	local px0 =  x0
	local py0 = -y0
	local px1 =  x0 + tx
	local py1 = -ty
	local px2 =  x0 + tx
	local py2 =  ty
	local px3 =  x0
	local py3 =  y0

	local sn = math.sin(start_angle + sweep_angle / 2)
	local cs = math.cos(start_angle + sweep_angle / 2)

	write('curve',
		cx + rx * (px0 * cs - py0 * sn),
		cy + ry * (px0 * sn + py0 * cs),

		cx + rx * (px1 * cs - py1 * sn),
		cy + ry * (px1 * sn + py1 * cs),

		cx + rx * (px2 * cs - py2 * sn),
		cy + ry * (px2 * sn + py2 * cs),

		cx + rx * (px3 * cs - py3 * sn),
		cy + ry * (px3 * sn + py3 * cs))
end

local bezier_arc_angle_epsilon = 0.01 --limit to prevent adding degenerate curves

local function arc_end_points(cx, cy, rx, ry, a1, a2)
	--TODO
end

--from agg/src/agg_bezier_arc.cpp: bezier_arc::init()
local function arc_to_curves(write, cx, cy, rx, ry, start_angle, sweep_angle)
	start_angle = math.fmod(start_angle, 2 * math.pi)
	if sweep_angle >=  2 * math.pi then sweep_angle =  2 * math.pi end
	if sweep_angle <= -2 * math.pi then sweep_angle = -2 * math.pi end

	if math.abs(sweep_angle) < 1e-10 then
		write('line',
			cx + rx * math.cos(start_angle),
			cy + ry * math.sin(start_angle),
			cx + rx * math.cos(start_angle + sweep_angle),
			cy + ry * math.sin(start_angle + sweep_angle))
		return
	end

	local total_sweep = 0
	local local_sweep = 0
	local prev_sweep
	local done
	for i=1,4 do
		if sweep_angle < 0 then
			prev_sweep  = total_sweep
			local_sweep = -math.pi * 0.5
			total_sweep = total_sweep - math.pi * 0.5
			if total_sweep <= sweep_angle + bezier_arc_angle_epsilon then
				local_sweep = sweep_angle - prev_sweep
				done = true
			end
		else
			prev_sweep  = total_sweep
			local_sweep = math.pi * 0.5
			total_sweep = total_sweep + math.pi * 0.5
			if total_sweep >= sweep_angle - bezier_arc_angle_epsilon then
				local_sweep = sweep_angle - prev_sweep
				done = true
			end
		end
		arc_segment_to_curve(write, cx, cy, rx, ry, start_angle, local_sweep)
		start_angle = start_angle + local_sweep
		if done then break end
	end
end

--from agg/src/agg_bezier_arc.cpp: bezier_arc_svg::init()
local function elliptical_arc_to_curves(write, x0, y0, rx, ry, angle, large_arc_flag, sweep_flag, x2, y2)
	if rx < 0 then rx = -rx end
	if ry < 0 then ry = -rx end

	-- Calculate the middle point between the current and the final points
	local dx2 = (x0 - x2) / 2
	local dy2 = (y0 - y2) / 2

	local cos_a = math.cos(angle)
	local sin_a = math.sin(angle)

	-- Calculate (x1, y1)
	local x1 =  cos_a * dx2 + sin_a * dy2
	local y1 = -sin_a * dx2 + cos_a * dy2

	-- Ensure radii are large enough
	local prx = rx * rx
	local pry = ry * ry
	local px1 = x1 * x1
	local py1 = y1 * y1

	-- Check that radii are large enough
	local radii_check = px1/prx + py1/pry
	if radii_check > 1 then
		rx = math.sqrt(radii_check) * rx
		ry = math.sqrt(radii_check) * ry
		prx = rx * rx
		pry = ry * ry
		if radii_check > 10 then print'invalid radii' end
	end

	-- Calculate (cx1, cy1)
	local sign = large_arc_flag == sweep_flag and -1 or 1
	local sq   = (prx*pry - prx*py1 - pry*px1) / (prx*py1 + pry*px1)
	local coef = sign * math.sqrt(sq < 0 and 0 or sq)
	local cx1  = coef *  ((rx * y1) / ry)
	local cy1  = coef * -((ry * x1) / rx)

	-- Calculate (cx, cy) from (cx1, cy1)
	local sx2 = (x0 + x2) / 2
	local sy2 = (y0 + y2) / 2
	local cx = sx2 + (cos_a * cx1 - sin_a * cy1)
	local cy = sy2 + (sin_a * cx1 + cos_a * cy1)

	-- Calculate the start_angle (angle1) and the sweep_angle (dangle)
	local ux =  (x1 - cx1) / rx
	local uy =  (y1 - cy1) / ry
	local vx = (-x1 - cx1) / rx
	local vy = (-y1 - cy1) / ry
	local p, n

	-- Calculate the angle start
	n = math.sqrt(ux*ux + uy*uy)
	p = ux -- (1 * ux) + (0 * uy)
	sign = uy < 0 and -1 or 1
	local v = p / n
	if v < -1 then v = -1 end
	if v >  1 then v =  1 end
	local start_angle = sign * math.acos(v)

	-- Calculate the sweep angle
	n = math.sqrt((ux*ux + uy*uy) * (vx*vx + vy*vy))
	p = ux * vx + uy * vy
	sign = ux * vy - uy * vx < 0 and -1 or 1
	v = p / n
	if v < -1 then v = -1 end
	if v >  1 then v =  1 end
	local sweep_angle = sign * math.acos(v)

	if sweep_flag == 0 and sweep_angle > 0 then
		sweep_angle = sweep_angle - math.pi * 2
	elseif sweep_flag == 1 and sweep_angle < 0 then
		sweep_angle = sweep_angle + math.pi * 2
	end

	-- We can now build and transform the resulting arc
	local path={}
	local mt = affine:new():translate(cx, cy):rotate(angle)
	local function write_curves(s,x1,y1,x2,y2,x3,y3,x4,y4)
		x1,y1 = mt:transform(x1, y1)
		x2,y2 = mt:transform(x2, y2)
		if s == 'line' then
			glue.append(path,'line',x1,y1,x2,y2)
		else
			x3,y3 = mt:transform(x3, y3)
			x4,y4 = mt:transform(x4, y4)
			glue.append(path,'curve',x1,y1,x2,y2,x3,y3,x4,y4)
		end
	end
	arc_to_curves(write_curves, 0, 0, rx, ry, start_angle, sweep_angle)
	--adjust first and last points of the path
	--TODO: find a way that doesn't involve saving and replaying the path cuz this is ridiculous
	path[2] = x0
	path[3] = y0
	path[#path-1] = x2
	path[#path] = y2
	local i=1
	while i <= #path do
		if path[i] == 'line' then
			write('line', unpack(path, i + 1, i + 4))
			i = i + 5
		elseif path[i] == 'curve' then
			write('curve', unpack(path, i + 1, i + 8))
			i = i + 9
		end
	end
end

--draws an arc and also a line from (cpx,cpy) to the start point of the arc. returns the end point of the arc.
local function arc_to_curves_tied(cpx, cpy, cx, cy, rx, ry, a1, a2)
	local x1, y1, x2, y2 = arc_end_points(cx, cy, r, r, a1, a2)
	if cpx then
		write('line', cpx, cpy, x1, y1)
	else
		write('move', nil, nil, x1, y1)
	end
	arc_to_curves(cx, cy, rx, ry, a1, a2)
	return x2, y2
end

return {
	elliptical_arc_to_curves = elliptical_arc_to_curves,
	arc_end_points = arc_end_points,
	arc_to_curves = arc_to_curves,
	arc_to_curves_tied = arc_to_curves_tied,
}

