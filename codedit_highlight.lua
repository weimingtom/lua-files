local glue = require'glue'

local highlighter = {}

--lifetime

function highlighter:new(buffer, lang)
	self = glue.inherit({buffer = buffer}, highlighter)
	self:init(lang)
	return self
end

function highlighter:invalidate(line)
	self.lines[line] = false
end

function highlighter:length_to(line2)
	local sz = 0
	for line = 1,line2 - 1 do
		sz = sz + #self.buffer:getline(line)
	end
	return sz
end


package.path = package.path .. ';' .. 'lexers/?.lua'
lexer = require'lexers.lexer'
_LEXER = nil
lexer.style_tag = lexer.style{}
lexer.style_type = lexer.style{}
lexer.load'lexers.hypertext'

function highlighter:tokens_pos(tokens)
	local line = 0
	local start_pos = 0
	local end_pos = 0

	tokens[0] = 1 --the list starts with the style of the first token instead of its position
	local i = 0 --so we'll consider the list to be 0-based instead

	return function()

		local pos, style, next_pos = tokens[i], tokens[i+1], tokens[i+2]
		if not style then return end
		local token_len = next_pos - pos
		i = i + 2

		while pos > end_pos do
			line = line + 1
			start_pos = end_pos + 1
			end_pos = end_pos + #self.buffer:getline(line) + #self.buffer.line_terminator
		end

		local rel_pos = pos - start_pos + 1

		return line, rel_pos, rel_pos + token_len - 1, style
	end
end

function highlighter:lang_pos(tokens, lang, line)
	local line0, i0, lang0 = 1, 1, lang
	for line1, i1, i2, style in self:tokens_pos(tokens) do
		--print(line1, i1, i2, style, self.buffer:sub(line1, i1, i2))
		if line1 >= line then
			break
		end
		local lang = style:match'^lexers.([^_]+)_whitespace$' or style:match'^([^_]+)_whitespace$'
		if lang then
			line0, i0, lang0 = line1, i1, lang
		end
	end
	return line0, i0, lang0
end

function highlighter:init(lang)
	self.tokens = lexer.lex(self.buffer:contents(), lang)
end

function highlighter:reparse(line1, line2, lang)
	local line1, i, lang = self:lang_pos(self.tokens, 'hypertext', line1)
	local s = self.buffer:getline(line1):sub(i)
	local s = s .. table.concat(self.buffer.lines, self.buffer.line_terminator, line1 + 1, line2)
	self.tokens = lexer.lex(s, lang)
end


if not ... then

local buffer = require'codedit_buffer'; require'codedit_undo'
local view = {tabsize = 3}
local editor = {getstate = function() end, setstate = function() end}
local buf = buffer:new(editor, view, '<script type="text/javascript">\nvar i = 1;</script>more')
local lighter = highlighter:new(buf, 'hypertext')

--lighter:lex()

end

return highlighter

