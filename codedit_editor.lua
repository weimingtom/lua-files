--codedit main class
local glue = require'glue'
local str = require'codedit_str'

local editor = {
	line_terminator = nil, --line terminator to use when saving. nil means autodetect.
	line_numbers = true,
}

function editor:new(options)
	self = glue.inherit(options or {}, self)

	--line buffer
	local text = self.text or ''
	self.line_terminator = self.line_terminator or self:detect_line_terminator(text)
	self.lines = {''} --can't have zero lines
	self.changed = {} --{flag = nil/true/false}; all flags are set to true whenever the buffer changes.
	self:insert_string(1, 1, text)
	self.changed.file = true

	--undo
	self.undo_stack = {}
	self.redo_stack = {}
	self.undo_group = nil

	--rendering
	self.selections = {} --{selections = true, ...}
	self.cursors = {} --{cursor = true, ...}

	--cursor
	self.cursor = self:create_cursor(true)

	--scrolling
	self.scroll_x = 0
	self.scroll_y = 0

	--margins
	self.margins = {} --{margin1, ...}
	if self.line_numbers then
		self:create_line_numbers_margin()
	end

	return self
end

if not ... then require'codedit_demo' end

return editor

