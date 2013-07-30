--codedit: modifying the string buffer.
local lines = require'codedit_lines'
local edit = {}

--normalize string for newline and tab format.
local function normalize(s, tabs, newline)
	s = s:gsub('\t', tabs)
	s = s:gsub('\r?\n', newline)
	return s
end

--insert text at cursor. if the cursor is outside editor space, the editor space is extended
--with newlines and spaces until it reaches the cursor.
function edit.insert(lnum, cnum, s)
	s = normalize(s)
	local i, n, c = self:pos(lnum, cnum)
	local pad = ''
	if n < lnum then pad = pad .. self.newline:rep(lnum - n); c = 1 end
 	if c < cnum then pad = pad .. (' '):rep(cnum - c) end
	self.buffer.s = self.buffer.s:sub(1, i - 1) .. pad .. s .. self.buffer.s:sub(i)
end

--remove the text between two cursors.
function edit.remove(lnum1, cnum1, lnum2, cnum2)
	local i = self:pos(lnum1, cnum1)
	local j = self:pos(lnum2, cnum2)
	self.buffer.s = self.buffer.s:sub(1, i - 1) .. self.buffer.s:sub(j + 1)
end

return edit
