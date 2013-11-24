setfenv(1, require'windesigner.namespace')
require'winapi.panelclass'

--helpers

local function round(x, p) --round to the closest multiple of p
	if not x then return end
	p = p or 1
	local m = x % p
	return x - m + (m > p/2 and p or 0)
end

local function unpack_rect(r)
	return r.x1, r.y1, r.x2, r.y2
end

local function point_inside(x, y, x1, y1, x2, y2) --point inside rectangle test
	return x1 <= x and x2 >= x and y1 <= y and y2 >= y
end

local function rect_around(x, y, q) --return the rectangle around a center point and a median radius
	return x-q, y-q, x+q, y+q
end

local function zoom_rect(q, x1, y1, x2, y2) --equally enlarge all sides of a rectangle
	return x1-q, y1-q, x2+q, y2+q
end

local function hit_test(x, y, q, selected, x1, y1, x2, y2) --return cursor and "move mask" for each side of the rectangle
	local t,f=true,false
	if point_inside(x, y, x1, y1, x2, y2) then
		if selected then
			x1, y1, x2, y2 = zoom_rect(-q, x1, y1, x2, y2)
			if point_inside(x, y, rect_around(x1, y1, q)) then
				return IDC_SIZENWSE,t,t,f,f
			elseif point_inside(x, y, rect_around(x2, y2, q)) then
				return IDC_SIZENWSE,f,f,t,t
			elseif point_inside(x, y, rect_around(x1, y2, q)) then
				return IDC_SIZENESW,t,f,f,t
			elseif point_inside(x, y, rect_around(x2, y1, q)) then
				return IDC_SIZENESW,f,t,t,f
			else
				local mx = x1 + round((x2 - x1) / 2)
				local my = y1 + round((y2 - y1) / 2)
				if point_inside(x, y, rect_around(mx, y1, q)) then
					return IDC_SIZENS,f,t,f,f
				elseif point_inside(x, y, rect_around(mx, y2, q)) then
					return IDC_SIZENS,f,f,f,t
				elseif point_inside(x, y, rect_around(x1, my, q)) then
					return IDC_SIZEWE,t,f,f,f
				elseif point_inside(x, y, rect_around(x2, my, q)) then
					return IDC_SIZEWE,f,f,t,f
				end
			end
		end
		return IDC_ARROW,t,t,t,t
	end
end

--the panel class

SelectionPanel = class(Panel)

local default_config = {
	grid = {6, 6},
	show_grid = false,
	grip_radius = 2,
	grip_hover_radius = 4,
	snap_size = 12,
}

function SelectionPanel:__init(window, designer)
	self.designer = designer
	self.config = update({}, default_config, designer.config)
	SelectionPanel.__index.__init(self, {
		parent = window, w = window.client_w, h = window.client_h, transparent = true,
		anchors = {left = true, top = true, right = true, bottom = true},
	})
	self.selected_controls = {}

	local on_paint = window.on_paint
	function window.on_paint(_self, hdc)
		self:draw_snapping_grid(hdc)
		self:draw_drag_select_rect(hdc)
		if on_paint then on_paint(_self, hdc) end
	end
end

--finding controls

--TODO: iterate controls in depth (the z-order is already correct; dive recursively then iterate siblings)
local function filtered_next(filter)
	return function(self, ctl)
		repeat
			ctl = self.parent:next_child(ctl)
		until not ctl or filter(self, ctl)
		return ctl
	end
end
local next_control = filtered_next(function(self, ctl)
	return ctl ~= self
end)
local next_selected = filtered_next(function(self, ctl)
	return ctl ~= self and self.selected_controls[ctl]
end)
local next_unselected = filtered_next(function(self, ctl)
	return ctl ~= self and not self.selected_controls[ctl]
end)
function SelectionPanel:controls()   return next_control, self end
function SelectionPanel:selected()   return next_selected, self end
function SelectionPanel:unselected() return next_unselected, self end

function SelectionPanel:hit_test(x, y) --hit test all controls; return cursor, the hit control, and move mask
	local q = self.config.grip_hover_radius
	local r
	for ctl in self:controls() do
		r = ctl:get_rect(r)
		local cursor,m1,m2,m3,m4 = hit_test(x, y, q, self.selected_controls[ctl], unpack_rect(r))
		if cursor then
			return cursor,ctl,m1,m2,m3,m4
		end
	end
	return IDC_ARROW
end

function SelectionPanel:get_hover_cursor(x, y) --hit test selected controls to get the hover cursor
	return (self:hit_test(x, y, self.config.grip_hover_radius))
end

--selecting controls

function SelectionPanel:selection_changed()
	self.parent:redraw()
	self.designer:selection_changed(self.selected_controls)
end

local function normalize_rect(r) --switch rect sides to get a positive first diagonal vector
	local x1, y1, x2, y2 = unpack_rect(r)
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	return RECT(x1, y1, x2, y2)
end

local function intersect_rect(a, b) --rectangles intersection test
	return ((a.x2 > b.x1 and a.x1 < b.x2) or (b.x2 > a.x1 and b.x1 < a.x2)) and
			 ((a.y2 > b.y1 and a.y1 < b.y2) or (b.y2 > a.y1 and b.y1 < a.y2))
end

function SelectionPanel:select_touching(dr) --rect
	dr = normalize_rect(dr)
	local r
	for ctl in self:controls() do
		r = ctl:get_rect(r)
		if intersect_rect(r, dr) then
			self.selected_controls[ctl] = true
		end
	end
	self:selection_changed()
end

--copy/pasting controls

function SelectionPanel:copy_controls()
	local controls = {}
	for ctl in self:selected() do --we need them in z-order
		local info = ctl.info
		info.visible = false
		info.parent = nil
		controls[#controls+1] = ctl.__class(info)
	end
	return controls
end

function SelectionPanel:cut_controls()
	local controls = collect(self:selected())
	self.selected_controls = {}
	self:selection_changed()
	for _,ctl in ipairs(controls) do
		ctl.visible = false
		ctl.parent = nil
	end
	return controls
end

function SelectionPanel:paste_controls(controls)
	for i=#controls,1,-1 do
		local ctl = controls[i]
		ctl.parent = self.parent
		ctl.visible = true
		self.selected_controls[ctl] = true
	end
	self:selection_changed()
	self:bring_to_front()
end

function SelectionPanel:delete_controls()
	for ctl in pairs(self.selected_controls) do
		ctl:free()
	end
	self.selected_controls = {}
	self:selection_changed()
end

--moving controls

local function snap_offset(a, b, q)
	if math.abs(b - a) < q then return b - a end
end

function move_rect(r, d)
	return RECT(r.x1+d.x1, r.y1+d.y1, r.x2+d.x2, r.y2+d.y2)
end

function mask_rect(mask, r, d)
	return RECT(mask[1] and d.x1 or r.x1,
					mask[2] and d.y1 or r.y1,
					mask[3] and d.x2 or r.x2,
					mask[4] and d.y2 or r.y2)
end

function SelectionPanel:move_controls(dx, dy, st, ut, ctl, mask, snapping) --get a pencil
	local dr = RECT(dx, dy, dx, dy)

	if snapping then
		local o = RECT()
		local gr = RECT(self.config.grid[1], self.config.grid[2], self.config.grid[1], self.config.grid[2])
		local function snap_side(i) --snap the moved side "i" of selected controls to the same side of unselected controls
			for _,sr in pairs(st) do
				local x = sr[i] + dr[i]
				--snap to unselected controls
				for _,ur in pairs(ut) do
					local d = snap_offset(x, ur[i], self.config.snap_size)
					if d then
						o[i] = d
						return true
					end
				end
			end
			--snap to grid only the control under the mouse
			local x = st[ctl][i] + dr[i]
			local d = snap_offset(x, round(x, gr[i]), gr[i])
			if d then
				o[i] = d
			end
		end

		--this messy logic helps keep the width and the height of the control stable while moving
		if mask[1] and snap_side'x1' then
			o.x2 = o.x1
		elseif mask[3] then
			snap_side'x2'
			if mask[1] then o.x1 = o.x2 end
		end

		if mask[2] and snap_side'y1' then
			o.y2 = o.y1
		elseif mask[4] then
			snap_side'y2'
			if mask[2] then o.y1 = o.y2 end
		end

		dr = move_rect(dr, o)
	end

	for ctl,r in pairs(st) do
		ctl.rect = mask_rect(mask, r, move_rect(r, dr))
	end
end

--drawing on the parent window

function SelectionPanel:draw_snapping_grid(hdc)
	if self.config.show_grid and self.config.grid[1] > 3 and self.config.grid[2] > 3 then
		for y = 0, self.h, self.config.grid[2] do
			for x = 0, self.w, self.config.grid[1] do
				SetPixel(hdc, x, y, 0x00000000)
			end
		end
	end
end

function SelectionPanel:draw_drag_select_rect(hdc)
	local ds = self.drag_state
	if not ds or not ds.select_rect then return end
	SelectObject(hdc, GetStockObject(DC_PEN))
	SelectObject(hdc, GetStockObject(NULL_BRUSH))
	Rectangle(hdc, unpack_rect(ds.select_rect))
end

--drawing on the panel

function SelectionPanel:draw_control_grips(hdc)
	local q = self.config.grip_radius
	for ctl in pairs(self.selected_controls) do
		local r = ctl.rect
		local x1, y1, x2, y2 = zoom_rect(-q, unpack_rect(r))
		SelectObject(hdc, GetStockObject(DC_PEN))
		SelectObject(hdc, GetStockObject(DC_BRUSH))
		--corner dots
		Rectangle(hdc, rect_around(x1, y1, q))
		Rectangle(hdc, rect_around(x2, y2, q))
		Rectangle(hdc, rect_around(x1, y2, q))
		Rectangle(hdc, rect_around(x2, y1, q))
		--median dots
		local mx = x1 + round((x2 - x1) / 2)
		local my = y1 + round((y2 - y1) / 2)
		Rectangle(hdc, rect_around(mx, y1, q))
		Rectangle(hdc, rect_around(mx, y2, q))
		Rectangle(hdc, rect_around(x1, my, q))
		Rectangle(hdc, rect_around(x2, my, q))
	end
end

function SelectionPanel:on_paint(hdc)
	self:draw_control_grips(hdc)
end

--setting the cursor

function SelectionPanel:set_cursor() --either the cursor is fixed or we get it with a hit test
	local cursor
	if self.drag_state and self.drag_state.cursor then
		cursor = self.drag_state.cursor
	else
		local p = Windows:map_point(self, GetCursorPos())
		cursor = self:get_hover_cursor(p.x, p.y)
	end
	SetCursor(LoadCursor(cursor))
end

--interaction

function SelectionPanel:on_lbutton_down(x, y, buttons)
	self.drag_state = {}
	local ds = self.drag_state
	SetCapture(self.hwnd)

	local cursor,ctl,m1,m2,m3,m4 = self:hit_test(x, y)
	ds.cursor = cursor
	self:set_cursor()

	if ctl then --clicked on a control: select it and prepare for moving/resizing
		local moving = m1 and m2 and m3 and m4

		if moving and not buttons.shift and not self.selected_controls[ctl] then
			self.selected_controls = {}
		end
		self.selected_controls[ctl] = not (buttons.shift and moving) and true or not self.selected_controls[ctl]
		self:selection_changed()

		ds.control = ctl --the control under the mouse
		ds.test_it = moving --delayed drag: prevents accidental moving if you only want to select
		ds.x1, ds.y1 = x, y
		ds.move_mask = {m1,m2,m3,m4}
		ds.selected = {}
		for ctl in self:selected() do
			ds.selected[ctl] = ctl.rect
		end
		ds.unselected = {}
		for ctl in self:unselected() do
			ds.unselected[ctl] = ctl.rect
			ctl:invalidate() --clean up grips smudge from overlapping selected controls
		end
	else --clicked outside a control: unselect all and prepare the select rectangle
		self.selected_controls = {}
		self:selection_changed()
		ds.select_rect = RECT(x, y, x, y)
	end
end

function SelectionPanel:on_lbutton_up(x, y, buttons)
	if not self.drag_state then return end
	ReleaseCapture(self.hwnd)
	if self.drag_state.test_it and not buttons.shift then
		self.selected_controls = {[self.drag_state.control] = true}
		self:selection_changed()
	end
	self.drag_state = nil
	self.parent:redraw() --remove drag-select rectangle if any
	self:set_cursor()
end

function SelectionPanel:on_mouse_move(x, y, buttons)
	local ds = self.drag_state
	if not ds then return end

	if ds.test_it then --do a "detect drag" stunt
		ds.test_it = point_inside(x, y, rect_around(ds.x1, ds.y1, 10))
		if ds.test_it then return end
	end

	if ds.control then --move to delta coordinates from the initial perspective
		self:move_controls(x - ds.x1, y - ds.y1, ds.selected, ds.unselected, ds.control, ds.move_mask, not buttons.shift)
	else --drag-select
		ds.select_rect.x2 = x
		ds.select_rect.y2 = y
		self.parent:invalidate()
		self:select_touching(ds.select_rect)
	end
end

function SelectionPanel:on_set_cursor()
	self:set_cursor()
	return 1
end

