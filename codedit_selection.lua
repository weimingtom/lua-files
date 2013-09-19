--codedit selection: selecting contiguous text between two line,col pairs.
--line1,col1 is the first selected char and line2,col2 is the char immediately after the last selected char.
local editor = require'codedit_editor'
local glue = require'glue'

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

editor.selection = {
	color = nil, --color override
}

function editor:create_selection(visible)
	return self.selection:new(self, visible)
end

local selection = editor.selection

function selection:new(editor, visible)
	self = glue.inherit({editor = editor, visible = visible}, self)
	self:reset(1, 1)
	self.editor.selections[self] = true
	return self
end

function selection:free()
	self.editor.selections[self] = nil
end

function selection:isempty()
	return self.line2 == self.line1 and self.col2 == self.col1
end

local function clamp_pos(self, line, col) --self = editor
	if line < 1 then
		return 1, 1
	elseif line > self:last_line() then
		return self:last_line(), self:last_col(self:last_line()) + 1
	else
		return line, clamp(col, 1, self:last_col(line) + 1)
	end
end

--empty and re-anchor the selection
function selection:reset(line, col)
	line, col = clamp_pos(self.editor, line, col)
	self.anchor_line, self.anchor_col = line, col
	self.line1, self.col1 = line, col
	self.line2, self.col2 = line, col
end

--move selection's free endpoint
function selection:move(line, col)
	local line1, col1 = self.anchor_line, self.anchor_col
	local line2, col2 = line, col
	--switch cursors if the end cursor is before the start cursor
	if line2 < line1 then
		line2, line1 = line1, line2
		col2, col1 = col1, col2
	elseif line2 == line1 and col2 < col1 then
		col2, col1 = col1, col2
	end
	--restrict selection boundaries to the available text
	self.line1, self.col1 = clamp_pos(self.editor, line1, col1)
	self.line2, self.col2 = clamp_pos(self.editor, line2, col2)
end

function selection:cols(line)
	local col1 = line == self.line1 and self.col1 or 1
	local col2 = line == self.line2 and self.col2 or self.editor:last_col(line) + 1
	return col1, col2
end

function selection:next_line(line)
	line = line and line + 1 or self.line1
	if line > self.line2 then
		return
	end
	return line, self:cols(line)
end

function selection:lines()
	return self.next_line, self
end

function selection:select()
	return self.editor:select_string(self.line1, self.col1, self.line2, self.col2)
end

function selection:contents()
	return self.editor:contents(self:select())
end

function selection:remove()
	if self:isempty() then return end
	self.editor:remove_string(self.line1, self.col1, self.line2, self.col2)
	self:reset(self.line1, self.col1)
end

--expand the selection to contain first and last lines fully
function selection:expand_to_full_lines()
	local line1, line2, col2 = self.line1, self.line2, self.col2
	self:reset(line1, 1)
	self:move(line2 + (col2 == 1 and 0 or 1), 1)
end

function selection:indent(with_tabs)
	self:expand_to_full_lines()
	for line = self.line1, self.line2-1 do
		self.editor:indent(line, with_tabs)
	end
end

function selection:outdent()
	self:expand_to_full_lines()
	for line = self.line1, self.line2-1 do
		self.editor:outdent(line)
	end
end

if not ... then require'codedit_demo' end

