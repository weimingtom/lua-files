local CPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.messageloop'
require'winapi.vkcodes'
require'winapi.keyboard'
local cairo = require'cairo'
local ffi = require'ffi'

--winapi keycodes. key codes for 0-9 and A-Z keys are ascii codes.
local keynames = {
	[0x08] = 'backspace',[0x09] = 'tab',      [0x0d] = 'return',   [0x10] = 'shift',    [0x11] = 'control',
	[0x12] = 'alt',      [0x13] = 'break',    [0x14] = 'caps',     [0x1b] = 'esc',      [0x20] = 'space',
	[0x21] = 'pageup',   [0x22] = 'pagedown', [0x23] = 'end',      [0x24] = 'home',     [0x25] = 'left',
	[0x26] = 'up',       [0x27] = 'right',    [0x28] = 'down',     [0x2c] = 'printscreen',
	[0x2d] = 'insert',   [0x2e] = 'delete',   [0x60] = 'numpad0',  [0x61] = 'numpad1',  [0x62] = 'numpad2',
	[0x63] = 'numpad3',  [0x64] = 'numpad4',  [0x65] = 'numpad5',  [0x66] = 'numpad6',  [0x67] = 'numpad7',
	[0x68] = 'numpad8',  [0x69] = 'numpad9',  [0x6a] = 'multiply', [0x6b] = 'add',      [0x6c] = 'separator',
	[0x6d] = 'subtract', [0x6e] = 'decimal',  [0x6f] = 'divide',   [0x70] = 'f1',       [0x71] = 'f2',
	[0x72] = 'f3',       [0x73] = 'f4',       [0x74] = 'f5',       [0x75] = 'f6',       [0x76] = 'f7',
	[0x77] = 'f8',       [0x78] = 'f9',       [0x79] = 'f10',      [0x7a] = 'f11',      [0x7b] = 'f12',
	[0x90] = 'numlock',  [0x91] = 'scrolllock',
	--varying by keyboard
	[0xba] = ';',        [0xbb] = '+',        [0xbc] = ',',        [0xbd] = '-',        [0xbe] = '.',
	[0xbf] = '/',        [0xc0] = '`',        [0xdb] = '[',        [0xdc] = '\\',       [0xdd] = ']',
	[0xde] = "'",
}

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

local dark_theme = {
	window_bg = {0,0,0,1},
	faint_bg  = {1,1,1,0.2},
	normal_bg = {1,1,1,0.3},
	normal_fg = {1,1,1,1},
	normal_border = {1,1,1,0.4},
	border_width = 1,
	hot_bg = {1,1,1,0.6},
	hot_fg = {1,1,1,1},
	selected_bg = {1,1,1,1},
	selected_fg = {0,0,0,1},
}

local player = {
	--window state
	w = panel.client_w,
	h = panel.client_h,   --client area size
	--mouse state
	mousex = 0,
	mousey = 0,           --mouse coords
	lbutton = false,      --mouse left button is pressed
	rbutton = false,      --mouse right button is pressed
	wheel_delta = 0,      --mouse wheel movement
	--keyboard state
	key = nil,            --key code
	char = nil,           --char code
	shift = false,        --shift key is pressed
	control = false,      --control key is pressed
	--UI styles
	theme = dark_theme,
	--event handler stubs
	on_render = function(self, cr) end,
}

--panel events for rendering and mouse

function panel:__create_surface(surface)
	player.cr = surface:create_context()
end

function panel:__destroy_surface(surface)
	player.cr:free()
	player.cr = nil
end

function panel:on_resized(...)
	CPanel.on_resized(self, ...)
	player.w = self.client_w
	player.h = self.client_h
end

local function fps_function()
	ffi.cdef'uint32_t GetTickCount();'
	local count_per_sec = 2
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

	player.cr:reset_clip()
	player:setcolor'window_bg'
	player.cr:paint()
	player.cr:identity_matrix()

	player:on_render(player.cr)
	player.key = nil
	player.char = nil
	player.shift = nil
	player.ctrl = nil
	player.alt = nil
	player.wheel_delta = 0
end

function panel:on_mouse_move(x, y, buttons, wheel_delta)
	player.mousex = x
	player.mousey = y
	player.lbutton = buttons.lbutton
	player.rbutton = buttons.rbutton
	player.wheel_delta = wheel_delta and wheel_delta / 120 or 0
	self:invalidate()
end

panel.on_mouse_over = panel.on_mouse_move
panel.on_mouse_leave = panel.on_mouse_move
panel.on_lbutton_double_click = panel.on_mouse_move
panel.on_lbutton_down = panel.on_mouse_move
panel.on_lbutton_up = panel.on_mouse_move
panel.on_rbutton_double_click = panel.on_mouse_move
panel.on_rbutton_down = panel.on_mouse_move
panel.on_rbutton_up = panel.on_mouse_move
main.on_mouse_wheel = panel.on_mouse_move

--main window events for keyboard

main.__wantallkeys = true --superhack

function main:WM_GETDLGCODE()
	return winapi.DLGC_WANTALLKEYS
end

function main:on_key_down(vk, flags)
	player.key =
		(((vk >= string.byte'0' and vk <= string.byte'9') or
		  (vk >= string.byte'A' and vk <= string.byte'Z'))
			and string.char(vk) or keynames[vk])
	player.shift = bit.band(ffi.C.GetKeyState(winapi.VK_SHIFT), 0x8000) ~= 0
	player.ctrl = bit.band(ffi.C.GetKeyState(winapi.VK_CONTROL), 0x8000) ~= 0
	player.alt = bit.band(ffi.C.GetKeyState(winapi.VK_MENU), 0x8000) ~= 0
	panel:invalidate()
end

main.on_syskey_down = main.on_key_down

function main:on_key_down_char(char, flags)
	local buf = ffi.new'uint8_t[16]'
	local sz = ffi.C.WideCharToMultiByte(winapi.CP_UTF8, 0, char, 1, buf, 16, nil, nil)
	assert(sz > 0)
	player.char = ffi.string(buf, sz)
	panel:invalidate()
end

main.on_syskey_down_char = main.on_key_down_char
main.on_dead_syskey_down_char = main.on_key_down_char

--player UI API

function player:hot(bx, by, bw, bh)
	return self.mousex >= bx and self.mousex <= bx + bw and self.mousey >= by and self.mousey <= by + bh
end

function player:setcolor(name)
	self.cr:set_source_rgba(unpack(self.theme[name]))
end

--submodule autoloader

local submodules = {
	editbox = 'cairo_player_editbox',
	vscrollbar = 'cairo_player_scrollbars',
	hscrollbar = 'cairo_player_scrollbars',
	scrollbox = 'cairo_player_scrollbars',
	button = 'cairo_player_buttons',
	mbutton = 'cairo_player_buttons',
	tabs = 'cairo_player_buttons',
}

setmetatable(player, {__index = function(_, k)
	if submodules[k] then
		require(submodules[k])
		return player[k]
	end
end})

--player user API

function player:play()
	main:show()
	panel:settimer(1, panel.invalidate) --render continuously
	return winapi.MessageLoop()
end


if not ... then require'cairo_player_ui_demo' end

return player
