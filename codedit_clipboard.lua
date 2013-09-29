--codedit clipboard functionality
local editor = require'codedit_editor'

--clipboard API stubs

local clipboard_contents = '' --global clipboard over all editor instances on the same Lua state

function editor:set_clipboard(s)
	clipboard_contents = s
end

function editor:get_clipboard()
	return clipboard_contents
end

--clipboard-based editing

function editor:cut()
	if self.cursor.selection:isempty() then return end
	local s = self.cursor.selection:contents()
	self:set_clipboard(s)
	self.cursor:remove_selection()
end

function editor:copy()
	if self.cursor.selection:isempty() then return end
	self:set_clipboard(self.cursor.selection:contents())
end

function editor:paste()
	local s = self:get_clipboard()
	if not s then return end
	self.cursor:remove_selection()
	self.cursor:insert_string(s)
end

function editor:paste_block()
	local s = self:get_clipboard()
	if not s then return end
	self.cursor:remove_selection()
	self.cursor:insert_block(s)
end


if not ... then require'codedit_demo' end
