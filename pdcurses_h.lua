--curses.h from PDCurses 3.4
local ffi = require'ffi'
require'stdio_h'

ffi.cdef[[
//    XCURSES         True if compiling for X11.
//    PDC_RGB         True if you want to use RGB color definitions
//                    (Red = 1, Green = 2, Blue = 4) instead of BGR.
//    PDC_WIDE        True if building wide-character support.
//    NCURSES_MOUSE_VERSION   Use the ncurses mouse API instead
//                            of PDCurses' traditional mouse API.

typedef unsigned long chtype;  /* 16-bit attr + 16-bit char */
typedef chtype cchar_t;
typedef chtype attr_t;

/*----------------------------------------------------------------------
 *
 *  PDCurses Mouse Interface -- SYSVR4, with extensions
 *
 */

typedef struct
{
	int x;           /* absolute column, 0 based, measured in characters */
	int y;           /* absolute row, 0 based, measured in characters */
	short button[3]; /* state of each button */
	int changes;     /* flags indicating what has changed with the mouse */
} MOUSE_STATUS;

enum {
	BUTTON_RELEASED = 0x0000,
	BUTTON_PRESSED = 0x0001,
	BUTTON_CLICKED = 0x0002,
	BUTTON_DOUBLE_CLICKED = 0x0003,
	BUTTON_TRIPLE_CLICKED = 0x0004,
	BUTTON_MOVED = 0x0005, /* PDCurses */
	WHEEL_SCROLLED = 0x0006, /* PDCurses */
	BUTTON_ACTION_MASK = 0x0007, /* PDCurses */

	PDC_BUTTON_SHIFT = 0x0008, /* PDCurses */
	PDC_BUTTON_CONTROL = 0x0010, /* PDCurses */
	PDC_BUTTON_ALT = 0x0020, /* PDCurses */
	BUTTON_MODIFIER_MASK = 0x0038, /* PDCurses */
};

/*
 * Bits associated with the .changes field:
 *   3         2         1         0
 * 210987654321098765432109876543210
 *                                 1 <- button 1 has changed
 *                                10 <- button 2 has changed
 *                               100 <- button 3 has changed
 *                              1000 <- mouse has moved
 *                             10000 <- mouse position report
 *                            100000 <- mouse wheel up
 *                           1000000 <- mouse wheel down
 */

enum {
	PDC_MOUSE_MOVED = 0x0008,
	PDC_MOUSE_POSITION = 0x0010,
	PDC_MOUSE_WHEEL_UP = 0x0020,
	PDC_MOUSE_WHEEL_DOWN = 0x0040,
};

/* mouse bit-masks */

enum {
	BUTTON1_RELEASED = 0x00000001L,
	BUTTON1_PRESSED = 0x00000002L,
	BUTTON1_CLICKED = 0x00000004L,
	BUTTON1_DOUBLE_CLICKED = 0x00000008L,
	BUTTON1_TRIPLE_CLICKED = 0x00000010L,
	BUTTON1_MOVED = 0x00000010L, /* PDCurses */

	BUTTON2_RELEASED = 0x00000020L,
	BUTTON2_PRESSED = 0x00000040L,
	BUTTON2_CLICKED = 0x00000080L,
	BUTTON2_DOUBLE_CLICKED = 0x00000100L,
	BUTTON2_TRIPLE_CLICKED = 0x00000200L,
	BUTTON2_MOVED = 0x00000200L, /* PDCurses */

	BUTTON3_RELEASED = 0x00000400L,
	BUTTON3_PRESSED = 0x00000800L,
	BUTTON3_CLICKED = 0x00001000L,
	BUTTON3_DOUBLE_CLICKED = 0x00002000L,
	BUTTON3_TRIPLE_CLICKED = 0x00004000L,
	BUTTON3_MOVED = 0x00004000L, /* PDCurses */

/* For the ncurses-compatible functions only, BUTTON4_PRESSED and
   BUTTON5_PRESSED are returned for mouse scroll wheel up and down;
   otherwise PDCurses doesn't support buttons 4 and 5 */

	BUTTON4_RELEASED = 0x00008000L,
	BUTTON4_PRESSED = 0x00010000L,
	BUTTON4_CLICKED = 0x00020000L,
	BUTTON4_DOUBLE_CLICKED = 0x00040000L,
	BUTTON4_TRIPLE_CLICKED = 0x00080000L,

	BUTTON5_RELEASED = 0x00100000L,
	BUTTON5_PRESSED = 0x00200000L,
	BUTTON5_CLICKED = 0x00400000L,
	BUTTON5_DOUBLE_CLICKED = 0x00800000L,
	BUTTON5_TRIPLE_CLICKED = 0x01000000L,

	MOUSE_WHEEL_SCROLL = 0x02000000L, /* PDCurses */
	BUTTON_MODIFIER_SHIFT = 0x04000000L, /* PDCurses */
	BUTTON_MODIFIER_CONTROL = 0x08000000L, /* PDCurses */
	BUTTON_MODIFIER_ALT = 0x10000000L, /* PDCurses */

	ALL_MOUSE_EVENTS = 0x1fffffffL,
	REPORT_MOUSE_POSITION = 0x20000000L,
};

/* ncurses mouse interface */

typedef unsigned long mmask_t;

typedef struct
{
	short id;       /* unused, always 0 */
	int x, y, z;    /* x, y same as MOUSE_STATUS; z unused */
	mmask_t bstate; /* equivalent to changes + button[], but
						   in the same format as used for mousemask() */
} MEVENT;

enum {
//#ifdef NCURSES_MOUSE_VERSION
	BUTTON_SHIFT = BUTTON_MODIFIER_SHIFT,
	BUTTON_CONTROL = BUTTON_MODIFIER_CONTROL,
	BUTTON_CTRL = BUTTON_MODIFIER_CONTROL,
	BUTTON_ALT = BUTTON_MODIFIER_ALT,
/*
#else
	BUTTON_SHIFT = PDC_BUTTON_SHIFT,
	BUTTON_CONTROL = PDC_BUTTON_CONTROL,
	BUTTON_ALT = PDC_BUTTON_ALT,
#endif
*/
};

/*----------------------------------------------------------------------
 *
 *  PDCurses Structure Definitions
 *
 */

typedef struct _win       /* definition of a window */
{
	int   _cury;          /* current pseudo-cursor */
	int   _curx;
	int   _maxy;          /* max window coordinates */
	int   _maxx;
	int   _begy;          /* origin on screen */
	int   _begx;
	int   _flags;         /* window properties */
	chtype _attrs;        /* standard attributes and colors */
	chtype _bkgd;         /* background, normally blank */
	bool  _clear;         /* causes clear at next refresh */
	bool  _leaveit;       /* leaves cursor where it is */
	bool  _scroll;        /* allows window scrolling */
	bool  _nodelay;       /* input character wait flag */
	bool  _immed;         /* immediate update flag */
	bool  _sync;          /* synchronise window ancestors */
	bool  _use_keypad;    /* flags keypad key mode active */
	chtype **_y;          /* pointer to line pointer array */
	int   *_firstch;      /* first changed character in line */
	int   *_lastch;       /* last changed character in line */
	int   _tmarg;         /* top of scrolling region */
	int   _bmarg;         /* bottom of scrolling region */
	int   _delayms;       /* milliseconds of delay for getch() */
	int   _parx, _pary;   /* coords relative to parent (0,0) */
	struct _win *_parent; /* subwin's pointer to parent win */
} WINDOW;

/* Avoid using the SCREEN struct directly -- use the corresponding
   functions if possible. This struct may eventually be made private. */

typedef struct
{
	bool  alive;          /* if initscr() called, and not endwin() */
	bool  autocr;         /* if cr -> lf */
	bool  cbreak;         /* if terminal unbuffered */
	bool  echo;           /* if terminal echo */
	bool  raw_inp;        /* raw input mode (v. cooked input) */
	bool  raw_out;        /* raw output mode (7 v. 8 bits) */
	bool  audible;        /* FALSE if the bell is visual */
	bool  mono;           /* TRUE if current screen is mono */
	bool  resized;        /* TRUE if TERM has been resized */
	bool  orig_attr;      /* TRUE if we have the original colors */
	short orig_fore;      /* original screen foreground color */
	short orig_back;      /* original screen foreground color */
	int   cursrow;        /* position of physical cursor */
	int   curscol;        /* position of physical cursor */
	int   visibility;     /* visibility of cursor */
	int   orig_cursor;    /* original cursor size */
	int   lines;          /* new value for LINES */
	int   cols;           /* new value for COLS */
	unsigned long _trap_mbe;       /* trap these mouse button events */
	unsigned long _map_mbe_to_key; /* map mouse buttons to slk */
	int   mouse_wait;              /* time to wait (in ms) for a
									  button release after a press, in
									  order to count it as a click */
	int   slklines;                /* lines in use by slk_init() */
	WINDOW *slk_winptr;            /* window for slk */
	int   linesrippedoff;          /* lines ripped off via ripoffline() */
	int   linesrippedoffontop;     /* lines ripped off on
									  top via ripoffline() */
	int   delaytenths;             /* 1/10ths second to wait block
									  getch() for */
	bool  _preserve;               /* TRUE if screen background
									  to be preserved */
	int   _restore;                /* specifies if screen background
									  to be restored, and how */
	bool  save_key_modifiers;      /* TRUE if each key modifiers saved
									  with each key press */
	bool  return_key_modifiers;    /* TRUE if modifier keys are
									  returned as "real" keys */
	bool  key_code;                /* TRUE if last key is a special key;
									  used internally by get_wch() */
//#ifdef XCURSES
	int   XcurscrSize;    /* size of Xcurscr shared memory block */
	bool  sb_on;
	int   sb_viewport_y;
	int   sb_viewport_x;
	int   sb_total_y;
	int   sb_total_x;
	int   sb_cur_y;
	int   sb_cur_x;
//#endif
	short line_color;     /* color of line attributes - default -1 */
} SCREEN;

/*----------------------------------------------------------------------
 *
 *  PDCurses External Variables
 *
 */

int          LINES;        /* terminal height */
int          COLS;         /* terminal width */
WINDOW       *stdscr;      /* the default screen window */
WINDOW       *curscr;      /* the current screen image */
SCREEN       *SP;          /* curses variables */
MOUSE_STATUS Mouse_status;
int          COLORS;
int          COLOR_PAIRS;
int          TABSIZE;
chtype       acs_map[];    /* alternate character set map */
char         ttytype[];    /* terminal name/description */

/*man-start**************************************************************

PDCurses Text Attributes
========================

Originally, PDCurses used a short (16 bits) for its chtype. To include
color, a number of things had to be sacrificed from the strict Unix and
System V support. The main problem was fitting all character attributes
and color into an unsigned char (all 8 bits!).

Today, PDCurses by default uses a long (32 bits) for its chtype, as in
System V. The short chtype is still available, by undefining CHTYPE_LONG
and rebuilding the library.

The following is the structure of a win->_attrs chtype:

short form:

-------------------------------------------------
|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3| 2| 1| 0|
-------------------------------------------------
  color number |  attrs |   character eg 'a'

The available non-color attributes are bold, reverse and blink. Others
have no effect. The high order char is an index into an array of
physical colors (defined in color.c) -- 32 foreground/background color
pairs (5 bits) plus 3 bits for other attributes.

long form:

----------------------------------------------------------------------------
|31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|15|14|13|12|..| 3| 2| 1| 0|
----------------------------------------------------------------------------
	  color number      |     modifiers         |      character eg 'a'

The available non-color attributes are bold, underline, invisible,
right-line, left-line, protect, reverse and blink. 256 color pairs (8
bits), 8 bits for other attributes, and 16 bits for character data.

**man-end****************************************************************/

/*** Video attribute macros ***/

enum {
	A_NORMAL = (chtype)0,

	A_ALTCHARSET = (chtype)0x00010000,
	A_RIGHTLINE = (chtype)0x00020000,
	A_LEFTLINE = (chtype)0x00040000,
	A_INVIS = (chtype)0x00080000,
	A_UNDERLINE = (chtype)0x00100000,
	A_REVERSE = (chtype)0x00200000,
	A_BLINK = (chtype)0x00400000,
	A_BOLD = (chtype)0x00800000,

	A_ATTRIBUTES = (chtype)0xffff0000,
	A_CHARTEXT = (chtype)0x0000ffff,
	A_COLOR = (chtype)0xff000000,

	A_ITALIC = A_INVIS,
	A_PROTECT = (A_UNDERLINE | A_LEFTLINE | A_RIGHTLINE),

	PDC_ATTR_SHIFT = 19,
	PDC_COLOR_SHIFT = 24,

	A_STANDOUT = (A_REVERSE | A_BOLD), /* X/Open */
	A_DIM = A_NORMAL,

	CHR_MSK = A_CHARTEXT, /* Obsolete */
	ATR_MSK = A_ATTRIBUTES, /* Obsolete */
	ATR_NRM = A_NORMAL, /* Obsolete */

	/* For use with attr_t -- X/Open says, "these shall be distinct", so
		this is a non-conforming implementation. */

	WA_ALTCHARSET = A_ALTCHARSET,
	WA_BLINK = A_BLINK,
	WA_BOLD = A_BOLD,
	WA_DIM = A_DIM,
	WA_INVIS = A_INVIS,
	WA_LEFT = A_LEFTLINE,
	WA_PROTECT = A_PROTECT,
	WA_REVERSE = A_REVERSE,
	WA_RIGHT = A_RIGHTLINE,
	WA_STANDOUT = A_STANDOUT,
	WA_UNDERLINE = A_UNDERLINE,

	WA_HORIZONTAL = A_NORMAL,
	WA_LOW = A_NORMAL,
	WA_TOP = A_NORMAL,
	WA_VERTICAL = A_NORMAL,
};

/*** Alternate character set macros ***/

/* 'w' = 32-bit chtype; acs_map[] index | A_ALTCHARSET
   'n' = 16-bit chtype; it gets the fallback set because no bit is
		 available for A_ALTCHARSET */

/* VT100-compatible symbols -- box chars */

enum {
	ACS_ULCORNER = (chtype)'l' | A_ALTCHARSET,
	ACS_LLCORNER = (chtype)'m' | A_ALTCHARSET,
	ACS_URCORNER = (chtype)'k' | A_ALTCHARSET,
	ACS_LRCORNER = (chtype)'j' | A_ALTCHARSET,
	ACS_RTEE = (chtype)'u' | A_ALTCHARSET,
	ACS_LTEE = (chtype)'t' | A_ALTCHARSET,
	ACS_BTEE = (chtype)'v' | A_ALTCHARSET,
	ACS_TTEE = (chtype)'w' | A_ALTCHARSET,
	ACS_HLINE = (chtype)'q' | A_ALTCHARSET,
	ACS_VLINE = (chtype)'x' | A_ALTCHARSET,
	ACS_PLUS = (chtype)'n' | A_ALTCHARSET,

	/* VT100-compatible symbols -- other */

	ACS_S1 = (chtype)'o' | A_ALTCHARSET,
	ACS_S9 = (chtype)'s' | A_ALTCHARSET,
	ACS_DIAMOND = (chtype)'`' | A_ALTCHARSET,
	ACS_CKBOARD = (chtype)'a' | A_ALTCHARSET,
	ACS_DEGREE = (chtype)'f' | A_ALTCHARSET,
	ACS_PLMINUS = (chtype)'g' | A_ALTCHARSET,
	ACS_BULLET = (chtype)'~' | A_ALTCHARSET,

	/* Teletype 5410v1 symbols -- these are defined in SysV curses, but
		are not well-supported by most terminals. Stick to VT100 characters
		for optimum portability. */

	ACS_LARROW = (chtype)',' | A_ALTCHARSET,
	ACS_RARROW = (chtype)'+' | A_ALTCHARSET,
	ACS_DARROW = (chtype)'.' | A_ALTCHARSET,
	ACS_UARROW = (chtype)'-' | A_ALTCHARSET,
	ACS_BOARD = (chtype)'h' | A_ALTCHARSET,
	ACS_LANTERN = (chtype)'i' | A_ALTCHARSET,
	ACS_BLOCK = (chtype)'0' | A_ALTCHARSET,

	/* That goes double for these -- undocumented SysV symbols. Don't use
		them. */

	ACS_S3 = (chtype)'p' | A_ALTCHARSET,
	ACS_S7 = (chtype)'r' | A_ALTCHARSET,
	ACS_LEQUAL = (chtype)'y' | A_ALTCHARSET,
	ACS_GEQUAL = (chtype)'z' | A_ALTCHARSET,
	ACS_PI = (chtype)'{' | A_ALTCHARSET,
	ACS_NEQUAL = (chtype)'|' | A_ALTCHARSET,
	ACS_STERLING = (chtype)'}' | A_ALTCHARSET,

	/* Box char aliases */

	ACS_BSSB = ACS_ULCORNER,
	ACS_SSBB = ACS_LLCORNER,
	ACS_BBSS = ACS_URCORNER,
	ACS_SBBS = ACS_LRCORNER,
	ACS_SBSS = ACS_RTEE,
	ACS_SSSB = ACS_LTEE,
	ACS_SSBS = ACS_BTEE,
	ACS_BSSS = ACS_TTEE,
	ACS_BSBS = ACS_HLINE,
	ACS_SBSB = ACS_VLINE,
	ACS_SSSS = ACS_PLUS,
};

/* cchar_t aliases */

// based on acs_map, done in Lua

/*** Color macros ***/

enum {
	COLOR_BLACK = 0,
	COLOR_WHITE = 7,
	// PDCurses is BGR, ncurses is RGB, so other colors are selectable at runtime
};

/*----------------------------------------------------------------------
 *
 *  Function and Keypad Key Definitions.
 *  Many are just for compatibility.
 *
 */

enum {
	KEY_CODE_YES = 0x100, /* If get_wch() gives a key code */

	KEY_BREAK = 0x101, /* Not on PC KBD */
	KEY_DOWN = 0x102, /* Down arrow key */
	KEY_UP = 0x103, /* Up arrow key */
	KEY_LEFT = 0x104, /* Left arrow key */
	KEY_RIGHT = 0x105, /* Right arrow key */
	KEY_HOME = 0x106, /* home key */
	KEY_BACKSPACE = 0x107, /* not on pc */
	KEY_F0 = 0x108, /* function keys; 64 reserved */

	KEY_DL = 0x148, /* delete line */
	KEY_IL = 0x149, /* insert line */
	KEY_DC = 0x14a, /* delete character */
	KEY_IC = 0x14b, /* insert char or enter ins mode */
	KEY_EIC = 0x14c, /* exit insert char mode */
	KEY_CLEAR = 0x14d, /* clear screen */
	KEY_EOS = 0x14e, /* clear to end of screen */
	KEY_EOL = 0x14f, /* clear to end of line */
	KEY_SF = 0x150, /* scroll 1 line forward */
	KEY_SR = 0x151, /* scroll 1 line back (reverse) */
	KEY_NPAGE = 0x152, /* next page */
	KEY_PPAGE = 0x153, /* previous page */
	KEY_STAB = 0x154, /* set tab */
	KEY_CTAB = 0x155, /* clear tab */
	KEY_CATAB = 0x156, /* clear all tabs */
	KEY_ENTER = 0x157, /* enter or send (unreliable) */
	KEY_SRESET = 0x158, /* soft/reset (partial/unreliable) */
	KEY_RESET = 0x159, /* reset/hard reset (unreliable) */
	KEY_PRINT = 0x15a, /* print/copy */
	KEY_LL = 0x15b, /* home down/bottom (lower left) */
	KEY_ABORT = 0x15c, /* abort/terminate key (any) */
	KEY_SHELP = 0x15d, /* short help */
	KEY_LHELP = 0x15e, /* long help */
	KEY_BTAB = 0x15f, /* Back tab key */
	KEY_BEG = 0x160, /* beg(inning) key */
	KEY_CANCEL = 0x161, /* cancel key */
	KEY_CLOSE = 0x162, /* close key */
	KEY_COMMAND = 0x163, /* cmd (command) key */
	KEY_COPY = 0x164, /* copy key */
	KEY_CREATE = 0x165, /* create key */
	KEY_END = 0x166, /* end key */
	KEY_EXIT = 0x167, /* exit key */
	KEY_FIND = 0x168, /* find key */
	KEY_HELP = 0x169, /* help key */
	KEY_MARK = 0x16a, /* mark key */
	KEY_MESSAGE = 0x16b, /* message key */
	KEY_MOVE = 0x16c, /* move key */
	KEY_NEXT = 0x16d, /* next object key */
	KEY_OPEN = 0x16e, /* open key */
	KEY_OPTIONS = 0x16f, /* options key */
	KEY_PREVIOUS = 0x170, /* previous object key */
	KEY_REDO = 0x171, /* redo key */
	KEY_REFERENCE = 0x172, /* ref(erence) key */
	KEY_REFRESH = 0x173, /* refresh key */
	KEY_REPLACE = 0x174, /* replace key */
	KEY_RESTART = 0x175, /* restart key */
	KEY_RESUME = 0x176, /* resume key */
	KEY_SAVE = 0x177, /* save key */
	KEY_SBEG = 0x178, /* shifted beginning key */
	KEY_SCANCEL = 0x179, /* shifted cancel key */
	KEY_SCOMMAND = 0x17a, /* shifted command key */
	KEY_SCOPY = 0x17b, /* shifted copy key */
	KEY_SCREATE = 0x17c, /* shifted create key */
	KEY_SDC = 0x17d, /* shifted delete char key */
	KEY_SDL = 0x17e, /* shifted delete line key */
	KEY_SELECT = 0x17f, /* select key */
	KEY_SEND = 0x180, /* shifted end key */
	KEY_SEOL = 0x181, /* shifted clear line key */
	KEY_SEXIT = 0x182, /* shifted exit key */
	KEY_SFIND = 0x183, /* shifted find key */
	KEY_SHOME = 0x184, /* shifted home key */
	KEY_SIC = 0x185, /* shifted input key */

	KEY_SLEFT = 0x187, /* shifted left arrow key */
	KEY_SMESSAGE = 0x188, /* shifted message key */
	KEY_SMOVE = 0x189, /* shifted move key */
	KEY_SNEXT = 0x18a, /* shifted next key */
	KEY_SOPTIONS = 0x18b, /* shifted options key */
	KEY_SPREVIOUS = 0x18c, /* shifted prev key */
	KEY_SPRINT = 0x18d, /* shifted print key */
	KEY_SREDO = 0x18e, /* shifted redo key */
	KEY_SREPLACE = 0x18f, /* shifted replace key */
	KEY_SRIGHT = 0x190, /* shifted right arrow */
	KEY_SRSUME = 0x191, /* shifted resume key */
	KEY_SSAVE = 0x192, /* shifted save key */
	KEY_SSUSPEND = 0x193, /* shifted suspend key */
	KEY_SUNDO = 0x194, /* shifted undo key */
	KEY_SUSPEND = 0x195, /* suspend key */
	KEY_UNDO = 0x196, /* undo key */

	/* PDCurses-specific key definitions -- PC only */

	ALT_0 = 0x197,
	ALT_1 = 0x198,
	ALT_2 = 0x199,
	ALT_3 = 0x19a,
	ALT_4 = 0x19b,
	ALT_5 = 0x19c,
	ALT_6 = 0x19d,
	ALT_7 = 0x19e,
	ALT_8 = 0x19f,
	ALT_9 = 0x1a0,
	ALT_A = 0x1a1,
	ALT_B = 0x1a2,
	ALT_C = 0x1a3,
	ALT_D = 0x1a4,
	ALT_E = 0x1a5,
	ALT_F = 0x1a6,
	ALT_G = 0x1a7,
	ALT_H = 0x1a8,
	ALT_I = 0x1a9,
	ALT_J = 0x1aa,
	ALT_K = 0x1ab,
	ALT_L = 0x1ac,
	ALT_M = 0x1ad,
	ALT_N = 0x1ae,
	ALT_O = 0x1af,
	ALT_P = 0x1b0,
	ALT_Q = 0x1b1,
	ALT_R = 0x1b2,
	ALT_S = 0x1b3,
	ALT_T = 0x1b4,
	ALT_U = 0x1b5,
	ALT_V = 0x1b6,
	ALT_W = 0x1b7,
	ALT_X = 0x1b8,
	ALT_Y = 0x1b9,
	ALT_Z = 0x1ba,

	CTL_LEFT = 0x1bb, /* Control-Left-Arrow */
	CTL_RIGHT = 0x1bc,
	CTL_PGUP = 0x1bd,
	CTL_PGDN = 0x1be,
	CTL_HOME = 0x1bf,
	CTL_END = 0x1c0,

	KEY_A1 = 0x1c1, /* upper left on Virtual keypad */
	KEY_A2 = 0x1c2, /* upper middle on Virt. keypad */
	KEY_A3 = 0x1c3, /* upper right on Vir. keypad */
	KEY_B1 = 0x1c4, /* middle left on Virt. keypad */
	KEY_B2 = 0x1c5, /* center on Virt. keypad */
	KEY_B3 = 0x1c6, /* middle right on Vir. keypad */
	KEY_C1 = 0x1c7, /* lower left on Virt. keypad */
	KEY_C2 = 0x1c8, /* lower middle on Virt. keypad */
	KEY_C3 = 0x1c9, /* lower right on Vir. keypad */

	PADSLASH = 0x1ca, /* slash on keypad */
	PADENTER = 0x1cb, /* enter on keypad */
	CTL_PADENTER = 0x1cc, /* ctl-enter on keypad */
	ALT_PADENTER = 0x1cd, /* alt-enter on keypad */
	PADSTOP = 0x1ce, /* stop on keypad */
	PADSTAR = 0x1cf, /* star on keypad */
	PADMINUS = 0x1d0, /* minus on keypad */
	PADPLUS = 0x1d1, /* plus on keypad */
	CTL_PADSTOP = 0x1d2, /* ctl-stop on keypad */
	CTL_PADCENTER = 0x1d3, /* ctl-enter on keypad */
	CTL_PADPLUS = 0x1d4, /* ctl-plus on keypad */
	CTL_PADMINUS = 0x1d5, /* ctl-minus on keypad */
	CTL_PADSLASH = 0x1d6, /* ctl-slash on keypad */
	CTL_PADSTAR = 0x1d7, /* ctl-star on keypad */
	ALT_PADPLUS = 0x1d8, /* alt-plus on keypad */
	ALT_PADMINUS = 0x1d9, /* alt-minus on keypad */
	ALT_PADSLASH = 0x1da, /* alt-slash on keypad */
	ALT_PADSTAR = 0x1db, /* alt-star on keypad */
	ALT_PADSTOP = 0x1dc, /* alt-stop on keypad */
	CTL_INS = 0x1dd, /* ctl-insert */
	ALT_DEL = 0x1de, /* alt-delete */
	ALT_INS = 0x1df, /* alt-insert */
	CTL_UP = 0x1e0, /* ctl-up arrow */
	CTL_DOWN = 0x1e1, /* ctl-down arrow */
	CTL_TAB = 0x1e2, /* ctl-tab */
	ALT_TAB = 0x1e3,
	ALT_MINUS = 0x1e4,
	ALT_EQUAL = 0x1e5,
	ALT_HOME = 0x1e6,
	ALT_PGUP = 0x1e7,
	ALT_PGDN = 0x1e8,
	ALT_END = 0x1e9,
	ALT_UP = 0x1ea, /* alt-up arrow */
	ALT_DOWN = 0x1eb, /* alt-down arrow */
	ALT_RIGHT = 0x1ec, /* alt-right arrow */
	ALT_LEFT = 0x1ed, /* alt-left arrow */
	ALT_ENTER = 0x1ee, /* alt-enter */
	ALT_ESC = 0x1ef, /* alt-escape */
	ALT_BQUOTE = 0x1f0, /* alt-back quote */
	ALT_LBRACKET = 0x1f1, /* alt-left bracket */
	ALT_RBRACKET = 0x1f2, /* alt-right bracket */
	ALT_SEMICOLON = 0x1f3, /* alt-semi-colon */
	ALT_FQUOTE = 0x1f4, /* alt-forward quote */
	ALT_COMMA = 0x1f5, /* alt-comma */
	ALT_STOP = 0x1f6, /* alt-stop */
	ALT_FSLASH = 0x1f7, /* alt-forward slash */
	ALT_BKSP = 0x1f8, /* alt-backspace */
	CTL_BKSP = 0x1f9, /* ctl-backspace */
	PAD0 = 0x1fa, /* keypad 0 */

	CTL_PAD0 = 0x1fb, /* ctl-keypad 0 */
	CTL_PAD1 = 0x1fc,
	CTL_PAD2 = 0x1fd,
	CTL_PAD3 = 0x1fe,
	CTL_PAD4 = 0x1ff,
	CTL_PAD5 = 0x200,
	CTL_PAD6 = 0x201,
	CTL_PAD7 = 0x202,
	CTL_PAD8 = 0x203,
	CTL_PAD9 = 0x204,

	ALT_PAD0 = 0x205, /* alt-keypad 0 */
	ALT_PAD1 = 0x206,
	ALT_PAD2 = 0x207,
	ALT_PAD3 = 0x208,
	ALT_PAD4 = 0x209,
	ALT_PAD5 = 0x20a,
	ALT_PAD6 = 0x20b,
	ALT_PAD7 = 0x20c,
	ALT_PAD8 = 0x20d,
	ALT_PAD9 = 0x20e,

	CTL_DEL = 0x20f, /* clt-delete */
	ALT_BSLASH = 0x210, /* alt-back slash */
	CTL_ENTER = 0x211, /* ctl-enter */

	SHF_PADENTER = 0x212, /* shift-enter on keypad */
	SHF_PADSLASH = 0x213, /* shift-slash on keypad */
	SHF_PADSTAR = 0x214, /* shift-star  on keypad */
	SHF_PADPLUS = 0x215, /* shift-plus  on keypad */
	SHF_PADMINUS = 0x216, /* shift-minus on keypad */
	SHF_UP = 0x217, /* shift-up on keypad */
	SHF_DOWN = 0x218, /* shift-down on keypad */
	SHF_IC = 0x219, /* shift-insert on keypad */
	SHF_DC = 0x21a, /* shift-delete on keypad */

	KEY_MOUSE = 0x21b, /* "mouse" key */
	KEY_SHIFT_L = 0x21c, /* Left-shift */
	KEY_SHIFT_R = 0x21d, /* Right-shift */
	KEY_CONTROL_L = 0x21e, /* Left-control */
	KEY_CONTROL_R = 0x21f, /* Right-control */
	KEY_ALT_L = 0x220, /* Left-alt */
	KEY_ALT_R = 0x221, /* Right-alt */
	KEY_RESIZE = 0x222, /* Window resize */
	KEY_SUP = 0x223, /* Shifted up arrow */
	KEY_SDOWN = 0x224, /* Shifted down arrow */

	KEY_MIN = KEY_BREAK, /* Minimum curses key value */
	KEY_MAX = KEY_SDOWN, /* Maximum curses key */
};

/*----------------------------------------------------------------------
 *
 *  PDCurses Function Declarations
 *
 */

/* Standard */

int     addch(const chtype);
int     addchnstr(const chtype *, int);
int     addchstr(const chtype *);
int     addnstr(const char *, int);
int     addstr(const char *);
int     attroff(chtype);
int     attron(chtype);
int     attrset(chtype);
int     attr_get(attr_t *, short *, void *);
int     attr_off(attr_t, void *);
int     attr_on(attr_t, void *);
int     attr_set(attr_t, short, void *);
int     baudrate(void);
int     beep(void);
int     bkgd(chtype);
void    bkgdset(chtype);
int     border(chtype, chtype, chtype, chtype, chtype, chtype, chtype, chtype);
int     box(WINDOW *, chtype, chtype);
bool    can_change_color(void);
int     cbreak(void);
int     chgat(int, attr_t, short, const void *);
int     clearok(WINDOW *, bool);
int     clear(void);
int     clrtobot(void);
int     clrtoeol(void);
int     color_content(short, short *, short *, short *);
int     color_set(short, void *);
int     copywin(const WINDOW *, WINDOW *, int, int, int, int, int, int, int);
int     curs_set(int);
int     def_prog_mode(void);
int     def_shell_mode(void);
int     delay_output(int);
int     delch(void);
int     deleteln(void);
void    delscreen(SCREEN *);
int     delwin(WINDOW *);
WINDOW *derwin(WINDOW *, int, int, int, int);
int     doupdate(void);
WINDOW *dupwin(WINDOW *);
int     echochar(const chtype);
int     echo(void);
int     endwin(void);
char    erasechar(void);
int     erase(void);
void    filter(void);
int     flash(void);
int     flushinp(void);
chtype  getbkgd(WINDOW *);
int     getnstr(char *, int);
int     getstr(char *);
WINDOW *getwin(FILE *);
int     halfdelay(int);
bool    has_colors(void);
bool    has_ic(void);
bool    has_il(void);
int     hline(chtype, int);
void    idcok(WINDOW *, bool);
int     idlok(WINDOW *, bool);
void    immedok(WINDOW *, bool);
int     inchnstr(chtype *, int);
int     inchstr(chtype *);
chtype  inch(void);
int     init_color(short, short, short, short);
int     init_pair(short, short, short);
WINDOW *initscr(void);
int     innstr(char *, int);
int     insch(chtype);
int     insdelln(int);
int     insertln(void);
int     insnstr(const char *, int);
int     insstr(const char *);
int     instr(char *);
int     intrflush(WINDOW *, bool);
bool    isendwin(void);
bool    is_linetouched(WINDOW *, int);
bool    is_wintouched(WINDOW *);
char   *keyname(int);
int     keypad(WINDOW *, bool);
char    killchar(void);
int     leaveok(WINDOW *, bool);
char   *longname(void);
int     meta(WINDOW *, bool);
int     move(int, int);
int     mvaddch(int, int, const chtype);
int     mvaddchnstr(int, int, const chtype *, int);
int     mvaddchstr(int, int, const chtype *);
int     mvaddnstr(int, int, const char *, int);
int     mvaddstr(int, int, const char *);
int     mvchgat(int, int, int, attr_t, short, const void *);
int     mvcur(int, int, int, int);
int     mvdelch(int, int);
int     mvderwin(WINDOW *, int, int);
int     mvgetch(int, int);
int     mvgetnstr(int, int, char *, int);
int     mvgetstr(int, int, char *);
int     mvhline(int, int, chtype, int);
chtype  mvinch(int, int);
int     mvinchnstr(int, int, chtype *, int);
int     mvinchstr(int, int, chtype *);
int     mvinnstr(int, int, char *, int);
int     mvinsch(int, int, chtype);
int     mvinsnstr(int, int, const char *, int);
int     mvinsstr(int, int, const char *);
int     mvinstr(int, int, char *);
int     mvprintw(int, int, const char *, ...);
int     mvscanw(int, int, const char *, ...);
int     mvvline(int, int, chtype, int);
int     mvwaddchnstr(WINDOW *, int, int, const chtype *, int);
int     mvwaddchstr(WINDOW *, int, int, const chtype *);
int     mvwaddch(WINDOW *, int, int, const chtype);
int     mvwaddnstr(WINDOW *, int, int, const char *, int);
int     mvwaddstr(WINDOW *, int, int, const char *);
int     mvwchgat(WINDOW *, int, int, int, attr_t, short, const void *);
int     mvwdelch(WINDOW *, int, int);
int     mvwgetch(WINDOW *, int, int);
int     mvwgetnstr(WINDOW *, int, int, char *, int);
int     mvwgetstr(WINDOW *, int, int, char *);
int     mvwhline(WINDOW *, int, int, chtype, int);
int     mvwinchnstr(WINDOW *, int, int, chtype *, int);
int     mvwinchstr(WINDOW *, int, int, chtype *);
chtype  mvwinch(WINDOW *, int, int);
int     mvwinnstr(WINDOW *, int, int, char *, int);
int     mvwinsch(WINDOW *, int, int, chtype);
int     mvwinsnstr(WINDOW *, int, int, const char *, int);
int     mvwinsstr(WINDOW *, int, int, const char *);
int     mvwinstr(WINDOW *, int, int, char *);
int     mvwin(WINDOW *, int, int);
int     mvwprintw(WINDOW *, int, int, const char *, ...);
int     mvwscanw(WINDOW *, int, int, const char *, ...);
int     mvwvline(WINDOW *, int, int, chtype, int);
int     napms(int);
WINDOW *newpad(int, int);
SCREEN *newterm(const char *, FILE *, FILE *);
WINDOW *newwin(int, int, int, int);
int     nl(void);
int     nocbreak(void);
int     nodelay(WINDOW *, bool);
int     noecho(void);
int     nonl(void);
void    noqiflush(void);
int     noraw(void);
int     notimeout(WINDOW *, bool);
int     overlay(const WINDOW *, WINDOW *);
int     overwrite(const WINDOW *, WINDOW *);
int     pair_content(short, short *, short *);
int     pechochar(WINDOW *, chtype);
int     pnoutrefresh(WINDOW *, int, int, int, int, int, int);
int     prefresh(WINDOW *, int, int, int, int, int, int);
int     printw(const char *, ...);
int     putwin(WINDOW *, FILE *);
void    qiflush(void);
int     raw(void);
int     redrawwin(WINDOW *);
int     refresh(void);
int     reset_prog_mode(void);
int     reset_shell_mode(void);
int     resetty(void);
int     ripoffline(int, int (*)(WINDOW *, int));
int     savetty(void);
int     scanw(const char *, ...);
int     scr_dump(const char *);
int     scr_init(const char *);
int     scr_restore(const char *);
int     scr_set(const char *);
int     scrl(int);
int     scroll(WINDOW *);
int     scrollok(WINDOW *, bool);
SCREEN *set_term(SCREEN *);
int     setscrreg(int, int);
int     slk_attroff(const chtype);
int     slk_attr_off(const attr_t, void *);
int     slk_attron(const chtype);
int     slk_attr_on(const attr_t, void *);
int     slk_attrset(const chtype);
int     slk_attr_set(const attr_t, short, void *);
int     slk_clear(void);
int     slk_color(short);
int     slk_init(int);
char   *slk_label(int);
int     slk_noutrefresh(void);
int     slk_refresh(void);
int     slk_restore(void);
int     slk_set(int, const char *, int);
int     slk_touch(void);
int     standend(void);
int     standout(void);
int     start_color(void);
WINDOW *subpad(WINDOW *, int, int, int, int);
WINDOW *subwin(WINDOW *, int, int, int, int);
int     syncok(WINDOW *, bool);
chtype  termattrs(void);
attr_t  term_attrs(void);
char   *termname(void);
void    timeout(int);
int     touchline(WINDOW *, int, int);
int     touchwin(WINDOW *);
int     typeahead(int);
int     untouchwin(WINDOW *);
void    use_env(bool);
int     vidattr(chtype);
int     vid_attr(attr_t, short, void *);
int     vidputs(chtype, int (*)(int));
int     vid_puts(attr_t, short, void *, int (*)(int));
int     vline(chtype, int);
int     vw_printw(WINDOW *, const char *, va_list);
int     vwprintw(WINDOW *, const char *, va_list);
int     vw_scanw(WINDOW *, const char *, va_list);
int     vwscanw(WINDOW *, const char *, va_list);
int     waddchnstr(WINDOW *, const chtype *, int);
int     waddchstr(WINDOW *, const chtype *);
int     waddch(WINDOW *, const chtype);
int     waddnstr(WINDOW *, const char *, int);
int     waddstr(WINDOW *, const char *);
int     wattroff(WINDOW *, chtype);
int     wattron(WINDOW *, chtype);
int     wattrset(WINDOW *, chtype);
int     wattr_get(WINDOW *, attr_t *, short *, void *);
int     wattr_off(WINDOW *, attr_t, void *);
int     wattr_on(WINDOW *, attr_t, void *);
int     wattr_set(WINDOW *, attr_t, short, void *);
void    wbkgdset(WINDOW *, chtype);
int     wbkgd(WINDOW *, chtype);
int     wborder(WINDOW *, chtype, chtype, chtype, chtype,
				chtype, chtype, chtype, chtype);
int     wchgat(WINDOW *, int, attr_t, short, const void *);
int     wclear(WINDOW *);
int     wclrtobot(WINDOW *);
int     wclrtoeol(WINDOW *);
int     wcolor_set(WINDOW *, short, void *);
void    wcursyncup(WINDOW *);
int     wdelch(WINDOW *);
int     wdeleteln(WINDOW *);
int     wechochar(WINDOW *, const chtype);
int     werase(WINDOW *);
int     wgetch(WINDOW *);
int     wgetnstr(WINDOW *, char *, int);
int     wgetstr(WINDOW *, char *);
int     whline(WINDOW *, chtype, int);
int     winchnstr(WINDOW *, chtype *, int);
int     winchstr(WINDOW *, chtype *);
chtype  winch(WINDOW *);
int     winnstr(WINDOW *, char *, int);
int     winsch(WINDOW *, chtype);
int     winsdelln(WINDOW *, int);
int     winsertln(WINDOW *);
int     winsnstr(WINDOW *, const char *, int);
int     winsstr(WINDOW *, const char *);
int     winstr(WINDOW *, char *);
int     wmove(WINDOW *, int, int);
int     wnoutrefresh(WINDOW *);
int     wprintw(WINDOW *, const char *, ...);
int     wredrawln(WINDOW *, int, int);
int     wrefresh(WINDOW *);
int     wscanw(WINDOW *, const char *, ...);
int     wscrl(WINDOW *, int);
int     wsetscrreg(WINDOW *, int, int);
int     wstandend(WINDOW *);
int     wstandout(WINDOW *);
void    wsyncdown(WINDOW *);
void    wsyncup(WINDOW *);
void    wtimeout(WINDOW *, int);
int     wtouchln(WINDOW *, int, int, int);
int     wvline(WINDOW *, chtype, int);

/* Wide-character functions */

int     addnwstr(const wchar_t *, int);
int     addwstr(const wchar_t *);
int     add_wch(const cchar_t *);
int     add_wchnstr(const cchar_t *, int);
int     add_wchstr(const cchar_t *);
int     border_set(const cchar_t *, const cchar_t *, const cchar_t *,
				   const cchar_t *, const cchar_t *, const cchar_t *,
				   const cchar_t *, const cchar_t *);
int     box_set(WINDOW *, const cchar_t *, const cchar_t *);
int     echo_wchar(const cchar_t *);
int     erasewchar(wchar_t *);
int     getbkgrnd(cchar_t *);
int     getcchar(const cchar_t *, wchar_t *, attr_t *, short *, void *);
int     getn_wstr(wint_t *, int);
int     get_wch(wint_t *);
int     get_wstr(wint_t *);
int     hline_set(const cchar_t *, int);
int     innwstr(wchar_t *, int);
int     ins_nwstr(const wchar_t *, int);
int     ins_wch(const cchar_t *);
int     ins_wstr(const wchar_t *);
int     inwstr(wchar_t *);
int     in_wch(cchar_t *);
int     in_wchnstr(cchar_t *, int);
int     in_wchstr(cchar_t *);
char   *key_name(wchar_t);
int     killwchar(wchar_t *);
int     mvaddnwstr(int, int, const wchar_t *, int);
int     mvaddwstr(int, int, const wchar_t *);
int     mvadd_wch(int, int, const cchar_t *);
int     mvadd_wchnstr(int, int, const cchar_t *, int);
int     mvadd_wchstr(int, int, const cchar_t *);
int     mvgetn_wstr(int, int, wint_t *, int);
int     mvget_wch(int, int, wint_t *);
int     mvget_wstr(int, int, wint_t *);
int     mvhline_set(int, int, const cchar_t *, int);
int     mvinnwstr(int, int, wchar_t *, int);
int     mvins_nwstr(int, int, const wchar_t *, int);
int     mvins_wch(int, int, const cchar_t *);
int     mvins_wstr(int, int, const wchar_t *);
int     mvinwstr(int, int, wchar_t *);
int     mvin_wch(int, int, cchar_t *);
int     mvin_wchnstr(int, int, cchar_t *, int);
int     mvin_wchstr(int, int, cchar_t *);
int     mvvline_set(int, int, const cchar_t *, int);
int     mvwaddnwstr(WINDOW *, int, int, const wchar_t *, int);
int     mvwaddwstr(WINDOW *, int, int, const wchar_t *);
int     mvwadd_wch(WINDOW *, int, int, const cchar_t *);
int     mvwadd_wchnstr(WINDOW *, int, int, const cchar_t *, int);
int     mvwadd_wchstr(WINDOW *, int, int, const cchar_t *);
int     mvwgetn_wstr(WINDOW *, int, int, wint_t *, int);
int     mvwget_wch(WINDOW *, int, int, wint_t *);
int     mvwget_wstr(WINDOW *, int, int, wint_t *);
int     mvwhline_set(WINDOW *, int, int, const cchar_t *, int);
int     mvwinnwstr(WINDOW *, int, int, wchar_t *, int);
int     mvwins_nwstr(WINDOW *, int, int, const wchar_t *, int);
int     mvwins_wch(WINDOW *, int, int, const cchar_t *);
int     mvwins_wstr(WINDOW *, int, int, const wchar_t *);
int     mvwin_wch(WINDOW *, int, int, cchar_t *);
int     mvwin_wchnstr(WINDOW *, int, int, cchar_t *, int);
int     mvwin_wchstr(WINDOW *, int, int, cchar_t *);
int     mvwinwstr(WINDOW *, int, int, wchar_t *);
int     mvwvline_set(WINDOW *, int, int, const cchar_t *, int);
int     pecho_wchar(WINDOW *, const cchar_t*);
int     setcchar(cchar_t*, const wchar_t*, const attr_t, short, const void*);
int     slk_wset(int, const wchar_t *, int);
int     unget_wch(const wchar_t);
int     vline_set(const cchar_t *, int);
int     waddnwstr(WINDOW *, const wchar_t *, int);
int     waddwstr(WINDOW *, const wchar_t *);
int     wadd_wch(WINDOW *, const cchar_t *);
int     wadd_wchnstr(WINDOW *, const cchar_t *, int);
int     wadd_wchstr(WINDOW *, const cchar_t *);
int     wbkgrnd(WINDOW *, const cchar_t *);
void    wbkgrndset(WINDOW *, const cchar_t *);
int     wborder_set(WINDOW *, const cchar_t *, const cchar_t *,
					const cchar_t *, const cchar_t *, const cchar_t *,
					const cchar_t *, const cchar_t *, const cchar_t *);
int     wecho_wchar(WINDOW *, const cchar_t *);
int     wgetbkgrnd(WINDOW *, cchar_t *);
int     wgetn_wstr(WINDOW *, wint_t *, int);
int     wget_wch(WINDOW *, wint_t *);
int     wget_wstr(WINDOW *, wint_t *);
int     whline_set(WINDOW *, const cchar_t *, int);
int     winnwstr(WINDOW *, wchar_t *, int);
int     wins_nwstr(WINDOW *, const wchar_t *, int);
int     wins_wch(WINDOW *, const cchar_t *);
int     wins_wstr(WINDOW *, const wchar_t *);
int     winwstr(WINDOW *, wchar_t *);
int     win_wch(WINDOW *, cchar_t *);
int     win_wchnstr(WINDOW *, cchar_t *, int);
int     win_wchstr(WINDOW *, cchar_t *);
wchar_t *wunctrl(cchar_t *);
int     wvline_set(WINDOW *, const cchar_t *, int);

/* Quasi-standard */

chtype  getattrs(WINDOW *);
int     getbegx(WINDOW *);
int     getbegy(WINDOW *);
int     getmaxx(WINDOW *);
int     getmaxy(WINDOW *);
int     getparx(WINDOW *);
int     getpary(WINDOW *);
int     getcurx(WINDOW *);
int     getcury(WINDOW *);
void    traceoff(void);
void    traceon(void);
char   *unctrl(chtype);

int     crmode(void);
int     nocrmode(void);
int     draino(int);
int     resetterm(void);
int     fixterm(void);
int     saveterm(void);
int     setsyx(int, int);

int     mouse_set(unsigned long);
int     mouse_on(unsigned long);
int     mouse_off(unsigned long);
int     request_mouse_pos(void);
int     map_button(unsigned long);
void    wmouse_position(WINDOW *, int *, int *);
unsigned long getmouse(void);
unsigned long getbmap(void);

/* ncurses */

int     assume_default_colors(int, int);
const char *curses_version(void);
bool    has_key(int);
int     use_default_colors(void);
int     wresize(WINDOW *, int, int);

int     mouseinterval(int);
mmask_t mousemask(mmask_t, mmask_t *);
bool    mouse_trafo(int *, int *, bool);
int     nc_getmouse(MEVENT *);
int     ungetmouse(MEVENT *);
bool    wenclose(const WINDOW *, int, int);
bool    wmouse_trafo(const WINDOW *, int *, int *, bool);

/* PDCurses */

int     addrawch(chtype);
int     insrawch(chtype);
bool    is_termresized(void);
int     mvaddrawch(int, int, chtype);
int     mvdeleteln(int, int);
int     mvinsertln(int, int);
int     mvinsrawch(int, int, chtype);
int     mvwaddrawch(WINDOW *, int, int, chtype);
int     mvwdeleteln(WINDOW *, int, int);
int     mvwinsertln(WINDOW *, int, int);
int     mvwinsrawch(WINDOW *, int, int, chtype);
int     raw_output(bool);
int     resize_term(int, int);
WINDOW *resize_window(WINDOW *, int, int);
int     waddrawch(WINDOW *, chtype);
int     winsrawch(WINDOW *, chtype);
char    wordchar(void);

wchar_t *slk_wlabel(int);

void    PDC_debug(const char *, ...);
int     PDC_ungetch(int);
int     PDC_set_blink(bool);
int     PDC_set_line_color(short);
void    PDC_set_title(const char *);

int     PDC_clearclipboard(void);
int     PDC_freeclipboard(char *);
int     PDC_getclipboard(char **, long *);
int     PDC_setclipboard(const char *, long);

unsigned long PDC_get_input_fd(void);
unsigned long PDC_get_key_modifiers(void);
int     PDC_return_key_modifiers(bool);
int     PDC_save_key_modifiers(bool);

WINDOW *Xinitscr(int, char **);
void    XCursesExit(void);
int     sb_init(void);
int     sb_set_horz(int, int, int);
int     sb_set_vert(int, int, int);
int     sb_get_horz(int *, int *, int *);
int     sb_get_vert(int *, int *, int *);
int     sb_refresh(void);

/* return codes from PDC_getclipboard() and PDC_setclipboard() calls */

enum {
	PDC_CLIP_SUCCESS = 0,
	PDC_CLIP_ACCESS_ERROR = 1,
	PDC_CLIP_EMPTY = 2,
	PDC_CLIP_MEMORY_ERROR = 3,
};

/* PDCurses key modifier masks */

enum {
	PDC_KEY_MODIFIER_SHIFT = 1,
	PDC_KEY_MODIFIER_CONTROL = 2,
	PDC_KEY_MODIFIER_ALT = 4,
	PDC_KEY_MODIFIER_NUMLOCK = 8,
};

]]
