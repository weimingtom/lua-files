--2d cubic bezier linear interpolation from http://www.antigrain.com/research/bezier_interpolation/index.html
--the interpolator also produces the bezier parameter (or time) corresponding to the 2nd point of the line segment.

local function interpolate(write, x1, y1, x2, y2, x3, y3, x4, y4, steps)
	steps = steps or 100

	local dx1 = x2 - x1
	local dy1 = y2 - y1
	local dx2 = x3 - x2
	local dy2 = y3 - y2
	local dx3 = x4 - x3
	local dy3 = y4 - y3

	local subdiv_step  = 1 / (steps + 1)
	local subdiv_step2 = subdiv_step^2
	local subdiv_step3 = subdiv_step^3

	local pre1 = 3 * subdiv_step
	local pre2 = 3 * subdiv_step2
	local pre4 = 6 * subdiv_step2
	local pre5 = 6 * subdiv_step3

	local tmp1x = x1 - x2 * 2 + x3
	local tmp1y = y1 - y2 * 2 + y3

	local tmp2x = (x2 - x3) * 3 - x1 + x4
	local tmp2y = (y2 - y3) * 3 - y1 + y4

	local fx = x1
	local fy = y1

	local dfx = (x2 - x1)*pre1 + tmp1x*pre2 + tmp2x*subdiv_step3
	local dfy = (y2 - y1)*pre1 + tmp1y*pre2 + tmp2y*subdiv_step3

	local ddfx = tmp1x*pre4 + tmp2x*pre5
	local ddfy = tmp1y*pre4 + tmp2y*pre5

	local dddfx = tmp2x*pre5
	local dddfy = tmp2y*pre5

	local tstep = 1/steps
	local t = tstep

	for i=1,steps do
		fx   = fx + dfx
		fy   = fy + dfy
		dfx  = dfx + ddfx
		dfy  = dfy + ddfy
		ddfx = ddfx + dddfx
		ddfy = ddfy + dddfy
		write('line', fx, fy, t)
		t = t + tstep
	end
	write('line', x4, y4, t)
end

if not ... then require'path_hit_demo' end

return interpolate
