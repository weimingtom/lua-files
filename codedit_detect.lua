--codedit text analysis
local editor = require'codedit_editor'
local str = require'codedit_str'

editor.default_line_terminator = '\n' --line terminator to use when autodetection fails.

--class method that returns the most common line terminator in a string, or default
function editor:detect_line_terminator(s)
	local rn = str.count(s, '\r\n') --win lines
	local r  = str.count(s, '\r') --mac lines
	local n  = str.count(s, '\n') --unix lines (default)
	if rn > n and rn > r then
		return '\r\n'
	elseif r > n then
		return '\r'
	else
		return self.default_line_terminator
	end
end

--detect indent type and tab size of current buffer
function editor:detect_indent()
	local tabs, spaces = 0, 0
	for line = 1, self:last_line() do
		local tabs1, spaces1 = str.indent_counts(self:getline(line))
		tabs = tabs + tabs1
		spaces = spaces + spaces1
	end
	--TODO: finish this
end
