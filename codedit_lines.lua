--codedit line-based interface to the internal line buffer
local editor = require'codedit_editor'

function editor:getline(line)
	return self.lines[line]
end

function editor:last_line()
	return #self.lines
end

function editor:contents(lines)
	return table.concat(lines or self.lines, self.line_terminator)
end

function editor:insert_line(line, s)
	table.insert(self.lines, line, s)
	self:undo_command('remove_line', line)
	self.dirty = true
	self.changed = true
end

function editor:remove_line(line)
	local s = table.remove(self.lines, line)
	self:undo_command('insert_line', line, s)
	self.dirty = true
	self.changed = true
	return s
end

function editor:setline(line, s)
	self:undo_command('setline', line, self:getline(line))
	self.lines[line] = s
	self.dirty = true
	self.changed = true
end

