--cairo player: procedural graphics player with immediate mode gui toolkit
local CairoPanel = require'winapi.cairopanel'
local winapi = require'winapi'
require'winapi.messageloop'
require'winapi.vkcodes'
require'winapi.keyboard'
local cairo = require'cairo'
local ffi = require'ffi'
local glue = require'glue'

local player = {}

player.themes = {}

player.themes.dark = {
	window_bg = {0,0,0,1},
	faint_bg  = {1,1,1,0.2},
	normal_bg = {1,1,1,0.3},
	normal_fg = {1,1,1,1},
	normal_border = {1,1,1,0.4},
	hot_bg = {1,1,1,0.6},
	hot_fg = {0,0,0,1},
	selected_bg = {1,1,1,1},
	selected_fg = {0,0,0,1},
	disabled_bg = {1,1,1,0.3},
	disabled_fg = {.6,.6,.6,1},
	error_bg = {1,0,0,0.7},
	error_fg = {1,1,1,1},
}

player.themes.light = {
	window_bg = {1,1,1,1},
	faint_bg  = {0,0,0,0.2},
	normal_bg = {0,0,0,0.3},
	normal_fg = {0,0,0,1},
	normal_border = {0,0,0,0.4},
	hot_bg = {0,0,0,0.6},
	hot_fg = {1,1,1,1},
	selected_bg = {0,0,0,0.9},
	selected_fg = {1,1,1,1},
	disabled_bg = {0,0,0,0.3},
	disabled_fg = {0.4,0.4,0.4,1},
	error_bg = {1,0,0,0.7},
	error_fg = {1,1,1,1},
}

player.themes.red = glue.merge({
	normal_bg = {1,0,0,0.7},
	normal_fg = {1,1,1,1},
	normal_border = {1,1,1,0.4},
	hot_bg = {1,0,0,0.9},
	hot_fg = {1,1,1,1},
	selected_bg = {1,1,1,1},
	selected_fg = {0,0,0,1},
	disabled_bg = {1,0,0,0.7},
	disabled_fg = {.6,.6,.6,1},
}, player.themes.dark)

--winapi keycodes. key codes for 0-9 and A-Z keys are ascii codes.
local keynames = {
	[0x08] = 'backspace',[0x09] = 'tab',      [0x0d] = 'return',   [0x10] = 'shift',    [0x11] = 'ctrl',
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

local function keyname(vk)
	return
		(((vk >= string.byte'0' and vk <= string.byte'9') or
		(vk >= string.byte'A' and vk <= string.byte'Z'))
			and string.char(vk) or keynames[vk])
end

local keycodes = glue.index(keynames)

local function keycode(name)
	return keycodes[name] or string.byte(name)
end

local cursors = { --names are by function not shape when possible
	--pointers
	normal = winapi.IDC_ARROW,
	text = winapi.IDC_IBEAM,
	link = winapi.IDC_HAND,
	crosshair = winapi.IDC_CROSS,
	invalid = winapi.IDC_NO,
	--move and resize
	resize_nwse = winapi.IDC_SIZENWSE,
	resize_nesw = winapi.IDC_SIZENESW,
	resize_horizontal = winapi.IDC_SIZEWE,
	resize_vertical = winapi.IDC_SIZENS,
	move = winapi.IDC_SIZEALL,
	--app state
	busy = winapi.IDC_WAIT,
	background_busy = winapi.IDC_APPSTARTING,
}

local function set_cursor(name)
	winapi.SetCursor(winapi.LoadCursor(assert(cursors[name or 'normal'])))
end

ffi.cdef'uint32_t GetTickCount();'

local function fps_function()
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

local null_layout = {} --a null layout is a stateless layout that requires all box coordinates to be specified

function null_layout:getbox(t)
	return
		assert(t.x, 'x missing'),
		assert(t.y, 'y missing'),
		assert(t.w, 'w missing'),
		assert(t.h, 'h missing')
end

function player:window(t)

	local referer = self
	local self = setmetatable({}, {__index = player})

	local panel, window

	if not t.parent then --player has no parent window, so we make a standalone window for it
		window = winapi.Window{
			--if the window is created from the player class then it's the main window
			autoquit = referer == player and true,
			visible = false,
			x = t.x or 100,
			y = t.y or 100,
			w = t.w or 1300,
			h = t.h or 700,
		}
	elseif type(t.parent) == 'table' then --parent is a winapi.Window object
		window = t.parent
	else --parent is a HWND (window handle): wrap it into a winapi.BaseWindow object
		window = winapi.BaseWindow{hwnd = t.parent}
	end

	panel = CairoPanel{
		parent = window, w = window.client_w, h = window.client_h,
		anchors = {left=true, right=true, top=true, bottom=true}
	}

	self.window = window --needed by filebox
	self.panel = panel --needed by self.close

	--window state
	self.w = panel.client_w
	self.h = panel.client_h

	--mouse state (off screen, no buttons pressed)
	self.mousex = -1
	self.mousey = -1
	self.clicked = false       --left mouse button clicked (one-shot)
	self.rightclick = false    --right mouse button clicked (one-shot)
	self.doubleclicked = false --left mouse button double-clicked (one-shot)
	self.lbutton = false       --left mouse button pressed state
	self.rbutton = false       --right mouse button pressed state
	self.wheel_delta = 0       --mouse wheel movement as number of scroll pages (one-shot)

	--keyboard state (no key pressed)
	self.key = nil            --key pressed: key code (one-shot)
	self.char = nil           --key pressed: char code (one-shot)
	self.shift = false        --shift key pressed state (only if key ~= nil)
	self.ctrl = false         --ctrl key pressed state (only if key ~= nil)
	self.alt = false          --alt key pressed state (only if key ~= nil)

	--theme state
	self.theme = referer.theme or self.themes.dark

	--layout state
	self.layout = null_layout

	--widget state
	self.active = nil
	self.focused = nil
	self.ui = {}

	--panel receives painting and mouse events

	function panel.__create_surface(panel, surface)
		self.surface = surface
		self.cr = surface:create_context()
	end

	function panel.__destroy_surface(panel, surface)
		self.cr:free()
		self.surface = nil
		self.cr = nil
	end

	local fps = fps_function()

	function panel.on_render(panel, surface)
		--set the window title
		window.title = string.format('Cairo %s - %d fps', cairo.cairo_version_string(), fps())

		--set the window state
		self.w = panel.client_w
		self.h = panel.client_h

		--reset the graphics context
		self.cr:reset_clip()
		self.cr:identity_matrix()

		--paint the background
		self.cr:set_source_rgba(unpack(self.theme.window_bg))
		self.cr:paint()

		--set the wall clock
		self.clock = ffi.C.GetTickCount()

		--clear the cursor state
		self.cursor = nil

		--render the frame
		self:on_render(self.cr)

		--magnifier glass: so useful it's enabled by default
		if self:keypressed'ctrl' then
			self.cr:identity_matrix()
			self:magnifier{id = 'mag', x = self.mousex - 200, y = self.mousey - 100, w = 400, h = 200, zoom_level = 4}
		end

		--reset the one-shot state vars
		self.clicked = false
		self.rightclick = false
		self.doubleclicked = false
		self.key = nil
		self.char = nil
		self.shift = nil
		self.ctrl = nil
		self.alt = nil
		self.wheel_delta = 0
	end

	function panel.on_mouse_move(panel, x, y, buttons)
		self.mousex = x
		self.mousey = y
		self.lbutton = buttons.lbutton
		self.rbutton = buttons.rbutton
		panel:invalidate()
	end
	panel.on_mouse_over = panel.on_mouse_move
	panel.on_mouse_leave = panel.on_mouse_move

	function panel.on_lbutton_down(panel)
		winapi.SetCapture(panel.hwnd)
		self.lbutton = true
		self.clicked = false
		panel:invalidate()
	end

	function panel.on_lbutton_up()
		winapi.ReleaseCapture()
		self.lbutton = false
		self.clicked = true
		panel:invalidate()
	end

	function panel.on_rbutton_down()
		self.rbutton = true
		self.rightclick = false
		panel:invalidate()
	end

	function panel.on_rbutton_up()
		self.rbutton = false
		self.rightclick = true
		panel:invalidate()
	end

	function panel.on_lbutton_double_click()
		self.doubleclicked = true
		panel:invalidate()
	end

	function panel.on_set_cursor(_, _, ht)
		if ht == winapi.HTCLIENT then --we set our own cursor on the client area
			set_cursor(self.cursor)
			return true
		else
			return false
		end
	end

	--window receives keyboard and mouse wheel events

	function window.on_mouse_wheel(window, x, y, buttons, wheel_delta)
		self.wheel_delta = self.wheel_delta + (wheel_delta and wheel_delta / 120 or 0)
		panel:invalidate()
	end

	window.__wantallkeys = true --suppress TranslateMessage() that eats up our WM_CHARs

	function window:WM_GETDLGCODE()
		return winapi.DLGC_WANTALLKEYS
	end

	function window.on_key_down(window, vk, flags)
		self.key = keyname(vk)
		self.shift = bit.band(ffi.C.GetKeyState(winapi.VK_SHIFT), 0x8000) ~= 0
		self.ctrl = bit.band(ffi.C.GetKeyState(winapi.VK_CONTROL), 0x8000) ~= 0
		self.alt = bit.band(ffi.C.GetKeyState(winapi.VK_MENU), 0x8000) ~= 0
		panel:invalidate()
	end

	window.on_syskey_down = window.on_key_down

	function window.on_key_down_char(window, char, flags)
		local buf = ffi.new'uint8_t[16]'
		local sz = ffi.C.WideCharToMultiByte(winapi.CP_UTF8, 0, char, 1, buf, 16, nil, nil)
		assert(sz > 0)
		self.char = ffi.string(buf, sz)
		panel:invalidate()
	end

	window.on_syskey_down_char = window.on_key_down_char
	window.on_dead_syskey_down_char = window.on_key_down_char

	--set panel to render continuously
	panel:settimer(1, panel.invalidate)

	window:show()

	return self
end

--theme-aware api

local function hexcolor(s)
	if s:sub(1,1) ~= '#' then return end
	local r,g,b,a = tonumber(s:sub(2,3), 16), tonumber(s:sub(4,5), 16),
						 tonumber(s:sub(6,7), 16), tonumber(s:sub(8,9), 16) or 255
	return {r/255, g/255, b/255, a/255}
end

function player:setcolor(color)
	color = assert(self.theme[color] or hexcolor(color), 'invalid color')
	self.cr:set_source_rgba(unpack(color))
end

function player:fill(color)
	self:setcolor(color or 'normal_bg')
	self.cr:fill()
end

function player:stroke(color, line_width)
	self:setcolor(color or 'normal_fg')
	self.cr:set_line_width(line_width or 1)
	self.cr:stroke()
end

function player:fillstroke(fill_color, stroke_color, line_width)
	if fill_color and stroke_color then
		self:setcolor(fill_color)
		self.cr:fill_preserve()
		self:stroke(stroke_color, line_width)
	elseif fill_color then
		self:fill(fill_color)
	elseif stroke_color then
		self:stroke(stroke_color, line_width)
	else
		self:fill('normal_bg')
	end
end

function player:save_theme(theme)
	local old_theme = self.theme
	self.theme = theme or self.theme
	return old_theme
end

--graphics helpers

function player:dot(x, y, r, ...)
	self:rect(x-r, y-r, 2*r, 2*r, ...)
end

function player:rect(x, y, w, h, ...)
	self.cr:rectangle(x, y, w, h)
	self:fillstroke(...)
end

function player:circle(x, y, r, ...)
	self.cr:circle(x, y, r)
	self:fillstroke(...)
end

function player:line(x1, y1, x2, y2, ...)
	self.cr:move_to(x1, y1)
	self.cr:line_to(x2, y2)
	self:stroke(...)
end

function player:curve(x1, y1, x2, y2, x3, y3, x4, y4, ...)
	self.cr:move_to(x1, y1)
	self.cr:curve_to(x2, y2, x3, y3, x4, y4)
	self:stroke(...)
end


local function aligntext(cr, text, font_size, halign, valign, x, y, w, h)
	cr:set_font_size(font_size)
	local extents = cr:text_extents(text)
	cr:move_to(
		halign == 'center' and (2 * x + w - extents.width) / 2 or
		halign == 'left'   and x or
		halign == 'right'  and x + w - extents.width,
		valign == 'middle' and (2 * y + h - extents.y_bearing) / 2 or
		valign == 'top'    and y + extents.height or
		valign == 'bottom' and y + h)
end

function player:text_path(text, font_size, halign, valign, x, y, w, h)
	aligntext(self.cr, text, font_size, halign, valign, x, y, w, h)
	self.cr:text_path(text)
end

function player:text(text, font_size, color, halign, valign, x, y, w, h)
	aligntext(self.cr, text, font_size, halign, valign, x, y, w, h)
	self:setcolor(color)
	self.cr:show_text(text)
end

--layout api

function player:getbox(t)
	return self.layout:getbox(t)
end

--mouse helpers

function player:hotbox(x, y, w, h)
	local mx, my = self.cr:device_to_user(self.mousex, self.mousey)
	return self.cr:in_clip(mx, my) and mx >= x and mx <= x + w and my >= y and my <= y + h
end

--keyboard helpers

function player:keypressed(keyname)
	return bit.band(ffi.C.GetAsyncKeyState(keycode(keyname)), 0x8000) ~= 0
end

--submodule autoloader

glue.autoload(player, {
	editbox      = 'cplayer.editbox',
	vscrollbar   = 'cplayer.scrollbars',
	hscrollbar   = 'cplayer.scrollbars',
	scrollbox    = 'cplayer.scrollbars',
	button       = 'cplayer.buttons',
	mbutton      = 'cplayer.buttons',
	togglebutton = 'cplayer.buttons',
	tabs         = 'cplayer.buttons',
	slider       = 'cplayer.slider',
	menu         = 'cplayer.menu',
	combobox     = 'cplayer.combobox',
	filebox      = 'cplayer.filebox',
	grid         = 'cplayer.grid',
	treeview     = 'cplayer.treeview',
	magnifier    = 'cplayer.magnifier',
	vsplitter    = 'cplayer.splitter',
	hsplitter    = 'cplayer.splitter',
	image        = 'cplayer.image',
	label        = 'cplayer.label',
	dragpoint    = 'cplayer.dragpoint',
	dragpoints   = 'cplayer.dragpoint',
})

--main loop

function player:play(...)
	if ... then --player loaded as module, return it instead of running it
		return player
	end
	self.main = self:window{on_render = self.on_render}
	return winapi.MessageLoop()
end

if not ... then require'cairo_player_demo' end

return player
