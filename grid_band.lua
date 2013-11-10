local player = require'cairo_player'
local layout = require'grid_band_layout'

local function walk_band_cells(f, band, x, y, w, row_h, i, pband)

	x = x or 0
	y = y or 0
	w = w or math.floor(band._w + 0.5)
	row_h = row_h or band.row_h

	local rows = math.max(band.rows or 1, 1)
	local h = rows * row_h

	if band.name then
		if f(band, x, y, w, h, i, pband) == false then
			return false
		end
		y = y + rows * row_h
	end

	local left_w = w
	for i, cband in ipairs(band) do
		local w = math.floor(cband._w + 0.5)
		if i == #band then
			w = left_w
		end
		if walk_band_cells(f, cband, x, y, w, row_h, i, band) == false then
			break
		end
		x = x + w
		left_w = left_w - w
	end
end

local function band_cells(band, x, y)
	return coroutine.wrap(function()
		walk_band_cells(coroutine.yield, band, x, y)
	end)
end

--box math

local function hitbox(x0, y0, x, y, w, h)
	return x0 >= x and x0 <= x + w and y0 >= y and y0 <= y + h
end

local function offsetbox(d, x, y, w, h)
	return x - d, y - d, w + 2*d, h + 2*d
end

local function hitbox_margins(x0, y0, x, y, w, h, d) --top, left, bottom, right
	if hitbox(x0, y0, offsetbox(d, x, y, 0, 0)) then
		return true, true, false, false
	elseif hitbox(x0, y0, offsetbox(d, x + w, y, 0, 0)) then
		return true, false, false, true
	elseif hitbox(x0, y0, offsetbox(d, x, y + h, 0, 0)) then
		return true, false, true, false
	elseif hitbox(x0, y0, offsetbox(d, x + w, y + h, 0, 0)) then
		return false, false, true, true
	elseif hitbox(x0, y0, offsetbox(d, x, y, w, 0)) then
		return true, false, false, false
	elseif hitbox(x0, y0, offsetbox(d, x, y + h, w, 0)) then
		return false, false, true, false
	elseif hitbox(x0, y0, offsetbox(d, x, y, 0, h)) then
		return false, true, false, false
	elseif hitbox(x0, y0, offsetbox(d, x + w, y, 0, h)) then
		return false, false, false, true
	end
end

--hit testing

local function hit_test_band(x0, y0, band, x, y)
	for band, x, y, w, h in band_cells(band, x, y) do
		local top, left, bottom, right = hitbox_margins(x0, y0, x, y, w, h, 5)
		if top ~= nil then
			return band, top, left, bottom, right
		elseif hitbox(x0, y0, x, y, w, h) then
			return band
		end
	end
end

local function eq(a, b, e) return math.abs(a-b) < e end

local function render_band(api, band)
	walk_band_cells(function(band, x, y, w, h, i, pband)
		local constrained = eq(band._w, band._max_w, 0.1) or eq(band._w, band._min_w, 0.1)
		api:rect(x + 0.5, y + 0.5, w, h, constrained and 'hot_bg' or 'normal_bg', 'normal_border', 1)
		api.cr:select_font_face('MS Sans Serif', 0, 0)
		local t = {band.name,
			string.format('%4.2f', band._pw),
			band._min_w .. ' - ' .. band._max_w,
			string.format('%4.2f', band._w)}
		for i,s in ipairs(t) do
			api:text(s, 8, 'normal_fg', 'center', 'middle', x, y + 13 * (i-1), w, h)
		end
	end, band, 10, 10)
end

player.continuous_rendering = false

local band = {
	row_h = 100,
	name = 'A', w = 480,
	{name = 'A1', w = 100, pw = .15},
	{name = 'A2', w = 20},
	{name = 'A3'},
	{name = 'A22', w = 20},
	{name = 'A4'},
	{name = 'A5', w = 120},
}

local band = {
	row_h = 100,
	w = 1000,
	name = 'main',
	{name = 'Product Information', rows = 2,
		{min_w = 100, name = 'Product ID'},
		{min_w = 100, name = 'Product Name'},
	},
	{name = 'Price Information',
		{name = 'Price',
			{min_w = 100, name = 'Qty / Unit', min_w = 40},
			{min_w = 100, name = 'Unit Price'},
			{min_w = 100, name = 'Discontinued'},
		},
		{name = 'Units',
			{min_w = 100, name = 'Units In Stock'},
			{min_w = 100, name = 'Units On Order'},
		},
	},
	{name = 'Other', rows = 2,
		{min_w = 100, name = 'Reorder Level'},
		{min_w = 100, name = 'EAN13'},
	},
}


--set parent and index for each band for stateless navigation

local function set_hierarchy(band)
	for i, cband in ipairs(band) do
		cband.index = i
		cband.parent = band
		set_hierarchy(cband)
	end
end

set_hierarchy(band)
layout.compute(band)

function player:draw_arrow(x, y, angle)
	local cr = self.cr
	local l = 12
	cr:new_path()
	cr:move_to(x, y)
	cr:rotate(math.rad(angle))
	cr:rel_line_to(l/2, 1.2 * l)
	cr:rel_line_to(-l, 0)
	cr:close_path()
	cr:rotate(math.rad(-angle))
	self:fillstroke('#ff0000ff', '#ff0000ff')
end

function player:on_render()

	render_band(self, band, 10, 10)

	local mx, my = self.cr:device_to_user(self.mousex, self.mousey)

	if self.active then
		if self.lbutton then
			if self.ui.move then

				walk_band_cells(function(band, x, y, w, h, i, pband)

					local top, left, bottom, right = hitbox_margins(mx, my, x, y, w, h, 10)
					if top ~= nil then

						if right then
							self:draw_arrow(x + w, y, 180)
							self:draw_arrow(x + w, y + h, 0)
							return false
						elseif bottom then
							self:draw_arrow(x, y + h, 90)
							self:draw_arrow(x + w, y + h, -90)
							return false
						end

					elseif hitbox(mx, my, x, y, w, h) then

					end
				end, band, 10, 10)

			elseif self.ui.vert then
				local row_h = (self.active.h / (self.active.rows or 1))
				self.active.rows = math.max( math.floor( (my - self.active.y) / row_h + 0.5), 1)
			elseif self.active.w then
				self.active.w = mx - self.active.x
				if self.ui.pband then
					--self.ui.pband.w = mx - self.ui.pband.x
				end
				layout.compute(band, 0)
				self:text(self.active.name or '', 8, 'normal_fg', 'right', 'middle', 100, 100, 1000, 100)
			end
		else
			self.active = nil
		end
	end

	walk_band_cells(function(band, x, y, w, h, i, pband)
		band.x = x
		band.y = y
		band.h = h
		local top, left, bottom, right = hitbox_margins(mx, my, x, y, w, h, 5)
		if top ~= nil then
			if (top and left) or (bottom and right) then
				self.cursor = 'resize_nwse'
			elseif (top and right) or (bottom and left) then
				self.cursor = 'resize_nesw'
			elseif bottom then
				self.cursor = 'resize_vertical'
				if not self.active and self.lbutton then
					self.active = band
					self.ui.vert = true
					self.ui.pband = pband
				end
			elseif right then
				local last_band = pband and i == #pband
				self.cursor = 'resize_horizontal'
				if not self.active and self.lbutton then
					self.active = band
					self.ui.vert = false
					self.ui.last_band = last_band
					self.ui.pband = pband
				end
			end
		elseif hitbox(mx, my, x, y, w, h) then
			self.cursor = 'move'
			if not self.active and self.lbutton then
				self.active = band
				self.ui.move = true
			end
		end
	end, band, 10, 10)

end


if not ... then

player:play()

end
