local codedit = require'codedit'
local player = require'cairo_player'

local v = codedit.view:new{x = 200, y = 10, w = 300, h = 150}
local b = codedit.buffer:new()
local e = codedit.editor:new{id = 'view', buffer = b, view = v}

b:load[[
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

function player:on_render(cr)

	--e.cursor.restrict_eol = false
	--e.cursor.restrict_eof = false

	v.smooth_vscroll = true
	v.smooth_hscroll = true

	v.tabsize = self:slider{id = 'tabsize', x = 10, y = 10, w = 80, h = 24, i0 = 1, i1 = 8, i = v.tabsize}
	v.linesize = self:slider{id = 'linesize', x = 10, y = 40, w = 80, h = 24, i0 = 10, i1 = 30, i = v.linesize}
	b.line_terminator = self:mbutton{id = 'term', x = 10, y = 70, w = 80, h = 24,
		values = {'\r\n', '\r', '\n'}, texts = {['\r\n'] = 'CRLF', ['\n'] = 'LF', ['\r'] = 'CR'},
		selected = b.line_terminator}
	v.eol_markers = self:togglebutton{id = 'eol markers', x = 10, y = 100, w = 80, h = 24, selected = v.eol_markers}

	e:render(self)

end

player:play()

