--codedit undo/redo command stack
local editor = require'codedit_editor'

function editor:start_undo_group()
	if self.undo_group then
		self:end_undo_group()
	end
	self.undo_group = {commands = {}}
end

function editor:end_undo_group()
	if #self.undo_group.commands > 0 then
		table.insert(self.undo_stack, self.undo_group)
	end
	self.undo_group = nil
end

function editor:undo_command(...)
	if not self.undo_group then return end
	table.insert(self.undo_group.commands, {...})
end

function editor:undo()
	local group = table.remove(self.undo_stack)
	self:start_undo_group()
	for i,t in ipairs(group.commands) do
		self[t[1]](self, unpack(t, 2))
	end
	self:end_undo_group()
	table.insert(self.redo_stack, table.remove(self.undo_stack))
end

function editor:redo()
	local group = table.remove(self.redo_stack)
	self:start_undo_group()
	for i,t in ipairs(group.commands) do
		self[t[1]](self, unpack(t, 2))
	end
	self:end_undo_group()
	table.insert(self.undo_stack, table.remove(self.redo_stack))
end

