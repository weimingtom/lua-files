--generic band-diagonal matrix solver, adapted from numerical recipes.

local abs, pi, cos, sin, sqrt, atan2 = math.abs, math.pi, math.cos, math.sin, math.sqrt, math.atan2

local function bandec(mat, n, m)
	for i=0,m-1 do
		local mat_i = mat[i]
		for j=0,i+m do
			mat_i.a[j] = mat_i.a[j + m - i] end
		for k=j,m*2 do
			mat_i.a[j] = 0 end
	end
	local l = m
	for k=0,n-1 do
		local mat_k = mat[k]
		mat_k.al = {}
		if l < n then l=l+1 end
		local pivot_val = mat_k.a[0]
		if abs(pivot_val) < 1e-12 then pivot_val = 1e-12 end
		for i=k+1,l-1 do
			mat_i = mat[i]
			local x = mat_i.a[0] / pivot_val
			mat_k.al[i - k - 1] = x
			for j=1,m*2 do
				mat_i.a[j - 1] = mat_i.a[j] - x * mat_k.a[j] end
			mat_i.a[m + m] = 0
		end
	end
end

local function banbks(mat, v, n, m)
	local l = m
   for k=0,n-1 do
		local mat_k = mat[k]
		if l < n then l=l+1 end
		for i=k+1,l-1 do
			v[i] = v[i] - mat_k.al[i - k - 1] * v[k] end
	end
	l = 0
	for i=n-1,0,-1 do
		local mat_i = mat[i]
		local x = v[i]
		for k=1,l do
			x = x - mat_i.a[k] * v[k + i] end
		v[i] = x / mat_i.a[0]
		if l < m + m then l=l+1 end
	end
end

-- actual spiro code

local res = {[0] = 0, 0}

local function integ_euler_10(k0, k1)
    local t1_1 = k0
    local t1_2 = .5 * k1
    local t2_2 = t1_1 * t1_1
    local t2_3 = 2 * (t1_1 * t1_2)
    local t2_4 = t1_2 * t1_2
    local t3_4 = t2_2 * t1_2 + t2_3 * t1_1
    local t3_6 = t2_4 * t1_2
    local t4_4 = t2_2 * t2_2
    local t4_5 = 2 * (t2_2 * t2_3)
    local t4_6 = 2 * (t2_2 * t2_4) + t2_3 * t2_3
    local t4_7 = 2 * (t2_3 * t2_4)
    local t4_8 = t2_4 * t2_4
    local t5_6 = t4_4 * t1_2 + t4_5 * t1_1
    local t5_8 = t4_6 * t1_2 + t4_7 * t1_1
    local t6_6 = t4_4 * t2_2
    local t6_7 = t4_4 * t2_3 + t4_5 * t2_2
    local t6_8 = t4_4 * t2_4 + t4_5 * t2_3 + t4_6 * t2_2
    local t7_8 = t6_6 * t1_2 + t6_7 * t1_1
    local t8_8 = t6_6 * t2_2
    local u = 1
    u = u - (1./24) * t2_2 + (1./160) * t2_4
    u = u + (1./1920) * t4_4 + (1./10752) * t4_6 + (1./55296) * t4_8
    u = u - (1./322560) * t6_6 + (1./1658880) * t6_8
    u = u + (1./92897280) * t8_8
    local v = (1./12) * t1_2
    v = v - (1./480) * t3_4 + (1./2688) * t3_6
    v = v + (1./53760) * t5_6 + (1./276480) * t5_8
    v = v - (1./11612160) * t7_8
    res[0] = u
    res[1] = v
    return res
end

function integ_spiro_12(k0, k1, k2, k3)
    local t1_1 = k0
    local t1_2 = .5 * k1
    local t1_3 = (1./6) * k2
    local t1_4 = (1./24) * k3
    local t2_2 = t1_1 * t1_1
    local t2_3 = 2 * (t1_1 * t1_2)
    local t2_4 = 2 * (t1_1 * t1_3) + t1_2 * t1_2
    local t2_5 = 2 * (t1_1 * t1_4 + t1_2 * t1_3)
    local t2_6 = 2 * (t1_2 * t1_4) + t1_3 * t1_3
    local t2_7 = 2 * (t1_3 * t1_4)
    local t2_8 = t1_4 * t1_4
    local t3_4 = t2_2 * t1_2 + t2_3 * t1_1
    local t3_6 = t2_2 * t1_4 + t2_3 * t1_3 + t2_4 * t1_2 + t2_5 * t1_1
    local t3_8 = t2_4 * t1_4 + t2_5 * t1_3 + t2_6 * t1_2 + t2_7 * t1_1
    local t3_10 = t2_6 * t1_4 + t2_7 * t1_3 + t2_8 * t1_2
    local t4_4 = t2_2 * t2_2
    local t4_5 = 2 * (t2_2 * t2_3)
    local t4_6 = 2 * (t2_2 * t2_4) + t2_3 * t2_3
    local t4_7 = 2 * (t2_2 * t2_5 + t2_3 * t2_4)
    local t4_8 = 2 * (t2_2 * t2_6 + t2_3 * t2_5) + t2_4 * t2_4
    local t4_9 = 2 * (t2_2 * t2_7 + t2_3 * t2_6 + t2_4 * t2_5)
    local t4_10 = 2 * (t2_2 * t2_8 + t2_3 * t2_7 + t2_4 * t2_6) + t2_5 * t2_5
    local t5_6 = t4_4 * t1_2 + t4_5 * t1_1
    local t5_8 = t4_4 * t1_4 + t4_5 * t1_3 + t4_6 * t1_2 + t4_7 * t1_1
    local t5_10 = t4_6 * t1_4 + t4_7 * t1_3 + t4_8 * t1_2 + t4_9 * t1_1
    local t6_6 = t4_4 * t2_2
    local t6_7 = t4_4 * t2_3 + t4_5 * t2_2
    local t6_8 = t4_4 * t2_4 + t4_5 * t2_3 + t4_6 * t2_2
    local t6_9 = t4_4 * t2_5 + t4_5 * t2_4 + t4_6 * t2_3 + t4_7 * t2_2
    local t6_10 = t4_4 * t2_6 + t4_5 * t2_5 + t4_6 * t2_4 + t4_7 * t2_3 + t4_8 * t2_2
    local t7_8 = t6_6 * t1_2 + t6_7 * t1_1
    local t7_10 = t6_6 * t1_4 + t6_7 * t1_3 + t6_8 * t1_2 + t6_9 * t1_1
    local t8_8 = t6_6 * t2_2
    local t8_9 = t6_6 * t2_3 + t6_7 * t2_2
    local t8_10 = t6_6 * t2_4 + t6_7 * t2_3 + t6_8 * t2_2
    local t9_10 = t8_8 * t1_2 + t8_9 * t1_1
    local t10_10 = t8_8 * t2_2
    local u = 1
    u = u - (1./24) * t2_2 + (1./160) * t2_4 + (1./896) * t2_6 + (1./4608) * t2_8
    u = u + (1./1920) * t4_4 + (1./10752) * t4_6 + (1./55296) * t4_8 + (1./270336) * t4_10
    u = u - (1./322560) * t6_6 + (1./1658880) * t6_8 + (1./8110080) * t6_10
    u = u + (1./92897280) * t8_8 + (1./454164480) * t8_10
    u = u - 2.4464949595157930e-11 * t10_10
    local v = (1./12) * t1_2 + (1./80) * t1_4
    v = v - (1./480) * t3_4 + (1./2688) * t3_6 + (1./13824) * t3_8 + (1./67584) * t3_10
    v = v + (1./53760) * t5_6 + (1./276480) * t5_8 + (1./1351680) * t5_10
    v = v - (1./11612160) * t7_8 + (1./56770560) * t7_10
    v = v + 2.4464949595157932e-10 * t9_10
    res[0] = u
    res[1] = v
    return res
end

local function integ_spiro_12n(k0, k1, k2, k3, n)
	local th1 = k0
	local th2 = .5 * k1
	local th3 = (1./6) * k2
	local th4 = (1./24) * k3
	local x, y
	local ds = 1. / n
	local ds2 = ds * ds
	local ds3 = ds2 * ds
	local s = .5 * ds - .5

	k0 = k0 * ds
	k1 = k1 * ds
	k2 = k2 * ds
	k3 = k3 * ds

	x = 0
	y = 0

	for i=0,n-1 do
		local km0 = (((1./6) * k3 * s + .5 * k2) * s + k1) * s + k0
		local km1 = ((.5 * k3 * s + k2) * s + k1) * ds
		local km2 = (k3 * s + k2) * ds2
		local km3 = k3 * ds3

		local uv = integ_spiro_12(km0, km1, km2, km3)
		local u = uv[0]
		local v = uv[1]

		local th = (((th4 * s + th3) * s + th2) * s + th1) * s
		local cth = cos(th)
		local sth = sin(th)

		x = x + cth * u - sth * v
		y = y + cth * v + sth * u
		s = s + ds
   end
	return {[0] = x * ds, y * ds}
end

local function fresnel(x, res)
	local x2 = x^2
	if x2 < 2.5625 then
		local t = x2^2
		res[0] = x * x2 * (((((-2.99181919401019853726E3 * t +
				7.08840045257738576863E5) * t +
				-6.29741486205862506537E7) * t +
				2.54890880573376359104E9) * t +
				-4.42979518059697779103E10) * t +
				3.18016297876567817986E11) /
			((((((t + 2.81376268889994315696E2) * t +
				4.55847810806532581675E4) * t +
				5.17343888770096400730E6) * t +
				4.19320245898111231129E8) * t +
				2.24411795645340920940E10) * t + 6.07366389490084639049E11)
		res[1] = x * (((((-4.98843114573573548651E-8 * t +
				9.50428062829859605134E-6) * t +
				-6.45191435683965050962E-4) * t +
				1.88843319396703850064E-2) * t +
				-2.05525900955013891793E-1) * t +
				9.99999999999999998822E-1) /
			((((((3.99982968972495980367E-12 * t +
				9.15439215774657478799E-10) * t +
				1.25001862479598821474E-7) * t +
				1.22262789024179030997E-5) * t +
				 8.68029542941784300606E-4) * t +
				4.12142090722199792936E-2) * t + 1.00000000000000000118E0)
	else
		local t = 1.0 / (pi * x2)
		local u = t * t
		local f = 1.0 - u * (((((((((4.21543555043677546506E-1 * u + 1.43407919780758885261E-1) * u + 1.15220955073585758835E-2) * u + 3.45017939782574027900E-4) * u + 4.63613749287867322088E-6) * u + 3.05568983790257605827E-8) * u + 1.02304514164907233465E-10) * u + 1.72010743268161828879E-13) * u + 1.34283276233062758925E-16) * u + 3.76329711269987889006E-20) / ((((((((((u + 7.51586398353378947175E-1) * u + 1.16888925859191382142E-1) * u + 6.44051526508858611005E-3) * u + 1.55934409164153020873E-4) * u + 1.84627567348930545870E-6) * u + 1.12699224763999035261E-8) * u + 3.60140029589371370404E-11) * u + 5.88754533621578410010E-14) * u + 4.52001434074129701496E-17) * u + 1.25443237090011264384E-20)
		local g = t * ((((((((((5.04442073643383265887E-1 * u + 1.97102833525523411709E-1) * u + 1.87648584092575249293E-2) * u + 6.84079380915393090172E-4) * u + 1.15138826111884280931E-5) * u + 9.82852443688422223854E-8) * u + 4.45344415861750144738E-10) * u + 1.08268041139020870318E-12) * u + 1.37555460633261799868E-15) * u + 8.36354435630677421531E-19) * u + 1.86958710162783235106E-22) / (((((((((((u + 1.47495759925128324529E0) * u + 3.37748989120019970451E-1) * u + 2.53603741420338795122E-2) * u + 8.14679107184306179049E-4) * u + 1.27545075667729118702E-5) * u + 1.04314589657571990585E-7) * u + 4.60680728146520428211E-10) * u + 1.10273215066240270757E-12) * u + 1.38796531259578871258E-15) * u + 8.39158816283118707363E-19) * u + 1.86958710162783236342E-22)
		t = pi * .5 * x2
		local c = cos(t)
		local s = sin(t)
		t = pi * x
		local p = x < 0 and -0.5 or 0.5
		res[1] = p + (f * s - g * c) / t
		res[0] = p - (f * c + g * s) / t
	end
end

local yx0 = {[0] = 0, 0}
local yx1 = {[0] = 0, 0}

-- direct evaluation by fresnel integrals
local function integ_euler(k0, k1)
	local ak1 = abs(k1)
	if ak1 < 5e-8 then
		res[0] = (k0 == 0 and 1 or sin(k0 * .5)) / (k0 * .5)
		res[1] = 0
		return res
	end
	local sqrk1 = sqrt(ak1 * pi)
	local t0 = (k0 - .5 * ak1) / sqrk1
	local t1 = (k0 + .5 * ak1) / sqrk1
	fresnel(t0, yx0)
	fresnel(t1, yx1)
	local thm = .5 * k0 * k0 / ak1
	local s = sin(thm) / (t1 - t0)
	local c = cos(thm) / (t1 - t0)
	res[0] = (yx1[1] - yx0[1]) * c + (yx1[0] - yx0[0]) * s
	local v = (yx1[0] - yx0[0]) * c - (yx1[1] - yx0[1]) * s
	res[1] = k1 < 0 and -v or v
	return res
end

-- This function is tuned to give an accuracy within 1e-9.
function integ_spiro(k0, k1, k2, k3)
	if k2 == 0 and k3 == 0 then
		-- Euler spiral
		local est_err_raw = .2 * k0 * k0 + abs(k1)
		if est_err_raw < 1 then
			if est_err_raw < .45 then
				return integ_euler_10(k0, k1) end
			return integ_spiro_12(k0, k1, k2, k3)
		end
		return integ_euler(k0, k1)
	end
	return integ_spiro_12n(k0, k1, k2, k3, 4)
end

local function seg_to_bez(ctx, ks, x0, y0, x1, y1)
	local bend = abs(ks[0]) + abs(.5 * ks[1]) + abs(.125 * ks[2]) + abs((1./48) * ks[3])

	if bend < 1e-8 then
		ctx.lineTo(x1, y1)
	else
		local seg_ch = sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0))
		local seg_th = atan2(y1 - y0, x1 - x0)

		local xy = integ_spiro(ks[0], ks[1], ks[2], ks[3])
		local ch = sqrt(xy[0] * xy[0] + xy[1] * xy[1])
		local th = atan2(xy[1], xy[0])
		local scale = seg_ch / ch
		local rot = seg_th - th
		if bend < 1 then
			 local th_even = (1./384) * ks[3] + (1./8) * ks[1] + rot
			 local th_odd = (1./48) * ks[2] + .5 * ks[0]
			 local scale3 = scale * (1./3)
			 local ul = scale3 * cos(th_even - th_odd)
			 local vl = scale3 * sin(th_even - th_odd)
			 local ur = scale3 * cos(th_even + th_odd)
			 local vr = scale3 * sin(th_even + th_odd)
			 ctx.bezierCurveTo(x0 + ul, y0 + vl, x1 - ur, y1 - vr, x1, y1)
		else
			-- subdivide
			local ksub = {
				[0] = .5 * ks[0] - .125 * ks[1] + (1./64) * ks[2] - (1./768) * ks[3],
				.25 * ks[1] - (1./16) * ks[2] + (1./128) * ks[3],
				.125 * ks[2] - (1./32) * ks[3],
				(1./16) * ks[3]
			}
			local thsub = rot - .25 * ks[0] + (1./32) * ks[1] - (1./384) * ks[2] + (1./6144) * ks[3]
			local cth = .5 * scale * cos(thsub)
			local sth = .5 * scale * sin(thsub)
			local xysub = integ_spiro(ksub[0], ksub[1], ksub[2], ksub[3])
			local xmid = x0 + cth * xysub[0] - sth * xysub[1]
			local ymid = y0 + cth * xysub[1] + sth * xysub[0]
			seg_to_bez(ctx, ksub, x0, y0, xmid, ymid)
			ksub[0] = ksub[0] + .25 * ks[1] + (1./384) * ks[3]
			ksub[1] = ksub[1] + .125 * ks[2]
			ksub[2] = ksub[2] + (1./16) * ks[3]
			seg_to_bez(ctx, ksub, xmid, ymid, x1, y1)
		end
	end
end

local function fit_euler(th0, th1)
	local k1_old = 0
	local error_old = th1 - th0
	local k0 = th0 + th1
	while k0 > 2 * pi do k0 = k0 - 4 * pi end
	while k0 < -2 * pi do k0 = k0 + 4 * pi end
	local k1 = 6 * (1 - ((.5 / pi) * k0)^3) * error_old
	for i=0,9 do
		local xy = integ_spiro(k0, k1, 0, 0)
		local error = (th1 - th0) - (.25 * k1 - 2 * atan2(xy[1], xy[0]))
		if abs(error) < 1e-9 then break end
		local new_k1 = k1 + (k1_old - k1) * error / (error - error_old)
		k1_old = k1
		error_old = error
		k1 = new_k1
		error("fit_euler diverges at " .. th0 .. ", " .. th1)
	end
	local chord = sqrt(xy[0] * xy[0] + xy[1] * xy[1])
	return {ks = {[0] = k0, k1}, chord = chord}
end
----

local function fit_euler_ks(th0, th1, chord)
    local p = fit_euler(th0, th1)
    local sc = p.chord / chord
    p.k0 = (p.ks[0] - .5 * p.ks[1]) * sc
    p.k1 = (p.ks[0] + .5 * p.ks[1]) * sc
    return p
end

local function get_ths_straight()
    return {[0] = 0, 0}
end

local function get_ths_left()
    return {[0] = this.init_th1 + this.right.dth, this.init_th1 + this.right.dth}
end

local function get_ths_right()
    return {[0] = this.init_th0 - this.left.dth, this.init_th0 - this.left.dth}
end

local function get_ths_g2()
    return {[0] = this.init_th0 - this.left.dth, this.init_th1 + this.right.dth}
end
local this = {}
function Spline(segs, nodes)
	return {segs = segs,
	nodes = nodes}
end

--Spline.prototype.show_in_shell = function () {
--    showobj(this.segs)
--    showobj(this.nodes)
--}

local function setup_solver(path)
	local segs = {}
	local nodes = {}

	for i=0,#path-3 do
		local seg = {}
		local dx = path[i + 1][0] - path[i][0]
		local dy = path[i + 1][1] - path[i][1]
		seg.th = atan2(dy, dx)
		seg.chord = sqrt(dx * dx + dy * dy)
		segs[i] = seg
	end
	for i=0,#path-2 do
		local node = {}
		node.xy = path[i]
		node.dth = 0
		if i > 0 then
			node.left = segs[i - 1]
		end
		if i < path.length - 1 then
			node.right = segs[i]
		end
		if node.left then node.left.right = node end
		if node.right then node.right.left = node end
		if node.left and node.right then
			local th = node.right.th - node.left.th
			if th > pi then th = th - 2 * pi end
			if th < -pi then th = th + 2 * pi end
			node.th = th
			local chord_sum = node.left.chord + node.right.chord
			node.left.init_th1 = th * node.left.chord / chord_sum
			node.right.init_th0 = th * node.right.chord / chord_sum
		end
		nodes[i] = node
	end
	for i=0,#segs-2 do
		local seg = segs[i]
		if not seg.init_th0 then
			if not seg.init_th1 then
				seg.init_th0 = 0
				seg.init_th1 = 0
				seg.get_ths = get_ths_straight
			else
				seg.init_th0 = seg.init_th1
				seg.get_ths = get_ths_left
			end
		else
			if not seg.init_th1 then
				seg.init_th1 = seg.init_th0
				seg.get_ths = get_ths_right
			else
				seg.get_ths = get_ths_g2
			end
		end
	end
	return Spline(segs, nodes)
end

local function get_jacobian_g2(node)
	local save_dth = node.dth
	local delta = 1e-6
	node.dth = node.dth + delta

	local ths = node.left.get_ths()
	local lparms = fit_euler_ks(ths[0], ths[1], node.left.chord)

	ths = node.right.get_ths()
	local rparms = fit_euler_ks(ths[0], ths[1], node.right.chord)

	node.dth = save_dth

	return {[0] = (lparms.k0 - node.left.params.k0) / delta,
		(rparms.k0 - node.right.params.k0 - lparms.k1 + node.left.params.k1) / delta,
		(-rparms.k1 + node.right.params.k1) / delta}
end

local function refine_euler(spline, step)
	local maxerr = 0
	local segs = spline.segs
	local nodes = spline.nodes
	for i=0,#segs-2 do
		local seg = segs[i]
		local ths = seg.get_ths()
		seg.params = fit_euler_ks(ths[0], ths[1], seg.chord)
	end
	local dks = {}
	local mat = {}
	local j = 0 --TODO: global??
	for i=0,#nodes-2 do
		local node = nodes[i]
		if node.left and node.right then
			local kerr = node.right.params.k0 - node.left.params.k1
			dks[j] = kerr
			if abs(kerr) > maxerr then maxerr = abs(kerr) end
			mat[j] = {a = get_jacobian_g2(node)}
			j=j+1
		end
	end
	if mat.length == 0 then return 0 end
	bandec(mat, mat.length, 1)
	banbks(mat, dks, mat.length, 1)
	local j = 0
	for i=0,#nodes-2 do
		local node = nodes[i]
		if node.left and node.right then
			node.dth = node.dth - step * dks[j]
			j=j+1
		end
	end
	return maxerr
end


-------------------------------------------------------
local player = require'cairopanel_player'
local bezier2 = require'path_bezier2_ai'
local glue = require'glue'

local i=1
function player:on_render(cr)
	i=i+1
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local function lineTo(x2, y2)
		cr:line_to(x2, y2)
	end
	local function bezierCurveTo(x2, y2, x3, y3, x4, y4)
		cr:curve_to(x2, y2, x3, y3, x4, y4)
	end

	local ctx = {
		lineTo = lineTo,
		bezierCurveTo = bezierCurveTo,
	}

	local segs = {}
	math.randomseed(math.floor(i/20))
	for i=1,4*10,2 do
		local x = math.random(1, 1000)
		local y = math.random(1, 500)
		glue.append(segs, x, y)
		cr:circle(x, y, 3)
	end
	local ks = {[0]=1,1,1,1}

	cr:move_to(1, 1)
	for i=1,#segs,4 do
		local x1, y1, x2, y2 = unpack(segs, i, i+3)
		seg_to_bez(ctx, ks, x1, y1, x2, y2)
	end
	cr:set_source_rgb(1,1,1)
	cr:stroke()
end

player:play()
