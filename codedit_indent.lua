--codedit indent/outdent a line
local editor = require'codedit_editor'
local str = require'codedit_str'

function editor:indent(line, with_tabs)
	return self:insert_string(line, 1, with_tabs and '\t' or string.rep(' ', self.tabsize))
end

function editor:outdent(line)
	local s = self:getline(line)
	if str.istab(s, 1) then
		self:remove_string(line, 1, line, 2)
	else
		--no tab to remove, hunt for enough spaces that make for a tab
		local n = 0
		for i in str.byte_indices(s) do
			n = n + 1
			if n > self.tabsize or not str.isspace(s, i) then
				--found enough spaces to make a full tab, or a non-space char encountered
				break
			elseif str.istab(s, i) then
				--not enough spaces to make a tab, but a tab was found: replace the tab with spaces
				--and remove a full tab worth of spaces from he beginning of the line
				s = s:sub(1, i - 1) .. string.rep(' ', self.tabsize) .. s:sub(i + 1)
				s = s:sub(self.tabsize + 1)
				self:setline(line, s)
				return
			end
		end
		--line ended or the search was interrupted
		self:remove_string(line, 1, line, n)
	end
end
