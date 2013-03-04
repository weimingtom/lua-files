local line_hit = require'path_line'.hit
local point_distance2 = require'path_point'.distance2

--TODO: rename the module to something more generic.

--create a curve hit function based on a supplied interpolation function.
--the hit function returns shortest distance-squared from point (x0, y0) to curve,
--plus the touch point, and the time in the curve where the touch point splits the curve.
local function interpolation_based_hit_function(interpolate)
	return function(x0, y0, x1, y1, ...)
		local cpx, cpy = x1, y1
		local mind = 1/0
		local minx, miny, mint, mint1, mint2
		local function write(_, x2, y2, t1, t2)
			local d, x, y, t = line_hit(x0, y0, cpx, cpy, x2, y2)
			if not d then
				d, x, y, t = point_distance2(x0, y0, x2, y2), x2, y2, 0
			end
			if d < mind then
				mind, minx, miny, mint, mint1, mint2 = d, x, y, t, t1, t2
			end
			cpx, cpy = x2, y2
		end
		interpolate(write, x1, y1, ...)
		if mint then
			mint = mint1 + mint * (mint2 - mint1)
			return mind, minx, miny, mint
		end
	end
end

if not ... then require'path_hit_demo' end

return {
	hit_function = interpolation_based_hit_function,
}

