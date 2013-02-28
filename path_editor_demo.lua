local path = {
	'move', 100, 100,
	'line', 200, 200,
	'line', 300, 50,
	'close',
	'rel_move', 0, 100,
	'rel_line', 100, -100,
	'hline', 500,
	'vline', 200,
	'hline', 600,
	'vline', 300,
	'rel_hline', 100,
	'rel_vline', -100,
	'rel_hline', 100,
	'rel_vline', 100,
	'rel_hline', 100,
	'rel_quad_curve', 50, -100, 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 100, 0,
	'move', 100, 400,
	'quad_curve', 200, 300, 300, 400,
	'smooth_quad_curve', 500, 400,
	'rel_line', 50, 100,
	'rel_smooth_quad_curve', 100, 0,
	'rel_smooth_quad_curve', 0, -100,
	'rel_smooth_quad_curve', 100, 0,
	'move', 100, 600,
	'curve', 50, 500, 250, 500, 200, 600,
	'rel_curve', 150, 100, -50, 100, 100, 0,
	'smooth_curve', 350, 500, 500, 600,
	'rel_smooth_curve', -50, 100, 100, 0,
	'rel_line', 100, 0,
	'rel_smooth_curve', 50, 100, 100, 0,
	'rel_arc', 100, 0, 50, 30, 60,
	'break',
	'arc', 1000, 600, 50, 30, 60,
	'rect', 600, 120, -50, -100,
	'round_rect', 700, 120, -50, -100, -10,
	'circle', 850, 70, -50,
	'ellipse', 1000, 70, -50, -30,
	'move', 1000, 500,
	'elliptical_arc', -50, -20, 0, 0, 1, 1000+30, 500+40,
	'rel_elliptical_arc', -50, -20, 0, 1, 0, 30, 40,
}

local editor = require'path_editor'
local glue = require'glue'
local player = require'cairopanel_player'
local path_simplify = require'path_simplify'
local ffi = require'ffi'

local e = editor(path)

local i = 0
local selected_pi = {} --point indices
local command = 'select'

function player:on_render(cr)
	i = i + 1
	cr:set_source_rgb(0,0,0)
	cr:paint()
	cr:identity_matrix()

	for i=#e.points-1,1,-2 do
		local x, y = e.points[i], e.points[i+1]
		if self.is_dragging then
			if not self.dragging_handle and self:dragging(x, y) then
				self.dragging_handle = i
				self.old_path = glue.update({}, path)
			end
		else
			self.dragging_handle = nil
			self.old_path = nil
		end
		if self.dragging_handle == i then
			e.update_point(i, self.mouse_x, self.mouse_y)
		end
	end

	if not self.dragging_handle then
		if self.is_dragging then
			cr:set_source_rgb(1,1,1)
			cr:set_dash(ffi.new('double[?]', 2, {1,2}), 2, 0)
			cr:rectangle(self.drag_from_x, self.drag_from_y, self.drag_x, self.drag_y)
			cr:stroke()
			local x1, y1, x2, y2 =
				self.drag_from_x,
				self.drag_from_y,
				self.drag_from_x + self.drag_x,
				self.drag_from_y + self.drag_y
			if x2 < x1 then x1, x2 = x2, x1 end
			if y2 < y1 then y1, y2 = y2, y1 end
			selected_pi = {}
			for i=#e.points-1,1,-2 do
				local x, y = e.points[i], e.points[i+1]
				if not e.point_styles[i] and x >= x1 and x <= x2 and y >= y1 and y <= y2 then
					selected_pi[i] = true
				end
			end
			self.drag_select = true
		elseif self.drag_select then
			self.drag_select = nil
		end
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

	cr:set_line_width(1)

	cr:set_dash(ffi.new('double[?]', 2, {1,2}), 2, 0)
	cr:set_source_rgb(0.5,1,0.5)
	path_simplify(write, e.control_path)
	cr:stroke()

	if self.old_path then
		cr:set_dash(nil, 0, 0)
		cr:set_source_rgb(1,1,1)
		cr:new_path()
		path_simplify(write, self.old_path)
		cr:stroke()

		cr:set_dash(ffi.new('double[?]', 2, {1,2}), 2, 0)
		cr:set_source_rgb(0.5,0.5,1)
		cr:new_path()
		path_simplify(write, path)
		cr:stroke()
	else
		cr:set_dash(nil, 0, 0)
		cr:set_source_rgb(1,1,1)
		cr:new_path()
		path_simplify(write, path)
		--cr:fill_preserve()
		cr:stroke()
	end

	for i=1,#e.points,2 do
		local x, y = e.points[i], e.points[i+1]
		if selected_pi[i] then
			cr:set_source_rgb(.5,.5,1)
			cr:rectangle(x-3, y-3, 6, 6)
		elseif e.point_styles[i] == 'control' then
			cr:set_source_rgb(0,1,0)
			cr:circle(x, y, 2)
		else
			cr:set_source_rgb(1,1,1)
			cr:rectangle(x-3, y-3, 6, 6)
		end
		cr:fill()
	end
end
player:play()
