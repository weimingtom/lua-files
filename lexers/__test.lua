lexer = require'lexers.lexer'
_LEXER = nil
local lua = lexer.load'lexers.lua'

--pp(lua)

local text = [[
function f() end
]]

pp(lexer.lex(text))

