--codedit block selection object: selecting vertically aligned text between two arbitrary cursor positions.
--line1,line2 are the horizontal boundaries and col1,col2 are the vertical boundaries of the rectangle.
local selection = require'codedit_selection'
local glue = require'glue'

local block_selection = {block = true}

--selection querying

block_selection.new = selection.new
block_selection.free = selection.free
block_selection.isempty = selection.isempty
block_selection.isforward = selection.isforward
block_selection.endpoints = selection.endpoints

--column range of one selection line
function block_selection:cols(line)
	return self.buffer:block_cols(line, self:endpoints())
end

block_selection.next_line = selection.next_line
block_selection.lines = selection.lines

--the range of lines that the selection covers
function block_selection:line_range()
	if self.line1 > self.line2 then
		return self.line2, self.line1
	else
		return self.line1, self.line2
	end
end

function block_selection:select()
	return self.buffer:select_block(self:endpoints())
end

block_selection.contents = selection.contents

--changing the selection

function block_selection:reset(line, col)
	line = math.min(math.max(line, 1), self.buffer:last_line())
	self.line1, self.col1 = line, col
	self.line2, self.col2 = self.line1, self.col1
end

function block_selection:extend(line, col)
	line = math.min(math.max(line, 1), self.buffer:last_line())
	self.line2, self.col2 = line, col
end

block_selection.set = selection.set
block_selection.reset_to_cursor = selection.reset_to_cursor
block_selection.extend_to_cursor = selection.extend_to_cursor
block_selection.set_to_selection = selection.set_to_selection

--selection-based editing

function block_selection:remove()
	self.buffer:remove_block(self:endpoints())
	self:reset(self.line1, self.col1)
end

--[[
function block_selection:indent(with_tabs)
	local line1, line2 = self:line_range()
	for line = line1, line2 do
		self.buffer:indent_block(line1, col1, line2, with_tabs)
	end
	self:set(line1, 1, line2 + 1, 1)
end

function selection:outdent()
	local line1, line2 = self:line_range()
	for line = line1, line2 do
		self.buffer:outdent_block(line)
	end
	self:set(line1, 1, line2 + 1, 1)
end

function selection:move_up()
	local line1, line2 = self:line_range()
	if line1 == 1 then
		return
	end
	for line = line1, line2 do
		self.buffer:move_line(line, line - 1)
	end
	self:set(line1 - 1, 1, line2 - 1 + 1, 1)
end

function selection:move_down()
	local line1, line2 = self:line_range()
	if line2 == self.buffer:last_line() then
		return
	end
	for line = line2, line1, -1 do
		self.buffer:move_line(line, line + 1)
	end
	self:set(line1 + 1, 1, line2 + 1 + 1, 1)
end
]]


if not ... then require'codedit_demo' end

return block_selection
