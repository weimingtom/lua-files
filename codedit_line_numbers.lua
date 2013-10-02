--codedit line numbers margin
local margin = require'codedit_margin'
local glue = require'glue'

local ln_margin = glue.update({}, margin)

local function digits(n) --number of base-10 digits of a number
	return math.floor(math.log10(n) + 1)
end

function ln_margin:draw_line(line, x, y)
	local s = tostring(line)
	x = x - #s * self.editor.charsize
	self.editor:draw_text(x, y, s, self.text_color or 'line_number')
end

function ln_margin:get_width()
	return digits(self.editor.buffer:last_line()) * self.editor.charsize or 0
end

return ln_margin
