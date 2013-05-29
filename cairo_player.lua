local CPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.messageloop'
require'winapi.vkcodes'
require'winapi.keyboard'
local cairo = require'cairo'
local ffi = require'ffi'

local main = winapi.Window{
	autoquit = true,
	visible = false,
	w = 1366, --settle on typical laptop resolution for demos
	h = 768,
	title = 'CairoPanel Player',
}

local panel = CPanel{
	parent = main, w = main.client_w, h = main.client_h,
	anchors = {left=true,right=true,top=true,bottom=true}
}

local player = {window = main, mouse_buttons = {}, mouse_x = 0, mouse_y = 0}

function player:on_render(cr) end
function player:on_init(cr) end

function panel:__create_surface(surface)
	player.cr = surface:create_context()
	player:on_init(player.cr)
end

function panel:__destroy_surface(surface)
	player.cr:free()
end

ffi.cdef'uint32_t GetTickCount();'
local function fps_function()
	local count_per_sec = 1
	local frame_count, last_frame_count, last_time = 0, 0
	return function()
		last_time = last_time or ffi.C.GetTickCount()
		frame_count = frame_count + 1

		local time = ffi.C.GetTickCount()
		if time - last_time > 1000 / count_per_sec then
			last_frame_count, frame_count = frame_count, 0
			last_time = time
		end
		return last_frame_count * count_per_sec
	end
end
local fps = fps_function()

function panel:on_render(surface)
	main.title = string.format('Cairo %s - %6.2f fps', cairo.cairo_version_string(), fps())
	player:on_render(player.cr)
	player.key_state = nil
end

local function around(x, y, targetx, targety, radius) --point is in the square around target point
	return
		x >= targetx - radius and x <= targetx + radius and
		y >= targety - radius and y <= targety + radius
end

function player:dragging(x, y, radius)
	return self.is_dragging and around(self.drag_from_x, self.drag_from_y, x, y, radius or 5)
end

function panel:on_mouse_move(x, y, buttons)
	player.mouse_last = {
		x = player.mouse_x,
		y = player.mouse_y,
		buttons = player.mouse_buttons
	}
	player.mouse_x = x
	player.mouse_y = y
	player.mouse_buttons = buttons
	if player.is_dragging then
		if buttons.lbutton then
			player.drag_x = player.mouse_x - player.drag_from_x
			player.drag_y = player.mouse_y - player.drag_from_y
		else
			player.is_dragging = false
			player.drag_x, player.drag_y, player.drag_from_x, player.drag_from_y = nil
		end
	elseif buttons.lbutton then
		player.is_dragging = true
		player.drag_from_x = x
		player.drag_from_y = y
		player.drag_x, player.drag_y = 0, 0
	end
	self:invalidate()
end

panel.on_mouse_over = panel.on_mouse_move
panel.on_mouse_leave = panel.on_mouse_move
panel.on_lbutton_double_click = panel.on_mouse_move
panel.on_lbutton_down = panel.on_mouse_move
panel.on_lbutton_up = panel.on_mouse_move
panel.on_mbutton_double_click = panel.on_mouse_move
panel.on_mbutton_down = panel.on_mouse_move
panel.on_mbutton_up = panel.on_mouse_move
panel.on_rbutton_double_click = panel.on_mouse_move
panel.on_rbutton_down = panel.on_mouse_move
panel.on_rbutton_up = panel.on_mouse_move
panel.on_xbutton_double_click = panel.on_mouse_move
panel.on_xbutton_down = panel.on_mouse_move
panel.on_xbutton_up = panel.on_mouse_move
panel.on_mouse_wheel = panel.on_mouse_move
panel.on_mouse_hwheel = panel.on_mouse_move

function main:WM_GETDLGCODE()
	return bit.bor(winapi.DLGC_WANTALLKEYS, winapi.DLGC_WANTCHARS)
end

function main:on_key_down(vk, flags)
	player.key_state = 'down'
	player.key_code = vk
	player.key_flags = flags
	player.ctrl = bit.band(ffi.C.GetKeyState(winapi.VK_CONTROL), 0x8000) ~= 0
	panel:invalidate()
end

function main:on_key_up(vk, flags)
	player.key_state = 'up'
	player.key_code = vk
	player.key_flags = flags
	panel:invalidate()
end

main.on_syskey_down = main.on_key_down
main.on_syskey_up = main.on_key_up

function main:on_key_down_char(char, flags)
	print'here'
	player.key_state = 'down'
	player.key_char = char
	player.key_flags = flags
	panel:invalidate()
end

main.on_syskey_down_char = main.on_key_down_char
main.on_dead_syskey_down_char = main.on_key_down_char

function main:on_dead_key_up_char(char, flags)
	player.key_state = 'up'
	player.key_char = char
	player.key_flags = flags
	panel:invalidate()
end

function player:play()
	main:show()
	panel:settimer(1, panel.invalidate) --render continuously
	winapi.MessageLoop()
end

local function inbox(x, y, bx, by, bw, bh)
	return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

function player:hscrollbar(t)
	local id, x, y, w, h, size, i, autohide = t.id, t.x, t.y, t.w, t.h, t.size, t.i, t.autohide
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	if autohide and not inbox(mx, my, x, y, w, h) then return i end
	local bw = w^2 / size
	local bx = x + i * (w - bw) / (size - w)
	bx = math.min(math.max(bx, x), x + w - bw)

	local hot = inbox(mx, my, bx, y, bw, h)

	if down and hot and not self.active then
		self.active = id
		self.vs_w = mx - bx
	elseif self.active == id then
		if down then
			bx = mx - self.vs_w
		else
			self.active = nil
			self.vs_w = nil
		end
	end

	bx = math.min(math.max(bx, x), x + w - bw)

	cr:rectangle(bx, y, bw, h)
	cr:set_source_rgba(1, 1, 1, hot and (down and 0.9 or 0.6) or 0.3)
	cr:fill()

	cr:rectangle(x, y, w, h)
	cr:set_source_rgba(1, 1, 1, 0.2)
	cr:fill()

	return (bx - x) / w * size
end

function player:vscrollbar(t)
	local id, x, y, w, h, size, i, autohide = t.id, t.x, t.y, t.w, t.h, t.size, t.i, t.autohide
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	if autohide and not inbox(mx, my, x, y, w, h) then return i end
	local bh = h^2 / size
	local by = y + i * (h - bh) / (size - h)
	by = math.min(math.max(by, y), y + h - bh)

	local hot = inbox(mx, my, x, by, w, bh)

	if down and hot and not self.active then
		self.active = id
		self.vs_h = my - by
	elseif self.active == id then
		if down then
			by = my - self.vs_h
		else
			self.active = nil
			self.vs_h = nil
		end
	end

	by = math.min(math.max(by, y), y + h - bh)

	cr:rectangle(x, by, w, bh)
	cr:set_source_rgba(1, 1, 1, hot and (down and 0.9 or 0.6) or 0.3)
	cr:fill()

	cr:rectangle(x, y, w, h)
	cr:set_source_rgba(1, 1, 1, 0.3)
	cr:fill()

	return (by - y) / h * size
end

local kappa = 4 / 3 * (math.sqrt(2) - 1)

function player:button(t)
	local id, x1, y1, w, h, text, cut, selected = t.id, t.x, t.y, t.w, t.h, t.text, t.cut, t.selected
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	local rx, ry = 5, 5
	rx = math.min(math.abs(rx), math.abs(w/2))
	ry = math.min(math.abs(ry), math.abs(h/2))
	if rx == 0 and ry == 0 then
		rect_to_lines(write, x1, y1, w, h)
		return
	end
	local x2, y2 = x1 + w, y1 + h
	if x1 > x2 then x2, x1 = x1, x2 end
	if y1 > y2 then y2, y1 = y1, y2 end
	local lx = rx * kappa
	local ly = ry * kappa
	local cx, cy = x2-rx, y1+ry
	if cut == 'right' or cut == 'both' then
		cr:move_to(x2, y1)
		cr:line_to(x2, y2)
		cr:line_to(cut == 'right' and x1+rx or x1, y2)
	else
		cr:move_to(cx, y1)
		cr:curve_to(cx+lx, cy-ry, cx+rx, cy-ly, cx+rx, cy) --q1
		cr:line_to(x2, y2-ry)
		cx, cy = x2-rx, y2-ry
		cr:curve_to(cx+rx, cy+ly, cx+lx, cy+ry, cx, cy+ry) --q4
		cr:line_to(cut and x1 or x1+rx, y2)
	end
	if cut == 'left' or cut == 'both' then
		cr:line_to(x1, y1)
	else
		cx, cy = x1+rx, y2-ry
		cr:curve_to(cx-lx, cy+ry, cx-rx, cy+ly, cx-rx, cy) --q3
		cr:line_to(x1, y1+ry)
		cx, cy = x1+rx, y1+ry
		cr:curve_to(cx-rx, cy-ly, cx-lx, cy-ry, cx, cy-ry) --q2
		cr:line_to(cx, y1)
	end
	cr:close_path()

	local hot = inbox(mx, my, x1, y1, w, h)

	local clicked = false
	if hot and down and not self.active then
		self.active = id
	elseif self.active == id then
		if hot then
			clicked = not down
			selected = clicked
		elseif not down then
			self.active = nil
		end
	end

	cr:set_source_rgba(1, 1, 1, (hot or selected) and ((down or selected) and 0.9 or 0.6) or 0.3)
	cr:fill_preserve()

	cr:set_source_rgba(1, 1, 1, 0.3)
	cr:set_line_width(1)
	cr:stroke()

	cr:set_font_size(h / 2)
	local extents = cr:text_extents(text)
	cr:move_to((2 * x1 + w - extents.width) / 2, (2 * y1 + h - extents.y_bearing) / 2)
	if hot and down or selected then
		cr:set_source_rgba(0, 0, 0, 1)
	else
		cr:set_source_rgba(1, 1, 1, 1)
	end
	cr:show_text(text)

	return clicked
end

function player:mbutton(t)
	local id, x, y, w, h, buttons, selected = t.id, t.x, t.y, t.w, t.h, t.buttons, t.selected
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	local bwidth = w/#buttons
	for i=1,#buttons do
		local cut = #buttons > 1 and (i==#buttons and 'left' or i==1 and 'right' or 'both')
		if self:button{id = id..'_'..i, x = x, y = y, w = bwidth, h = h, text = buttons[i],
							cut = cut, selected = selected == i}
		then
			selected = i
		end
		x = x + bwidth
	end
	return selected
end

function player:tabs(t)
	local id, x, y, w, h, buttons, selected = t.id, t.x, t.y, t.w, t.h, t.buttons, t.selected
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	local bwidth = w/#buttons
	for i=1,#buttons do
		if self:button{id = id..'_'..i, x = x, y = y, w = bwidth, h = h, text = buttons[i],
							cut = 'both', selected = selected == i}
		then
			selected = i
		end
		x = x + bwidth
	end
	return selected
end

function player:edit(t)
	local id, x, y, w, h, text, tabstop = t.id, t.x, t.y, t.w, t.h, t.text, t.tabstop
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr
	local caret_w = 2

	local hot = inbox(mx, my, x, y, w, h)

	cr:save()
	cr:rectangle(x, y, w, h)
	cr:set_source_rgba(1,1,1, 0.3 + (hot and 0.1 or 0))
	cr:fill_preserve()
	cr:clip()

	local text_x = 0
	local caret_pos
	if (not self.active and ((hot and down) or not self.activate or self.activate == id)) then
		self.active = id
		self.focus_tab = nil
		self.text_x = 0
		self.caret_pos = #text
		caret_pos = #text
	elseif self.active == id then
		if down and not hot then
			self.active = nil
			self.text_x = nil
			self.caret_pos = nil
		elseif self.key_state == 'down' and self.key_code == winapi.VK_TAB then
			self.activate = self.key_flags.shift and t.prev_tab or t.next_tab
			self.active = nil
			self.text_x = nil
			self.caret_pos = nil
		else
			text_x = self.text_x
			caret_pos = self.caret_pos
		end
	end

	cr:set_font_size(h * .8)

	local caret_x
	if caret_pos then
		local vk = self.key_code
		if self.key_state == 'down' then
			if vk == winapi.VK_LEFT then
				if self.ctrl then
					local pos = text:sub(1, math.max(0, caret_pos - 1)):find('%s[^%s]*$') or 0
					caret_pos = math.max(0, pos)
				else
					caret_pos = math.max(0, caret_pos - 1)
				end
			elseif vk == winapi.VK_RIGHT then
				if self.ctrl then
					local pos = text:find('%s', caret_pos + 1) or #text
					caret_pos = math.min(#text, pos)
				else
					caret_pos = math.min(#text, caret_pos + 1)
				end
			elseif vk == winapi.VK_UP then
			elseif vk == winapi.VK_DOWN then
			elseif vk == winapi.VK_BACK then
				text = text:sub(1, caret_pos - 1) .. text:sub(caret_pos + 1)
				caret_pos = math.max(0, caret_pos - 1)
			elseif vk == winapi.VK_DELETE then
				text = text:sub(1, caret_pos) .. text:sub(caret_pos + 2)
			elseif self.key_char then
				text = text:sub(1, caret_pos) .. self.key_char .. text:sub(caret_pos + 1)
			end
		end

		local text_w = cr:text_extents(text).x_advance
		caret_x = cr:text_extents(text:sub(1, caret_pos) .. '\0').x_advance
		text_x = math.min(text_x, -(caret_x + caret_w - w))
		text_x = math.max(text_x, -caret_x)

		self.caret_pos = caret_pos
		self.text_x = text_x
	end

	cr:move_to(x + text_x, y + h * .8)
	cr:set_source_rgba(1, 1, 1, 1)
	cr:show_text(text)

	if caret_x then
		cr:set_source_rgba(1, 1, 1, 1)
		cr:rectangle(x + text_x + caret_x, y, caret_w, h)
		cr:fill()
	end

	cr:restore()

	return text
end

if not ... then require'cairo_player_ui_demo' end
--if not ... then require'freetype_test' end

return player

