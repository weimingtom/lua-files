local editor = require'path_editor'
local player = require'cairopanel_player'
local path_simplify = require'path_simplify'
local path_math = require'path_math'
local winapi = require'winapi'
require'winapi.menuclass'

local tpath = editor:new{
	'move', 10, 10,
	'rel_line', 0, 100,
	'rel_hline', 100,
	'rel_vline', -100,
	'close',
	'rel_move', 110, 0,
	'rel_curve', 100, 0, 0, 100, 100, 100,
	'rel_move', 10, -100,
	'rel_curve', 100, 200, 100, -100, 0, 100,
	'rel_move', 110, -50,
	'rel_curve', 30, -60, 100-30, -60, 100, 0,
	'rel_smooth_curve', 100-30, 60, 100, 0,
	'rel_quad_curve', 50, 50, 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_elliptical_arc', 50, 20, -15, 1, 0, 20, 0,
	'rel_elliptical_arc', 50, 20, -15, 1, 1, 20, 0,
	'rel_arc', 0, 0, 50, 0, -330,
	'rel_arc', 0, 0, 50, 0, 330,
	'break',

	'move', 10, 120,
	'line', 10, 220,
	'hline', 110,
	'vline', 120,
	'close',
	'move', 120, 120,
	'curve', 120+100, 120+0, 120+0, 120+100, 120+100, 120+100,
	'move', 230, 120,
	'curve', 230+100, 120+200, 230+100, 120+-100, 230+0, 120+100,
	'move', 340, 220-50,
	'curve', 340+30, 220+-60-50, 340+100-30, 220+-60-50, 340+100, 220+0-50,
	'smooth_curve', 340+100+100-30, 220+60-50, 340+100+100, 220+0-50,
	'quad_curve', 340+100+100+50, 220+0-50+50, 340+100+100+100, 220+0-50,
	'smooth_quad_curve', 340+100+100+100+100, 220+0-50,
	'elliptical_arc', 50, 20, -15, 1, 0, 340+100+100+100+100+20, 220+0-50,
	'elliptical_arc', 50, 20, -15, 1, 1, 340+100+100+100+100+20+20, 220+0-50,
	'arc', 340+100+100+100+100, 220+0-50, 50, 0, -330,
	'arc', 340+100+100+100+100, 220+0-50, 50, 0, 330,
	'break',

	'ellipse', 960, 60, 100, 50,
	'circle', 960, 60, 50,
	'rect', 960+110, 10, 100, 100,
	'round_rect', 960+220, 10, 100, 100, 20,
	--'move', 860, 220,
	--'text', {size = 110, family = 'georgia', slant = 'italic'}, 'g@AWmi',
}

--[[
	menu_bar_break = MFT_MENUBARBREAK,
	menu_break = MFT_MENUBREAK,
	separator = MFT_SEPARATOR,
	owner_draw = MFT_OWNERDRAW,
	radio_check = MFT_RADIOCHECK,
	rtl = MFT_RIGHTORDER,
	right_align = MFT_RIGHTJUSTIFY, --this and subsequent items (only for menu bar items)

	checked = MFS_CHECKED,
	enabled = negate(MFS_DISABLED),
	highlight = MFS_HILITE,
	is_default = MFS_DEFAULT,
]]
function player:on_init(cr)
	self.menu = self.menu or winapi.Menu{
		items = {
			{text = 'Dude'},--submenu =--type = ,--state = ,
		},
	}
end

local function around(x, y, targetx, targety, radius) --point is in the square around target point
	return
		x >= targetx - radius and x <= targetx + radius and
		y >= targety - radius and y <= targety + radius
end

function player:on_render(cr)
	cr:identity_matrix()
	cr:set_source_rgb(0,0,0)
	cr:paint()

	local function dot(x,y,style)
		cr:new_path()
		cr:circle(x,y,2)
		cr:set_source_rgb(1,1,1)
		cr:fill_preserve()
		cr:set_source_rgb(1,0,0)
		cr:stroke()
	end

	local function line(x1,y1,x2,y2)
		cr:new_path()
		cr:set_source_rgba(0,1,0,0.3)
		cr:move_to(x1,y1)
		cr:line_to(x2,y2)
		cr:stroke()
	end

	local function write(s,...)
		if s == 'move' then
			cr:move_to(...)
		elseif s == 'line' then
			cr:line_to(...)
		elseif s == 'curve' then
			cr:curve_to(...)
		elseif s == 'close' then
			cr:close_path()
		end
	end
	path_simplify(write, tpath.path)
	cr:set_line_width(1)
	cr:set_source_rgba(1,1,1,1)
	cr:stroke()

	if self.cp then
		if self.dragging_point then
			if self.mouse_buttons.lbutton then
				self.cp = tpath:control_points(self.dragging_point, self.mouse_x, self.mouse_y)
			else
				self.dragging_point = nil
			end
		else
			if not self.mouse_buttons then goto done end
			for i=1,#self.cp,3 do
				local x, y = self.cp[i], self.cp[i+1]
				if self.mouse_buttons.lbutton and around(self.mouse_x, self.mouse_y, x, y, 5) then
					self.cp = tpath:control_points(i, self.mouse_x, self.mouse_y)
					self.dragging_point = i
				end
			end
			::done::
		end
	else
		self.cp = tpath:control_points()
	end
	for i=1,#self.cp,3 do
		dot(self.cp[i], self.cp[i+1], self.cp[i+2])
	end

	if self.mouse_buttons and self.mouse_buttons.rbutton then
		self.menu:popup(self.window, self.mouse_x, self.mouse_y)
	end
end

player:play()
