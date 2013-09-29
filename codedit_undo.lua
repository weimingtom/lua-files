--codedit undo and redo command stacks.
--the undo stack is a stack of undo groups. an undo group is a list of editor commands to be executed in reverse order
--in order to perform a single undo operation. consecutive undo groups of the same type are merged together.
--the undo commands in the group can be any editor method with any arguments.
local editor = require'codedit_editor'
local glue = require'glue'

function editor:save_state(state)
	state.line1 = self.cursor.selection.line1
	state.col1  = self.cursor.selection.col1
	state.line2 = self.cursor.selection.line2
	state.col2  = self.cursor.selection.col2
	state.line2 = self.cursor.line
	state.col2  = self.cursor.col
	state.vcol  = self.cursor.vcol
end

function editor:load_state(state)
	self.cursor.selection.line1 = state.line1
	self.cursor.selection.col1  = state.col1
	self.cursor.selection.line2 = state.line2
	self.cursor.selection.col2  = state.col2
	self.cursor.line = state.line2
	self.cursor.col  = state.col2
	self.cursor.vcol = state.vcol
end

function editor:start_undo_group(group_type)
	if self.undo_group then
		if self.undo_group.type == group_type then --same type of group, continue using the current group
			return
		end
		self:end_undo_group() --auto-close current group to start a new one
	end
	self.undo_group = {type = group_type}
	self:save_state(self.undo_group)
end

function editor:end_undo_group()
	if not self.undo_group then return end
	if #self.undo_group > 0 then --push group if not empty
		table.insert(self.undo_stack, self.undo_group)
	end
	self.undo_group = nil
end

function editor:undo_break()
	if not self.undo_group then return end
	if #self.undo_group == 0 then return end --group empty, reuse it
	local group_type = self.undo_group.type
	self:end_undo_group()
	self:start_undo_group(group_type)
end

--add an undo command to the current undo group, if any.
function editor:undo_command(...)
	if not self.undo_group then return end
	if ... == 'setline' then
		--optimization: ignore subsequent setline commands operating on the same line.
		local last_cmd = self.undo_group[#self.undo_group]
		if last_cmd and last_cmd[1] == 'setline' and last_cmd[2] == select(2, ...) then
			return
		end
	end
	table.insert(self.undo_group, {...})
end

local function undo_from(self, group_stack)
	self:end_undo_group()
	local group = table.remove(group_stack)
	if not group then return end
	self:start_undo_group()
	for i = #group, 1, -1 do
		local cmd = group[i]
		self[cmd[1]](self, unpack(cmd, 2))
	end
	self:end_undo_group()
	self:load_state(group)
end

function editor:undo()
	undo_from(self, self.undo_stack)
	if #self.undo_stack == 0 then return end
	table.insert(self.redo_stack, table.remove(self.undo_stack))
end

function editor:redo()
	undo_from(self, self.redo_stack)
end


if not ... then require'codedit_demo' end
