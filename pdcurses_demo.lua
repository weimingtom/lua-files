--go@ x:/work/lua-files/bin/luajit-noredirect *
local c = require'pdcurses'
local ffi = require'ffi'

c.initscr()
c.cbreak() --make getch() return after the first char not after the first newline
c.noecho() --don't echo typed chars
c.keypad(c.stdscr, 1) --make getch() return KEY_MOUSE too

--curses keycodes. key codes for 0-9 and A-Z keys are ascii codes.
local keynames = {
	[0x08] = 'backspace',[0x09] = 'tab',      [0x0a] = 'return',   [0x10] = 'shift',    [0x11] = 'ctrl',
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

local ok, err = pcall(function()

--REPORT_MOUSE_POSITION

local event = ffi.new'MEVENT'

c.printw(c.curses_version()..'\n')
c.refresh()
local mask = c.mousemask(bit.bor(c.ALL_MOUSE_EVENTS, c.REPORT_MOUSE_POSITION), nil)
assert(bit.band(mask, c.REPORT_MOUSE_POSITION) ~= 0)

while true do
	local ch = c.getch()
	if ch == c.KEY_MOUSE then
		if c.getmouse(event) == 0 then
			c.move(event.y, event.x)
			c.printw(event.x .. ', ' .. event.y)
			c.refresh()
		end
	elseif ch == 27 then --Esc or Alt
		c.printw('esc\n')
		--don't wait for another key
		--if it was Alt then curses has already sent the other key
		--otherwise -1 is sent (Escape)
		c.nodelay(c.stdscr, 1)
		local n = c.getch()
		if n == -1 then
			--break
		else
			c.ungetch(ch)
		end
		c.nodelay(c.stdscr, 0)
	else
		c.printw((ch >= 0 and ch <= 255 and (keynames[ch] or string.char(ch)) or '?') .. ': ' .. tostring(ch)..'\n')
	end
end

end)

if not ok then
	c.printw(err)
	c.refresh()
end

c.getch()
c.endwin()
