--codedit main class
local glue = require'glue'
local str = require'codedit_str'

local editor = {
	line_terminator = nil, --line terminator to use when saving. nil means autodetect.
	line_numbers = true,
}

function editor:new(options)
	self = glue.inherit(options or {}, self)
	local text = self.text or ''
	self.line_terminator = self.line_terminator or self:detect_line_terminator(text)
	self.lines = {''} --can't have zero lines
	self:insert_string(1, 1, text)
	self.changed = false
	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil
	self.selections = {} --{selections = true, ...}
	self.cursors = {} --{cursor = true, ...}
	self.cursor = self:create_cursor(true)
	self.scroll_x = 0
	self.scroll_y = 0
	self.margins = {} --{margin1, ...}
	if self.line_numbers then
		self:create_line_numbers_margin()
	end
	return self
end

if not ... then require'codedit_demo' end

return editor

