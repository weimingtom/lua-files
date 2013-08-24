lexer = require'lexers.lexer'
_LEXER = nil
local lua = lexer.load'lexers.lua'

--pp(lua)

local text = 'function\nend'

print(#text)
pp(lexer.lex(text))

