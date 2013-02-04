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

