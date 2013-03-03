--2d quadratic bezier adaptive interpolation from http://www.antigrain.com/research/adaptive_bezier/index.html
--apart from the line segments, it also writes the t1,t2 time interval corresponding to the end points of each segment.

local pi, atan2, abs = math.pi, math.atan2, math.abs

local curve_collinearity_epsilon    = 1e-30
local curve_angle_tolerance_epsilon = 0.01
local curve_recursion_limit         = 32

local recursive_bezier --forward decl.

--tip: adjust m_approximation_scale to the scale of the world-to-screen transformation.
--tip: enable m_angle_tolerance when stroke width * scale > 1.
local function interpolate(write, x1, y1, x2, y2, x3, y3, m_approximation_scale, m_angle_tolerance)
	m_approximation_scale = m_approximation_scale or 1
	m_angle_tolerance = m_angle_tolerance or 0
	local m_distance_tolerance2 = (1 / (2 * m_approximation_scale))^2

	local t1, t2 = recursive_bezier(write, x1, y1, x2, y2, x3, y3, 0, 0, 1,
												m_distance_tolerance2, m_angle_tolerance)
	write('line', x3, y3, t1, t2)
end

function recursive_bezier(write, x1, y1, x2, y2, x3, y3, level, t1, t2, m_distance_tolerance2, m_angle_tolerance)
	if level > curve_recursion_limit then return t1, t2 end

	-- Calculate all the mid-points of the line segments
	local x12   = (x1 + x2) * 0.5
	local y12   = (y1 + y2) * 0.5
	local x23   = (x2 + x3) * 0.5
	local y23   = (y2 + y3) * 0.5
	local x123  = (x12 + x23) * 0.5
	local y123  = (y12 + y23) * 0.5

	local dx = x3-x1
	local dy = y3-y1
	local d = abs((x2 - x3) * dy - (y2 - y3) * dx)

	if d > curve_collinearity_epsilon then
		-- Regular care
		if d^2 <= m_distance_tolerance2 * (dx^2 + dy^2) then
			-- If the curvature doesn't exceed the distance_tolerance value we tend to finish subdivisions.
			if m_angle_tolerance < curve_angle_tolerance_epsilon then
				write('line', x123, y123, t1, t2)
				return t1, t2
			end
			-- Angle & Cusp Condition
			local da = abs(atan2(y3 - y2, x3 - x2) - atan2(y2 - y1, x2 - x1))
			if da >= pi then
				da = 2*pi - da
			end
			if da < m_angle_tolerance then
				write('line', x123, y123, t1, t2)
				return t1, t2
			end
		end
	else
		-- Collinear case
		dx = x123 - (x1 + x3) / 2
		dy = y123 - (y1 + y3) / 2
		if dx^2 + dy^2 <= m_distance_tolerance2 then
			write('line', x123, y123, t1, t2)
			return t1, t2
		end
	end

	-- Continue subdivision
	local t12 = t1 + (t2 - t1) * 0.5
	recursive_bezier(write, x1, y1, x12, y12, x123, y123, level + 1, t1, t12, m_distance_tolerance2, m_angle_tolerance)
	recursive_bezier(write, x123, y123, x23, y23, x3, y3, level + 1, t12, t2, m_distance_tolerance2, m_angle_tolerance)
	return t1, t2
end

--if not ... then require'path_bezier3_ai_demo' end
if not ... then require'path_hit_demo' end

return interpolate

