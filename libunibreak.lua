local ffi = require'ffi'
require'libunibreak_h'
local C = ffi.load'libunibreak'
local M = setmetatable({C = C}, {__index = C})

C.init_linebreak()
C.init_wordbreak()

local function set_linebreaks_func(func, code_size)
	return function(s, len, lang, brks)
		len = len or math.floor(#s / code_size)
		brks = brks or ffi.new('char[?]', len)
		func(s, len, lang, brks)
		return brks
	end
end

M.set_linebreaks_utf8  = set_linebreaks_func(C.set_linebreaks_utf8, 1)
M.set_linebreaks_utf16 = set_linebreaks_func(C.set_linebreaks_utf16, 2)
M.set_linebreaks_utf32 = set_linebreaks_func(C.set_linebreaks_utf32, 4)

M.set_wordbreaks_utf8  = set_linebreaks_func(C.set_linebreaks_utf8, 1)
M.set_wordbreaks_utf16 = set_linebreaks_func(C.set_linebreaks_utf16, 2)
M.set_wordbreaks_utf32 = set_linebreaks_func(C.set_linebreaks_utf32, 4)


if not ... then

local line_break_names = {[0] = '!', 'Y', 'N', '.'}
local word_break_names = {[0] = 'Y', 'N', '.'}

print('version', C.linebreak_version)
local s = 'The quick ("brown") fox can\'t jump 32.3 feet, right?'
local line_brks = M.set_linebreaks_utf8(s)
local word_brks = M.set_wordbreaks_utf8(s)
for i=1,#s do
	print(s:sub(i,i), line_break_names[line_brks[i-1]], word_break_names[word_brks[i-1]])
end

end

return M
