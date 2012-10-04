--2d bezier adaptive interpolation
--transcribed from: http://www.antigrain.com/research/adaptive_bezier/index.html

local curve_collinearity_epsilon    = 1e-30
local curve_angle_tolerance_epsilon = 0.01
local curve_recursion_limit         = 32

local function bezier_to_lines_function(m_approximation_scale, m_angle_tolerance, m_cusp_limit)

	m_approximation_scale = m_approximation_scale or 1
	m_angle_tolerance = m_angle_tolerance or 0
	m_cusp_limit = m_cusp_limit and m_cusp_limit ~= 0 and math.pi - math.rad(m_cusp_limit) or 0

	local m_distance_tolerance_square = 0.5 / m_approximation_scale
	local m_distance_tolerance_square = m_distance_tolerance_square * m_distance_tolerance_square

	function recursive_bezier(write, x1, y1, x2, y2, x3, y3, x4, y4, level)
		if level > curve_recursion_limit then return end

		--Calculate all the mid-points of the line segments
		local x12   = (x1 + x2) / 2
		local y12   = (y1 + y2) / 2
		local x23   = (x2 + x3) / 2
		local y23   = (y2 + y3) / 2
		local x34   = (x3 + x4) / 2
		local y34   = (y3 + y4) / 2
		local x123  = (x12 + x23) / 2
		local y123  = (y12 + y23) / 2
		local x234  = (x23 + x34) / 2
		local y234  = (y23 + y34) / 2
		local x1234 = (x123 + x234) / 2
		local y1234 = (y123 + y234) / 2

		--Try to approximate the full cubic curve by a single straight line
		local dx = x4-x1
		local dy = y4-y1

		local d2 = math.abs((x2 - x4) * dy - (y2 - y4) * dx)
		local d3 = math.abs((x3 - x4) * dy - (y3 - y4) * dx)
		local da1, da2, k

		local case = (d2 > curve_collinearity_epsilon and 2 or 0) +
						 (d3 > curve_collinearity_epsilon and 1 or 0)

		if case == 0 then
			--All collinear OR p1==p4
			k = dx*dx + dy*dy
			if k == 0 then
				d2 = calc_sq_distance(x1, y1, x2, y2)
				d3 = calc_sq_distance(x4, y4, x3, y3)
			else
				k   = 1 / k
				da1 = x2 - x1
				da2 = y2 - y1
				d2  = k * (da1*dx + da2*dy)
				da1 = x3 - x1
				da2 = y3 - y1
				d3  = k * (da1*dx + da2*dy)

				if d2 > 0 and d2 < 1 and d3 > 0 and d3 < 1 then
					--Simple collinear case, 1---2---3---4
					--We can leave just two endpoints
					return
				end

				if d2 <= 0 then
					d2 = calc_sq_distance(x2, y2, x1, y1)
				elseif d2 >= 1 then
					d2 = calc_sq_distance(x2, y2, x4, y4)
				else
					d2 = calc_sq_distance(x2, y2, x1 + d2*dx, y1 + d2*dy)
				end

				if d3 <= 0 then
					d3 = calc_sq_distance(x3, y3, x1, y1)
				elseif d3 >= 1 then
					d3 = calc_sq_distance(x3, y3, x4, y4)
				else
					d3 = calc_sq_distance(x3, y3, x1 + d3*dx, y1 + d3*dy)
				end
			end

			if d2 > d3  then
				if d2 < m_distance_tolerance_square then
					write('line', x2, y2)
					return
				end
			elseif d3 < m_distance_tolerance_square then
				write('line', x3, y3)
				return
			end

		elseif case == 1 then
			-- p1,p2,p4 are collinear, p3 is significant
			if d3 * d3 <= m_distance_tolerance_square * (dx*dx + dy*dy) then
				if m_angle_tolerance < curve_angle_tolerance_epsilon then
					write('line', x23, y23)
					return
				end

				-- Angle Condition
				da1 = math.abs(atan2(y4 - y3, x4 - x3) - atan2(y3 - y2, x3 - x2))
				if da1 >= pi then da1 = 2*pi - da1 end

				if da1 < m_angle_tolerance then
					write('line', x2, y2)
					write('line', x3, y3)
					return
				end

				if m_cusp_limit ~= 0 then
					if da1 > m_cusp_limit then
						write('line', x3, y3)
						return
					end
				end
			end
		elseif case == 2 then
			-- p1,p3,p4 are collinear, p2 is significant
			if d2 * d2 <= m_distance_tolerance_square * (dx*dx + dy*dy) then
				if m_angle_tolerance < curve_angle_tolerance_epsilon then
					write('line', x23, y23)
					return
				end

				-- Angle Condition
				da1 = math.abs(atan2(y3 - y2, x3 - x2) - atan2(y2 - y1, x2 - x1))
				if da1 >= pi then da1 = 2*pi - da1 end

				if da1 < m_angle_tolerance then
					write('line', x2, y2)
					write('line', x3, y3)
					return
				end

				if m_cusp_limit ~= 0 then
					if da1 > m_cusp_limit then
						write('line', x2, y2)
						return
					end
				end
			end
		elseif case == 3 then
			-- Regular case
			if (d2 + d3)*(d2 + d3) <= m_distance_tolerance_square * (dx*dx + dy*dy) then
				-- If the curvature doesn't exceed the distance_tolerance value
				-- we tend to finish subdivisions.
				if m_angle_tolerance < curve_angle_tolerance_epsilon then
					write('line', x23, y23)
					return
				end

				-- Angle & Cusp Condition
				k   = atan2(y3 - y2, x3 - x2)
				da1 = math.abs(k - atan2(y2 - y1, x2 - x1))
				da2 = math.abs(atan2(y4 - y3, x4 - x3) - k)
				if da1 >= pi then da1 = 2*pi - da1 end
				if da2 >= pi then da2 = 2*pi - da2 end

				if da1 + da2 < m_angle_tolerance then
				  -- Finally we can stop the recursion
				  write('line', x23, y23)
				  return
				end

				if m_cusp_limit ~= 0 then
					if da1 > m_cusp_limit then
						write('line', x2, y2)
						return
					end

					if da2 > m_cusp_limit then
						write('line', x3, y3)
						return
					end
				end
			end
		end

		-- Continue subdivision
		recursive_bezier(write, x1, y1, x12, y12, x123, y123, x1234, y1234, level + 1)
		recursive_bezier(write, x1234, y1234, x234, y234, x34, y34, x4, y4, level + 1)
	end

	return function(write, x1, y1, x2, y2, x3, y3, x4, y4)
		recursive_bezier(write, x1, y1, x2, y2, x3, y3, x4, y4, 0)
		write('line', x4, y4)
	end
end

return {
	bezier_to_lines_function = bezier_to_lines_function,
}

