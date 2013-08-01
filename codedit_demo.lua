local codedit = require'codedit'
local player = require'cairo_player'

local s = [[
A	BB	C
AA	B	C
AAA	BB	C
function lines.pos(s, lnum)
	if lnum < 1 then return end
	local n = 0
	for _, i, j in lines.lines(s) do
		n = n + 1
		if n == lnum then return i, j end
	end
end
]]

local v = codedit.view:new{id = 'view', x = 200, y = 10, w = 300, h = 150}
local b = codedit.buffer:new{string = s}
local c = codedit.cursor:new{buffer = b, view = v}

function player:on_render(cr)

	--c.restrict_eol = false
	--c.restrict_eof = false

	v.tabsize = self:slider{id = 'tabsize', x = 10, y = 10, w = 80, h = 24, i0 = 1, i1 = 8, i = v.tabsize}
	v.linesize = self:slider{id = 'linesize', x = 10, y = 40, w = 80, h = 24, i0 = 10, i1 = 30, i = v.linesize}
	b.line_terminator = self:mbutton{id = 'term', x = 10, y = 70, w = 80, h = 24,
		values = {'\r\n', '\r', '\n'}, texts = {['\r\n'] = 'CRLF', ['\n'] = 'LF', ['\r'] = 'CR'},
		selected = b.line_terminator}

	c:keypress(self.key, self.char, self.ctrl, self.shift)

	--v:render_selection(codedit.selection:new{buffer = b, line1 = 2, line2 = 2, col1 = 2, col2 = 0}, self)
	v:render_selection(c.selection, self)
	v:render_buffer(b, self)
	v:render_cursor(c, self)

end

player:play()

