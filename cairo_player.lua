local CPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.messageloop'
local cairo = require'cairo'
local fps = require'fps_function'(2)

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

local player = {window = main, mouse_buttons = {}}

function player:on_render(cr) end
function player:on_init(cr) end

function panel:__create_surface(surface)
	self.cr = surface:create_context()
	player:on_init(self.cr)
end

function panel:__destroy_surface(surface)
	self.cr:free()
end

function panel:on_render(surface)
	main.title = string.format('Cairo %s - %6.2f fps', cairo.cairo_version_string(), fps())
	player:on_render(self.cr)
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

function panel.on_key_down(vk, flags)
	player.key_code = vk
	player.key_flags = flags
	panel:invalidate()
end

panel.on_key_up = panel.on_key_down
panel.on_syskey_down = panel.on_key_down
panel.on_syskey_up = panel.on_key_down

function panel.on_key_down_char(char, flags)
	player.key_char = char
	player.key_flags = flags
	panel:invalidate()
end

panel.on_syskey_down_char = panel.on_key_down_char
panel.on_dead_key_up_char = panel.on_key_down_char
panel.on_dead_syskey_down_char = panel.on_key_down_char

function player:play()
	main:show()
	panel:settimer(1, panel.invalidate) --render continuously
	winapi.MessageLoop()
end

if not ... then require'cairo_player_demo' end

return player

