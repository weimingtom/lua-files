--PDCurses binding for PDCurses 3.4
local ffi = require'ffi'
local bit = require'bit'
require'pdcurses_h'

local C = ffi.load'pdcurses'
local C = setmetatable({C = C}, {__index = C})

local PDCurses = ffi.string(C.C.curses_version()):match'^PDCurses'

--curses.h macros

function C.MOUSE_X_POS() return (C.Mouse_status.x) end
function C.MOUSE_Y_POS() return (C.Mouse_status.y) end

function C.A_BUTTON_CHANGED() return (bit.band(C.Mouse_status.changes, 7))  ~= 0 end
function C.MOUSE_MOVED() return (bit.band(C.Mouse_status.changes, C.PDC_MOUSE_MOVED)) ~= 0 end
function C.MOUSE_POS_REPORT() return (bit.band(C.Mouse_status.changes, C.PDC_MOUSE_POSITION))  ~= 0 end
function C.BUTTON_CHANGED(x) return (bit.band(C.Mouse_status.changes, bit.lshift(1, (x - 1))))  ~= 0 end
function C.BUTTON_STATUS(x) return (C.Mouse_status.button[x - 1]) end
function C.MOUSE_WHEEL_UP() return (bit.band(C.Mouse_status.changes, C.PDC_MOUSE_WHEEL_UP)) ~= 0 end
function C.MOUSE_WHEEL_DOWN() return (bit.band(C.Mouse_status.changes, C.PDC_MOUSE_WHEEL_DOWN)) ~= 0 end

--cchar_t aliases

C.WACS_ULCORNER = C.acs_map[string.byte('l')]
C.WACS_LLCORNER = C.acs_map[string.byte('m')]
C.WACS_URCORNER = C.acs_map[string.byte('k')]
C.WACS_LRCORNER = C.acs_map[string.byte('j')]
C.WACS_RTEE = C.acs_map[string.byte('u')]
C.WACS_LTEE = C.acs_map[string.byte('t')]
C.WACS_BTEE = C.acs_map[string.byte('v')]
C.WACS_TTEE = C.acs_map[string.byte('w')]
C.WACS_HLINE = C.acs_map[string.byte('q')]
C.WACS_VLINE = C.acs_map[string.byte('x')]
C.WACS_PLUS = C.acs_map[string.byte('n')]

C.WACS_S1 = C.acs_map[string.byte('o')]
C.WACS_S9 = C.acs_map[string.byte('s')]
C.WACS_DIAMOND = C.acs_map[string.byte('`')]
C.WACS_CKBOARD = C.acs_map[string.byte('a')]
C.WACS_DEGREE = C.acs_map[string.byte('f')]
C.WACS_PLMINUS = C.acs_map[string.byte('g')]
C.WACS_BULLET = C.acs_map[string.byte('~')]

C.WACS_LARROW = C.acs_map[string.byte(',')]
C.WACS_RARROW = C.acs_map[string.byte('+')]
C.WACS_DARROW = C.acs_map[string.byte('.')]
C.WACS_UARROW = C.acs_map[string.byte('-')]
C.WACS_BOARD = C.acs_map[string.byte('h')]
C.WACS_LANTERN = C.acs_map[string.byte('i')]
C.WACS_BLOCK = C.acs_map[string.byte('0')]

C.WACS_S3 = C.acs_map[string.byte('p')]
C.WACS_S7 = C.acs_map[string.byte('r')]
C.WACS_LEQUAL = C.acs_map[string.byte('y')]
C.WACS_GEQUAL = C.acs_map[string.byte('z')]
C.WACS_PI = C.acs_map[string.byte('{')]
C.WACS_NEQUAL = C.acs_map[string.byte('|')]
C.WACS_STERLING = C.acs_map[string.byte('}')]

C.WACS_BSSB = C.WACS_ULCORNER
C.WACS_SSBB = C.WACS_LLCORNER
C.WACS_BBSS = C.WACS_URCORNER
C.WACS_SBBS = C.WACS_LRCORNER
C.WACS_SBSS = C.WACS_RTEE
C.WACS_SSSB = C.WACS_LTEE
C.WACS_SSBS = C.WACS_BTEE
C.WACS_BSSS = C.WACS_TTEE
C.WACS_BSBS = C.WACS_HLINE
C.WACS_SBSB = C.WACS_VLINE
C.WACS_SSSS = C.WACS_PLUS

if PDCurses then --PDCurses is BGR
	C.COLOR_BLUE = 1
	C.COLOR_GREEN = 2
	C.COLOR_RED = 4
else --ncurses is RGB
	C.COLOR_RED = 1
	C.COLOR_GREEN = 2
	C.COLOR_BLUE = 4
end
C.COLOR_CYAN = bit.bor(C.COLOR_BLUE, C.COLOR_GREEN)
C.COLOR_MAGENTA = bit.bor(C.COLOR_RED, C.COLOR_BLUE)
C.COLOR_YELLOW = bit.bor(C.COLOR_RED, C.COLOR_GREEN)

C.KEY_F = function(n) return (C.KEY_F0 + (n)) end

-- getch() and ungetch() conflict with some DOS libraries so we don't cdef them

C.getch = function() return C.wgetch(C.stdscr) end
C.ungetch = function(ch) return C.PDC_ungetch(ch) end

C.COLOR_PAIR = function(n)
	return bit.band(bit.lshift((chtype)(n), PDC_COLOR_SHIFT), A_COLOR)
end
C.PAIR_NUMBER = function(n)
	return bit.rshift(bit.band((n), A_COLOR), PDC_COLOR_SHIFT)
end

C.getbegyx = function(w) return getbegy(w), getbegx(w) end
C.getmaxyx = function(w) return getmaxy(w), getmaxx(w) end
C.getparyx = function(w) return getpary(w), getparx(w) end
C.getyx = function(w) return C.getcury(w), getcurx(w) end

C.getsyx = function()
	if C.curscr._leaveit then
		return -1, -1
	else
		return C.getyx(C.curscr, y, x)
	end
end

C.getmouse = C.nc_getmouse --ncurses version (use C.C.getmouse() for pdcurses version)

--Lua wrappers

C.curses_version = function() return ffi.string(C.C.curses_version()) end


if not ... then require'pdcurses_demo' end


return C

