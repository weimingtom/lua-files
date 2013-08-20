-- Copyright 2006-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

local lpeg = require 'lpeg'
local lpeg_P, lpeg_R, lpeg_S, lpeg_V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local lpeg_Ct, lpeg_Cc, lpeg_Cp = lpeg.Ct, lpeg.Cc, lpeg.Cp
local lpeg_match = lpeg.match

-- Adds a rule to a lexer's current ordered list of rules.
-- @param lexer The lexer to add the given rule to.
-- @param name The name associated with this rule. It is used for other lexers
--   to access this particular rule from the lexer's `_RULES` table. It does not
--   have to be the same as the name passed to `token`.
-- @param rule The LPeg pattern of the rule.
local function add_rule(lexer, id, rule)
	if not lexer._RULES then
		lexer._RULES = {}
		-- Contains an ordered list (by numerical index) of rule names. This is used
		-- in conjunction with lexer._RULES for building _TOKENRULE.
		lexer._RULEORDER = {}
	end
	lexer._RULES[id] = rule
	lexer._RULEORDER[#lexer._RULEORDER + 1] = id
end

-- Adds a new Scintilla style to Scintilla.
-- @param lexer The lexer to add the given style to.
-- @param token_name The name of the token associated with this style.
-- @param style A Scintilla style created from `style()`.
-- @see style
local function add_style(lexer, token_name, style)
	local len = lexer._STYLES.len
	if len == 32 then len = len + 8 end -- skip predefined styles
	if len >= 255 then print('Too many styles defined (255 MAX)') end
	lexer._TOKENS[token_name] = len
	lexer._STYLES[len] = style
	lexer._STYLES.len = len + 1
end

-- (Re)constructs `lexer._TOKENRULE`.
-- @param parent The parent lexer.
local function join_tokens(lexer)
	local patterns, order = lexer._RULES, lexer._RULEORDER
	local token_rule = patterns[order[1]]
	for i = 2, #order do token_rule = token_rule + patterns[order[i]] end
	lexer._TOKENRULE = token_rule
	return lexer._TOKENRULE
end

-- Adds a given lexer and any of its embedded lexers to a given grammar.
-- @param grammar The grammar to add the lexer to.
-- @param lexer The lexer to add.
local function add_lexer(grammar, lexer, token_rule)
	local token_rule = join_tokens(lexer)
	local lexer_name = lexer._NAME
	for _, child in ipairs(lexer._CHILDREN) do
		if child._CHILDREN then add_lexer(grammar, child) end
		local child_name = child._NAME
		local rules = child._EMBEDDEDRULES[lexer_name]
		local rules_token_rule = grammar['__'..child_name] or rules.token_rule
		grammar[child_name] = (-rules.end_rule * rules_token_rule)^0 *
													rules.end_rule^-1 * lpeg_V(lexer_name)
		local embedded_child = '_'..child_name
		grammar[embedded_child] = rules.start_rule * (-rules.end_rule *
															rules_token_rule)^0 * rules.end_rule^-1
		token_rule = lpeg_V(embedded_child) + token_rule
	end
	grammar['__'..lexer_name] = token_rule -- can contain embedded lexer rules
	grammar[lexer_name] = token_rule^0
end

-- (Re)constructs `lexer._GRAMMAR`.
-- @param lexer The parent lexer.
-- @param initial_rule The name of the rule to start lexing with. The default
--   value is `lexer._NAME`. Multilang lexers use this to start with a child
--   rule if necessary.
local function build_grammar(lexer, initial_rule)
	local children = lexer._CHILDREN
	if children then
		local lexer_name = lexer._NAME
		if not initial_rule then initial_rule = lexer_name end
		local grammar = {initial_rule}
		add_lexer(grammar, lexer)
		lexer._INITIALRULE = initial_rule
		lexer._GRAMMAR = lpeg_Ct(lpeg_P(grammar))
	else
		lexer._GRAMMAR = lpeg_Ct(join_tokens(lexer)^0)
	end
end

-- Default tokens.
-- Contains predefined token names and their associated style numbers.
-- @class table
-- @name tokens
-- @field default The default token's style (0).
-- @field whitespace The whitespace token's style (1).
-- @field comment The comment token's style (2).
-- @field string The string token's style (3).
-- @field number The number token's style (4).
-- @field keyword The keyword token's style (5).
-- @field identifier The identifier token's style (6).
-- @field operator The operator token's style (7).
-- @field error The error token's style (8).
-- @field preprocessor The preprocessor token's style (9).
-- @field constant The constant token's style (10).
-- @field variable The variable token's style (11).
-- @field function The function token's style (12).
-- @field class The class token's style (13).
-- @field type The type token's style (14).
-- @field label The label token's style (15).
-- @field regex The regex token's style (16).
local tokens = {
	default      = 0,
	whitespace   = 1,
	comment      = 2,
	string       = 3,
	number       = 4,
	keyword      = 5,
	identifier   = 6,
	operator     = 7,
	error        = 8,
	preprocessor = 9,
	constant     = 10,
	variable     = 11,
	['function'] = 12,
	class        = 13,
	type         = 14,
	label        = 15,
	regex        = 16,
}
local string_upper = string.upper
for k, v in pairs(tokens) do M[string_upper(k)] = k end

---
-- Initializes or loads lexer *lexer_name* and returns the lexer object.
-- Scintilla calls this function to load a lexer. Parent lexers also call this
-- function to load child lexers and vice-versa.
-- @param lexer_name The name of the lexing language.
-- @return lexer object
-- @name load
function M.load(lexer_name)
	M.WHITESPACE = lexer_name..'_whitespace'
	local lexer = require(lexer_name or 'null')
	lexer._TOKENS = tokens
	lexer._STYLES = {
		[0] = M.style_nothing,
		[1] = M.style_whitespace,
		[2] = M.style_comment,
		[3] = M.style_string,
		[4] = M.style_number,
		[5] = M.style_keyword,
		[6] = M.style_identifier,
		[7] = M.style_operator,
		[8] = M.style_error,
		[9] = M.style_preproc,
		[10] = M.style_constant,
		[11] = M.style_variable,
		[12] = M.style_function,
		[13] = M.style_class,
		[14] = M.style_type,
		[15] = M.style_label,
		[16] = M.style_regex,
		len = 17,
		-- Predefined styles.
		[32] = M.style_default,
		[33] = M.style_line_number,
		[34] = M.style_bracelight,
		[35] = M.style_bracebad,
		[36] = M.style_controlchar,
		[37] = M.style_indentguide,
		[38] = M.style_calltip,
	}
	if lexer._lexer then
		local l, _r, _s = lexer._lexer, lexer._rules, lexer._tokenstyles
		if not l._tokenstyles then l._tokenstyles = {} end
		for _, r in ipairs(_r or {}) do
			-- Prevent rule id clashes.
			l._rules[#l._rules + 1] = {lexer._NAME..'_'..r[1], r[2]}
		end
		for _, s in ipairs(_s or {}) do l._tokenstyles[#l._tokenstyles + 1] = s end
		-- Each lexer that is loaded with l.load() has its _STYLES modified through
		-- add_style(). Reset _lexer's _STYLES accordingly.
		-- For example: RHTML load's HTML (which loads CSS and Javascript). CSS's
		-- styles are added to css._STYLES and JS's styles are added to js._STYLES.
		-- HTML adds its styles to html._STYLES as well as CSS's and JS's styles.
		-- RHTML adds its styles, HTML's styles, CSS's styles, and JS's styles to
		-- rhtml._STYLES. The problem is that rhtml == _lexer == html. Therefore
		-- html._STYLES would contain duplicate styles. Compensate by setting
		-- html._STYLES to rhtml._STYLES.
		l._STYLES = lexer._STYLES
		lexer = l
	end
	if lexer._rules then
		for _, s in ipairs(lexer._tokenstyles or {}) do
			add_style(lexer, s[1], s[2])
		end
		for _, r in ipairs(lexer._rules) do add_rule(lexer, r[1], r[2]) end
		build_grammar(lexer)
	end
	add_style(lexer, lexer._NAME..'_whitespace', M.style_whitespace)
	if lexer._foldsymbols and lexer._foldsymbols._patterns then
		local patterns = lexer._foldsymbols._patterns
		for i = 1, #patterns do patterns[i] = '()('..patterns[i]..')' end
	end
	_G._LEXER = lexer
	return lexer
end

---
-- Lexes a chunk of text *text* with an initial style number of *init_style*.
-- Called by the Scintilla lexer; **do not call from Lua**. If the lexer has a
-- `_LEXBYLINE` flag set, the text is lexed one line at a time. Otherwise the
-- text is lexed as a whole.
-- @param text The text in the buffer to lex.
-- @param init_style The current style. Multiple-language lexers use this to
--   determine which language to start lexing in.
-- @return table of token names and positions.
-- @name lex
function M.lex(text, init_style)
	local lexer = _G._LEXER
	if not lexer._LEXBYLINE then
		-- For multilang lexers, build a new grammar whose initial_rule is the
		-- current language.
		if lexer._CHILDREN then
			for style, style_num in pairs(lexer._TOKENS) do
				if style_num == init_style then
					local lexer_name = style:match('^(.+)_whitespace') or lexer._NAME
					if lexer._INITIALRULE ~= lexer_name then
						build_grammar(lexer, lexer_name)
					end
					break
				end
			end
		end
		return lpeg_match(lexer._GRAMMAR, text)
	else
		local tokens = {}
		local function append(tokens, line_tokens, offset)
			for i = 1, #line_tokens, 2 do
				tokens[#tokens + 1] = line_tokens[i]
				tokens[#tokens + 1] = line_tokens[i + 1] + offset
			end
		end
		local offset = 0
		local grammar = lexer._GRAMMAR
		for line in text:gmatch('[^\r\n]*\r?\n?') do
			local line_tokens = lpeg_match(grammar, line)
			if line_tokens then append(tokens, line_tokens, offset) end
			offset = offset + #line
			-- Use the default style to the end of the line if none was specified.
			if tokens[#tokens] ~= offset then
				tokens[#tokens + 1], tokens[#tokens + 2] = 'default', offset + 1
			end
		end
		return tokens
	end
end

---
-- Folds *text*, a chunk of text starting at position *start_pos* on line number
-- *start_line* with a beginning fold level of *start_level* in the buffer.
-- Called by the Scintilla lexer; **do not call from Lua**. If the current lexer
-- has a `_fold` function or a `_foldsymbols` table, it is used to perform
-- folding. Otherwise, if a `fold.by.indentation` property is set, folding by
-- indentation is done.
-- @param text The text in the buffer to fold.
-- @param start_pos The position in the buffer *text* starts at.
-- @param start_line The line number *text* starts on.
-- @param start_level The fold level *text* starts on.
-- @return table of fold levels.
-- @name fold
function M.fold(text, start_pos, start_line, start_level)
	local folds = {}
	if text == '' then return folds end
	local lexer = _G._LEXER
	local FOLD_BASE = M.FOLD_BASE
	local FOLD_HEADER, FOLD_BLANK  = M.FOLD_HEADER, M.FOLD_BLANK
	if lexer._fold then
		return lexer._fold(text, start_pos, start_line, start_level)
	elseif lexer._foldsymbols then
		local lines = {}
		for p, l in text:gmatch('()(.-)\r?\n') do lines[#lines + 1] = {p, l} end
		lines[#lines + 1] = {text:match('()([^\r\n]*)$')}
		local fold_symbols = lexer._foldsymbols
		local fold_symbols_patterns = fold_symbols._patterns
		local get_style_at = M.get_style_at
		local line_num, prev_level = start_line, start_level
		local current_level = prev_level
		for i = 1, #lines do
			local pos, line = lines[i][1], lines[i][2]
			if line ~= '' then
				for j = 1, #fold_symbols_patterns do
					for s, match in line:gmatch(fold_symbols_patterns[j]) do
						local symbols = fold_symbols[get_style_at(start_pos + pos + s - 1)]
						local l = symbols and symbols[match]
						if type(l) == 'number' then
							current_level = current_level + l
						elseif type(l) == 'function' then
							current_level = current_level + l(text, pos, line, s, match)
						end
					end
				end
				folds[line_num] = prev_level
				if current_level > prev_level then
					folds[line_num] = prev_level + FOLD_HEADER
				end
				if current_level < FOLD_BASE then current_level = FOLD_BASE end
				prev_level = current_level
			else
				folds[line_num] = prev_level + FOLD_BLANK
			end
			line_num = line_num + 1
		end
	elseif M.get_property('fold.by.indentation', 1) == 1 then
		local get_indent_amount = M.get_indent_amount
		-- Indentation based folding.
		local current_line, prev_level = start_line, start_level
		for _, line in text:gmatch('([\t ]*)(.-)\r?\n') do
			if line ~= '' then
				local current_level = FOLD_BASE + get_indent_amount(current_line)
				if current_level > prev_level then -- next level
					local i = current_line - 1
					while folds[i] and folds[i][2] == FOLD_BLANK do i = i - 1 end
					if folds[i] then folds[i][2] = FOLD_HEADER end -- low indent
					folds[current_line] = {current_level} -- high indent
				elseif current_level < prev_level then -- prev level
					if folds[current_line - 1] then
						folds[current_line - 1][1] = prev_level -- high indent
					end
					folds[current_line] = {current_level} -- low indent
				else -- same level
					folds[current_line] = {prev_level}
				end
				prev_level = current_level
			else
				folds[current_line] = {prev_level, FOLD_BLANK}
			end
			current_line = current_line + 1
		end
		-- Flatten.
		for line, level in pairs(folds) do
			folds[line] = level[1] + (level[2] or 0)
		end
	else
		-- No folding, reset fold levels if necessary.
		local current_line = start_line
		for _ in text:gmatch(".-\r?\n") do
			folds[current_line] = start_level
			current_line = current_line + 1
		end
	end
	return folds
end

-- The following are utility functions lexers will have access to.

-- Common patterns.
M.any = lpeg_P(1)
M.ascii = lpeg_R('\000\127')
M.extend = lpeg_R('\000\255')
M.alpha = lpeg_R('AZ', 'az')
M.digit = lpeg_R('09')
M.alnum = lpeg_R('AZ', 'az', '09')
M.lower = lpeg_R('az')
M.upper = lpeg_R('AZ')
M.xdigit = lpeg_R('09', 'AF', 'af')
M.cntrl = lpeg_R('\000\031')
M.graph = lpeg_R('!~')
M.print = lpeg_R(' ~')
M.punct = lpeg_R('!/', ':@', '[\'', '{~')
M.space = lpeg_S('\t\v\f\n\r ')

M.newline = lpeg_S('\r\n\f')^1
M.nonnewline = 1 - M.newline
M.nonnewline_esc = 1 - (M.newline + '\\') + '\\' * M.any

M.dec_num = M.digit^1
M.hex_num = '0' * lpeg_S('xX') * M.xdigit^1
M.oct_num = '0' * lpeg_R('07')^1
M.integer = lpeg_S('+-')^-1 * (M.hex_num + M.oct_num + M.dec_num)
M.float = lpeg_S('+-')^-1 *
					(M.digit^0 * '.' * M.digit^1 + M.digit^1 * '.' * M.digit^0 +
					 M.digit^1) *
					lpeg_S('eE') * lpeg_S('+-')^-1 * M.digit^1
M.word = (M.alpha + '_') * (M.alnum + '_')^0

---
-- Creates and returns a token pattern with the name *name* and pattern *patt*.
-- If *name* is not a predefined token name, its style must be defined in the
-- lexer's `_tokenstyles` table.
-- @param name The name of token. If this name is not a predefined token name,
--   then a style needs to be assiciated with it in the lexer's `_tokenstyles`
--   table.
-- @param patt The LPeg pattern associated with the token.
-- @return pattern
-- @usage local ws = token(l.WHITESPACE, l.space^1)
-- @usage local annotation = token('annotation', '@' * l.word)
-- @name token
function M.token(name, patt)
	return lpeg_Cc(name) * patt * lpeg_Cp()
end

-- Common tokens
M.any_char = M.token(M.DEFAULT, M.any)

---
-- Table of common colors for a theme.
-- This table should be redefined in each theme.
-- @class table
-- @name colors
M.colors = {}

---
-- Creates and returns a Scintilla style from the given table of style
-- properties.
-- @param style_table A table of style properties:
--   * `font` (string) The name of the font the style uses.
--   * `size` (number) The size of the font the style uses.
--   * `bold` (bool) Whether or not the font face is bold.
--   * `italic` (bool) Whether or not the font face is italic.
--   * `underline` (bool) Whether or not the font face is underlined.
--   * `fore` (number) The foreground [`color`](#color) of the font face.
--   * `back` (number) The background [`color`](#color) of the font face.
--   * `eolfilled` (bool) Whether or not the background color extends to the end
--     of the line.
--   * `case` (number) The case of the font (1 = upper, 2 = lower, 0 = normal).
--   * `visible` (bool) Whether or not the text is visible.
--   * `changeable` (bool) Whether the text changable or read-only.
--   * `hotspot` (bool) Whether or not the text is clickable.
-- @return style table
-- @usage local style_bold_italic = style{bold = true, italic = true}
-- @usage local style_grey = style{fore = l.colors.grey}
-- @see color
-- @name style
function M.style(style_table)
	setmetatable(style_table, {
		__concat = function(t1, t2)
			local t = setmetatable({}, getmetatable(t1)) -- duplicate t1
			for k,v in pairs(t1) do t[k] = v end
			for k,v in pairs(t2) do t[k] = v end
			return t
		end
	})
	return style_table
end

---
-- Creates and returns a Scintilla color from *r*, *g*, and *b* string
-- hexadecimal color components.
-- @param r The string red hexadecimal component of the color.
-- @param g The string green hexadecimal component of the color.
-- @param b The string blue hexadecimal component of the color.
-- @return integer color for Scintilla.
-- @usage local red = color('FF', '00', '00')
-- @name color
function M.color(r, g, b) return tonumber(b..g..r, 16) end

---
-- Creates and returns a pattern that matches a range of text bounded by
-- *chars* characters.
-- This is a convenience function for matching more complicated delimited ranges
-- like strings with escape characters and balanced parentheses. *escape*
-- specifies the escape characters a range can have, *end_optional* indicates
-- whether or not unterminated ranges match, *balanced* indicates whether or not
-- to handle balanced ranges like parentheses and requires *chars* to be
-- composed of two characters, and *forbidden* is a set of characters disallowed
-- in ranges such as newlines.
-- @param chars The character(s) that bound the matched range.
-- @param escape Optional escape character. This parameter may `nil` or the
--   empty string to indicate no escape character.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If `true`, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @param balanced Optional flag indicating whether or not a balanced range is
--   matched, like the "%b" Lua pattern. This flag only applies if *chars*
--   consists of two different characters (e.g. "()").
-- @param forbidden Optional string of characters forbidden in a delimited
--   range. Each character is part of the set. This is particularly useful for
--   disallowing newlines in delimited ranges.
-- @return pattern
-- @usage local dq_str_noescapes = l.delimited_range('"', nil, true)
-- @usage local dq_str_escapes = l.delimited_range('"', '\\', true)
-- @usage local unbalanced_parens = l.delimited_range('()', '\\')
-- @usage local balanced_parens = l.delimited_range('()', '\\', false, true)
-- @see nested_pair
-- @name delimited_range
function M.delimited_range(chars, escape, end_optional, balanced, forbidden)
	local s = chars:sub(1, 1)
	local e = #chars == 2 and chars:sub(2, 2) or s
	local range
	local b = balanced and s or ''
	local f = forbidden or ''
	if not escape or escape == '' then
		local invalid = lpeg_S(e..f..b)
		range = M.any - invalid
	else
		local invalid = lpeg_S(e..f..b) + escape
		range = M.any - invalid + escape * M.any
	end
	if balanced and s ~= e then
		return lpeg_P{s * (range + lpeg_V(1))^0 * e}
	else
		if end_optional then e = lpeg_P(e)^-1 end
		return s * range^0 * e
	end
end

---
-- Creates and returns a pattern that matches pattern *patt* only at the
-- beginning of a line.
-- @param patt The LPeg pattern to match on the beginning of a line.
-- @return pattern
-- @usage local preproc = token(l.PREPROCESSOR, #P('#') * l.starts_line('#' *
--   l.nonnewline^0))
-- @name starts_line
function M.starts_line(patt)
	return lpeg_P(function(input, index)
		if index == 1 then return index end
		local char = input:sub(index - 1, index - 1)
		if char == '\n' or char == '\r' or char == '\f' then return index end
	end) * patt
end

---
-- Creates and returns a pattern that matches any previous non-whitespace
-- character in *s* and consumes no input.
-- @param s String character set like one passed to `lpeg.S()`.
-- @return pattern
-- @usage local regex = l.last_char_includes('+-*!%^&|=,([{') *
--   l.delimited_range('/', '\\')
-- @name last_char_includes
function M.last_char_includes(s)
	s = '['..s:gsub('[-%%%[]', '%%%1')..']'
	return lpeg_P(function(input, index)
		if index == 1 then return index end
		local i = index
		while input:sub(i - 1, i - 1):match('[ \t\r\n\f]') do i = i - 1 end
		if input:sub(i - 1, i - 1):match(s) then return index end
	end)
end

---
-- Similar to `delimited_range()`, but allows for multi-character, nested
-- delimiters *start_chars* and *end_chars*. *end_optional* indicates whether or
-- not unterminated ranges match.
-- With single-character delimiters, this function is identical to
-- `delimited_range(start_chars..end_chars, nil, end_optional, true)`.
-- @param start_chars The string starting a nested sequence.
-- @param end_chars The string ending a nested sequence.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If `true`, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @return pattern
-- @usage local nested_comment = l.nested_pair('/*', '*/', true)
-- @see delimited_range
-- @name nested_pair
function M.nested_pair(start_chars, end_chars, end_optional)
	local s, e = start_chars, end_optional and lpeg_P(end_chars)^-1 or end_chars
	return lpeg_P{s * (M.any - s - end_chars + lpeg_V(1))^0 * e}
end

---
-- Creates and returns a pattern that matches any word in the set *words*
-- case-sensitively, unless *case_insensitive* is `true`, with the set of word
-- characters being alphanumerics, underscores, and all of the characters in
-- *word_chars*.
-- This is a convenience function for simplifying a set of ordered choice word
-- patterns.
-- @param words A table of words.
-- @param word_chars Optional string of additional characters considered to be
--   part of a word. By default, word characters are alphanumerics and
--   underscores ("%w_" in Lua). This parameter may be `nil` or the empty string
--   to indicate no additional word characters.
-- @param case_insensitive Optional boolean flag indicating whether or not the
--   word match is case-insensitive. The default is `false`.
-- @return pattern
-- @usage local keyword = token(l.KEYWORD, word_match{'foo', 'bar', 'baz'})
-- @usage local keyword = token(l.KEYWORD, word_match({'foo-bar', 'foo-baz',
--   'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar'}, '-', true))
-- @name word_match
function M.word_match(words, word_chars, case_insensitive)
	local word_list = {}
	for _, word in ipairs(words) do
		word_list[case_insensitive and word:lower() or word] = true
	end
	local chars = '%w_'
	-- escape 'magic' characters
	-- TODO: append chars to the end so ^_ can be passed for not including '_'s
	if word_chars then chars = chars..word_chars:gsub('([%^%]%-])', '%%%1') end
	return lpeg_P(function(input, index)
			local s, e, word = input:find('^(['..chars..']+)', index)
			if word then
				if case_insensitive then word = word:lower() end
				return word_list[word] and e + 1 or nil
			end
		end)
end

---
-- Embeds *child* lexer in *parent* with *start_rule* and *end_rule*, patterns
-- that signal the beginning and end of the embedded lexer, respectively.
-- @param parent The parent lexer.
-- @param child The child lexer.
-- @param start_rule The pattern that signals the beginning of the embedded
--   lexer.
-- @param end_rule The pattern that signals the end of the embedded lexer.
-- @usage l.embed_lexer(M, css, css_start_rule, css_end_rule)
-- @usage l.embed_lexer(html, M, php_start_rule, php_end_rule)
-- @usage l.embed_lexer(html, ruby, ruby_start_rule, ruby_end_rule)
-- @name embed_lexer
function M.embed_lexer(parent, child, start_rule, end_rule)
	-- Add child rules.
	if not child._EMBEDDEDRULES then child._EMBEDDEDRULES = {} end
	if not child._RULES then -- creating a child lexer to be embedded
		if not child._rules then error('Cannot embed language with no rules') end
		for _, r in ipairs(child._rules) do add_rule(child, r[1], r[2]) end
	end
	child._EMBEDDEDRULES[parent._NAME] = {
		['start_rule'] = start_rule,
		token_rule = join_tokens(child),
		['end_rule'] = end_rule
	}
	if not parent._CHILDREN then parent._CHILDREN = {} end
	local children = parent._CHILDREN
	children[#children + 1] = child
	-- Add child styles.
	if not parent._tokenstyles then parent._tokenstyles = {} end
	local tokenstyles = parent._tokenstyles
	tokenstyles[#tokenstyles + 1] = {child._NAME..'_whitespace',
																	 M.style_whitespace}
	for _, style in ipairs(child._tokenstyles or {}) do
		tokenstyles[#tokenstyles + 1] = style
	end
end

-- Determines if the previous line is a comment.
-- This is used for determining if the current comment line is a fold point.
-- @param prefix The prefix string defining a comment.
-- @param text The text passed to a fold function.
-- @param pos The pos passed to a fold function.
-- @param line The line passed to a fold function.
-- @param s The s passed to a fold function.
local function prev_line_is_comment(prefix, text, pos, line, s)
	local start = line:find('%S')
	if start < s and not line:find(prefix, start, true) then return false end
	local p = pos - 1
	if text:sub(p, p) == '\n' then
		p = p - 1
		if text:sub(p, p) == '\r' then p = p - 1 end
		if text:sub(p, p) ~= '\n' then
			while p > 1 and text:sub(p - 1, p - 1) ~= '\n' do p = p - 1 end
			while text:sub(p, p):find('^[\t ]$') do p = p + 1 end
			return text:sub(p, p + #prefix - 1) == prefix
		end
	end
	return false
end

-- Determines if the next line is a comment.
-- This is used for determining if the current comment line is a fold point.
-- @param prefix The prefix string defining a comment.
-- @param text The text passed to a fold function.
-- @param pos The pos passed to a fold function.
-- @param line The line passed to a fold function.
-- @param s The s passed to a fold function.
local function next_line_is_comment(prefix, text, pos, line, s)
	local p = text:find('\n', pos + s)
	if p then
		p = p + 1
		while text:sub(p, p):find('^[\t ]$') do p = p + 1 end
		return text:sub(p, p + #prefix - 1) == prefix
	end
	return false
end

---
-- Returns a fold function, to be used within the lexer's `_foldsymbols` table,
-- that folds consecutive line comments beginning with string *prefix*.
-- @param prefix The prefix string defining a line comment.
-- @usage [l.COMMENT] = {['--'] = l.fold_line_comments('--')}
-- @usage [l.COMMENT] = {['//'] = l.fold_line_comments('//')}
-- @name fold_line_comments
function M.fold_line_comments(prefix)
	local get_property = M.get_property
	return function(text, pos, line, s)
		if get_property('fold.line.comments', 0) == 0 then return 0 end
		if s > 1 and line:match('^%s*()') < s then return 0 end
		local prev_line_comment = prev_line_is_comment(prefix, text, pos, line, s)
		local next_line_comment = next_line_is_comment(prefix, text, pos, line, s)
		if not prev_line_comment and next_line_comment then return 1 end
		if prev_line_comment and not next_line_comment then return -1 end
		return 0
	end
end

--[[ The functions and fields below were defined in C.

---
-- Individual lexer fields.
-- @field _NAME The string name of the lexer in lowercase.
-- @field _rules An ordered list of rules for a lexer grammar.
--   Each rule is a table containing an arbitrary rule name and the LPeg pattern
--   associated with the rule. The order of rules is important as rules are
--   matched sequentially. Ensure there is a fallback rule in case the lexer
--   encounters any unexpected input, usually using the predefined `l.any_char`
--   token.
--   Child lexers should not use this table to access and/or modify their
--   parent's rules and vice-versa. Use the `_RULES` table instead.
-- @field _tokenstyles A list of styles associated with non-predefined token
--   names.
--   Each token style is a table containing the name of the token (not a rule
--   containing the token) and the style associated with the token. The order of
--   token styles is not important.
--   It is recommended to use predefined styles or color-agnostic styles derived
--   from predefined styles to ensure compatibility with user color themes.
-- @field _foldsymbols A table of recognized fold points for the lexer.
--   Keys are token names with table values defining fold points. Those table
--   values have string keys of keywords or characters that indicate a fold
--   point whose values are integers. A value of `1` indicates a beginning fold
--   point and a value of `-1` indicates an ending fold point. Values can also
--   be functions that return `1`, `-1`, or `0` (indicating no fold point) for
--   keys which need additional processing.
--   There is also a required `_pattern` key whose value is a table containing
--   Lua pattern strings that match all fold points (the string keys contained
--   in token name table values). When the lexer encounters text that matches
--   one of those patterns, the matched text is looked up in its token's table
--   to determine whether or not it is a fold point.
-- @field _fold If this function exists in the lexer, it is called for folding
--   the document instead of using `_foldsymbols` or indentation.
-- @field _lexer For child lexers embedding themselves into a parent lexer, this
--   field should be set to the parent lexer object in order for the parent's
--   rules to be used instead of the child's.
-- @field _RULES A map of rule name keys with their associated LPeg pattern
--   values for the lexer.
--   This is constructed from the lexer's `_rules` table and accessible to other
--   lexers for embedded lexer applications like modifying parent or child
--   rules.
-- @field _LEXBYLINE Indicates the lexer matches text by whole lines instead of
--    arbitrary chunks.
--    The default value is `false`. Line lexers cannot look ahead to subsequent
--    lines.
-- @class table
-- @name lexer
local lexer

---
-- Returns the string style name and style number at position *pos* in the
-- buffer.
-- @param pos The position in the buffer to get the style for.
-- @return style name
-- @return style number
-- @class function
-- @name get_style_at
local get_style_at

---
-- Returns the integer property value associated with string property *key*, or
-- *default*.
-- @param key The string property key.
-- @param default Optional integer value to return if *key* is not set.
-- @return integer property value
-- @class function
-- @name get_property
local get_property

---
-- Returns the fold level for line number *line_number*.
-- This level already has `SC_FOLDLEVELBASE` added to it, so you do not need to
-- add it yourself.
-- @param line_number The line number to get the fold level of.
-- @return integer fold level
-- @class function
-- @name get_fold_level
local get_fold_level

---
-- Returns the amount of indentation the text on line number *line_number* has.
-- @param line_number The line number to get the indent amount of.
-- @return integer indent amount
-- @class function
-- @name get_indent_amount
local get_indent_amount
]]

return M
