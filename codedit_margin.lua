--codedit margins
local glue = require'glue'

local margin = {
	side = 'left', --left, right
	w = 50,
	background_color = nil, --custom color
	text_color = nil, --custom color
}

function margin:new(buffer, view, t, pos)
	self = glue.inherit(t or {
		buffer = buffer,
		view = view,
	}, self)
	self.view:add_margin(self)
	return self
end

function margin:get_width()
	return self.w
end

function margin:draw_line(line, x, y, w) end --stub

function margin:hit_test(x, y)
	return self.view:margin_hit_test(self, x, y)
end

return margin

