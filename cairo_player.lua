local CPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.messageloop'
local cairo = require'cairo'
local fps = require'fps_function'(2)
local ffi = require'ffi'

local main = winapi.Window{
	autoquit = true,
	visible = false,
	w = 1366, --settle on typical laptop resolution for demos
	h = 768,
	--state = 'maximized',
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
	return winapi.DLGC_WANTALLKEYS
end

function main:on_key_down(vk, flags)
	player.key_state = 'down'
	player.key_code = vk
	player.key_flags = flags
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

function player:hscrollbar(x, y, w, h, size, i, autohide)
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	if autohide and not inbox(mx, my, x, y, w, h) then return end
	local bw = w^2 / size
	local bx = x + i * (w - bw) / (size - w)
	bx = math.min(math.max(bx, x), x + w - bw)

	local hot = inbox(mx, my, bx, y, bw, h)

	if down and hot and not self.vs_w then
		self.vs_w = mx - bx
	elseif not down then
		self.vs_w = nil
	elseif self.vs_w then
		bx = mx - self.vs_w
	end

	bx = math.min(math.max(bx, x), x + w - bw)

	cr:rectangle(bx, y, bw, h)
	if hot then
		if down then
			cr:set_source_rgba(1, 1, 1, 0.9)
		else
			cr:set_source_rgba(1, 1, 1, 0.6)
		end
	else
		cr:set_source_rgba(1, 1, 1, 0.3)
	end
	cr:fill()

	cr:rectangle(x, y, w, h)
	cr:set_source_rgba(1, 1, 1, 0.2)
	cr:fill()

	return (bx - x) / w * size
end

function player:vscrollbar(x, y, w, h, size, i, autohide)
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	if autohide and not inbox(mx, my, x, y, w, h) then return end
	local bh = h^2 / size
	local by = y + i * (h - bh) / (size - h)
	by = math.min(math.max(by, y), y + h - bh)

	local hot = inbox(mx, my, x, by, w, bh)

	if down and hot and not self.vs_h then
		self.vs_h = my - by
	elseif not down then
		self.vs_h = nil
	elseif self.vs_h then
		by = my - self.vs_h
	end

	by = math.min(math.max(by, y), y + h - bh)

	cr:rectangle(x, by, w, bh)
	if hot then
		if down then
			cr:set_source_rgba(1, 1, 1, 0.9)
		else
			cr:set_source_rgba(1, 1, 1, 0.6)
		end
	else
		cr:set_source_rgba(1, 1, 1, 0.3)
	end
	cr:fill()

	cr:rectangle(x, y, w, h)
	cr:set_source_rgba(1, 1, 1, 0.3)
	cr:fill_preserve()

	return (by - y) / h * size
end

--with this kappa the error deviation is ~ 0.0003, see http://www.tinaja.com/glib/ellipse4.pdf.
local kappa = 4 / 3 * (math.sqrt(2) - 1) - 0.000501
local min, max, abs = math.min, math.max, math.abs

function player:button(x1, y1, w, h, s, cut, selected)
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	local rx, ry = 5, 5
	rx = min(abs(rx), abs(w/2))
	ry = min(abs(ry), abs(h/2))
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

	if hot or selected then
		if down or selected then
			cr:set_source_rgba(1, 1, 1, 0.9)
		else
			cr:set_source_rgba(1, 1, 1, 0.6)
		end
	else
		cr:set_source_rgba(1, 1, 1, 0.3)
	end
	cr:fill_preserve()

	cr:set_source_rgba(1, 1, 1, 0.9)
	cr:set_line_width(1)
	cr:stroke()

	cr:set_font_size(16)
	local extents = ffi.new'cairo_text_extents_t'
	cr:text_extents(s, extents)
	cr:move_to((2 * x1 + w - extents.width) / 2, (2 * y1 + h - extents.y_bearing) / 2)
	if hot and down or selected then
		cr:set_source_rgba(0, 0, 0, 1)
	else
		cr:set_source_rgba(1, 1, 1, 1)
	end
	cr:show_text(s)

	return hot and down
end

function player:mbutton(x1, y1, w, h, t, selected)
	local mx, my = self.mouse_x, self.mouse_y
	local down = self.mouse_buttons.lbutton
	local cr = self.cr

	for i=1,#t do
		if self:button(x1, y1, w/#t, h, t[i], #t > 1 and (i==#t and 'left' or i==1 and 'right' or 'both'), selected == i) then
			selected = i
		end
		x1 = x1 + w/#t
	end
	return selected
end

--if not ... then require'cairo_player_demo' end
if not ... then require'freetype_test' end

return player

