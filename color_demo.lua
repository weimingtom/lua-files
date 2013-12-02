local color = require'color'
local player = require'cplayer'
local box = require'box2d'
local point = require'path_point'

local cx, cy, r1, r2, step = 200, 200, 100, 150, 1
local sx, sy, sw, sh, stepx, stepy = 400, 50, 300, 300, 0.01, 0.01

local hue, s, L = 0, 0.7, 0.3

function player:on_render(cr)

	local mx, my = self:mousepos()

	--wheel picker

	local hue1 = point.point_angle(mx, my, cx, cy)
	local d = point.distance(mx, my, cx, cy)
	local hot = d >= r1 and d <= r2

	for i = 0, 360, step do
		local r, g, b = color.hsl_to_rgb(i, 1, .5)
		cr:set_source_rgba(r, g, b, 1)
		cr:new_path()
		cr:arc(cx, cy, r1, math.rad(i), math.rad(i + step + 1))
		cr:arc_negative(cx, cy, r2, math.rad(i + step + 1), math.rad(i))
		cr:close_path()
		cr:fill()
	end

	if not self.active and hot and self.lpressed then
		self.active = 'wheel'
	elseif self.active == 'wheel' then
		if self.lbutton then
			hue = hue1
		else
			self.active = nil
		end
	end

	if hot or self.active then
		self.cursor = 'link'
	end

	local x, y = point.point_around(cx, cy, (r1 + r2) / 2, hue)
	self:dot(math.floor(x + 0.5), math.floor(y + 0.5), 5, 'normal_fg')

	--s, L picker

	for L = 0, 1, stepy do
		for s = 0, 1, stepx do
			local r, g, b = color.hsl_to_rgb(hue + 360, s, L)
			cr:set_source_rgba(r, g, b, 1)
			cr:rectangle(sx + s * sw, sy + L * sh, sw * stepx + 1, sh * stepy + 1)
			cr:fill()
		end
	end

	local shot = box.hit(mx, my, sx, sy, sw, sh)

	if not self.active and shot and self.lpressed then
		self.active = 'square'
	elseif self.active == 'square' then
		if self.lbutton then
			s = (mx - sx) / sw
			L = (my - sy) / sh
			s = math.min(math.max(s, 0), 1)
			L = math.min(math.max(L, 0), 1)
		else
			self.active = nil
		end
	end

	local x0 = sx + s * sw
	local y0 = sy + L * sh
	x0 = x0 + 0.5
	y0 = y0 + 0.5

	local r, g, b = color(hue, 1-s, 1-L):rgb()
	self:dot(x0, y0, 5, {r, g, b, 1}, {color(hue, s, 1-L):rgba()})

	--color derivations

	cr:translate(800, 100)
	local c1 = color(hue, s, L)
	local c1c = c1:complementary()
	local c2, c3 = c1:triadic()

	self:dot(0, 0, 40, {c1:rgba()})
	self:dot(100, 0, 40, {c2:rgba()})
	self:dot(200, 0, 40, {c3:rgba()})
	self:dot(0, 100, 40, {c1c:rgba()})

end

player:play()


