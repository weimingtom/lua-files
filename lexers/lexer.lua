-- Copyright 2006-2013 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[=[ This comment is for LuaDoc.
---
-- Lexes Scintilla documents with Lua and LPeg.
--
-- ## Overview
--
-- Lexers highlight the syntax of source code. Scintilla (the editing component
-- behind [Textadept][] and [SciTE][]) traditionally uses static, compiled C++
-- lexers which are notoriously difficult to create and/or extend. On the other
-- hand, Lua makes it easy to to rapidly create new lexers, extend existing
-- ones, and embed lexers within one another. Lua lexers tend to be more
-- readable than C++ lexers too.
--
-- Lexers are Parsing Expression Grammars, or PEGs, composed with the Lua
-- [LPeg library][]. The following table comes from the LPeg documentation and
-- summarizes all you need to know about constructing basic LPeg patterns. This
-- module provides convenience functions for creating and working with other
-- more advanced patterns and concepts.
--
-- Operator             | Description
-- ---------------------|------------
-- `lpeg.P(string)`     | Matches `string` literally.
-- `lpeg.P(`_`n`_`)`    | Matches exactly _`n`_ characters.
-- `lpeg.S(string)`     | Matches any character in set `string`.
-- `lpeg.R("`_`xy`_`")` | Matches any character between range `x` and `y`.
-- `patt^`_`n`_         | Matches at least _`n`_ repetitions of `patt`.
-- `patt^-`_`n`_        | Matches at most _`n`_ repetitions of `patt`.
-- `patt1 * patt2`      | Matches `patt1` followed by `patt2`.
-- `patt1 + patt2`      | Matches `patt1` or `patt2` (ordered choice).
-- `patt1 - patt2`      | Matches `patt1` if `patt2` does not match.
-- `-patt`              | Equivalent to `("" - patt)`.
-- `#patt`              | Matches `patt` but consumes no input.
--
-- The first part of this document deals with rapidly constructing a simple
-- lexer. The next part deals with more advanced techniques, such as custom
-- coloring and embedding lexers within one another. Following that is a
-- discussion about code folding, or being able to tell Scintilla which code
-- blocks are "foldable" (temporarily hideable from view). After that are
-- instructions on how to use LPeg lexers with the aforementioned Textadept and
-- SciTE editors. Finally there are comments on lexer performance and
-- limitations.
--
-- [LPeg library]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
-- [Textadept]: http://foicica.com/textadept
-- [SciTE]: http://scintilla.org/SciTE.html
--
-- ## Lexer Basics
--
-- The *lexers/* directory contains all lexers, including your new one. Before
-- attempting to write one from scratch though, first determine if your
-- programming language is similar to any of the 80+ languages supported. If so,
-- you may be able to copy and modify that lexer, saving some time and effort.
-- The filename of your lexer should be the name of your programming language in
-- lower case followed by a *.lua* extension. For example, a new Lua lexer has
-- the name *lua.lua*.
--
-- Note: Try to refrain from using one-character language names like "b", "c",
-- or "d". For example, Scintillua uses "b_lang", "cpp", and "dmd",
-- respectively.
--
-- ### New Lexer Template
--
-- There is a *lexers/template.txt* file that contains a simple template for a
-- new lexer. Feel free to use it, replacing the '?'s with the name of your
-- lexer:
--
--     -- ? LPeg lexer.
--
--     local l = lexer
--     local token, word_match = l.token, l.word_match
--     local P, R, S = lpeg.P, lpeg.R, lpeg.S
--
--     local M = {_NAME = '?'}
--
--     -- Whitespace.
--     local ws = token(l.WHITESPACE, l.space^1)
--
--     M._rules = {
--       {'whitespace', ws},
--     }
--
--     M._tokenstyles = {
--
--     }
--
--     return M
--
-- The first 4 lines of code simply define often used convenience variables. The
-- 5th and last lines define and return the lexer object Scintilla uses; they
-- are very important and must be part of every lexer. The sixth line defines
-- something called a "token", an essential building block of lexers. You will
-- learn about tokens shortly. The rest of the code defines a set of grammar
-- rules and token styles. You will learn about those later. Note, however, the
-- `M.` prefix in front of `_rules` and `_tokenstyles`: not only do these tables
-- belong to their respective lexers, but any non-local variables need the `M.`
-- prefix too so-as not to affect Lua's global environment. All in all, this is
-- a minimal, working lexer that you can build on.
--
-- ### Tokens
--
-- Take a moment to think about your programming language's structure. What kind
-- of key elements does it have? In the template shown earlier, one predefined
-- element all languages have is whitespace. Your language probably also has
-- elements like comments, strings, and keywords. Lexers refer to these elements
-- as "tokens". Tokens are the fundamental "building blocks" of lexers. Lexers
-- break down source code into tokens for coloring, which results in the syntax
-- highlighting familiar to you. It is up to you how specific your lexer is when
-- it comes to tokens. Perhaps only distinguishing between keywords and
-- identifiers is necessary, or maybe recognizing constants and built-in
-- functions, methods, or libraries is desirable. The Lua lexer, for example,
-- defines 11 tokens: whitespace, comments, strings, numbers, keywords, built-in
-- functions, constants, built-in libraries, identifiers, labels, and operators.
-- Even though constants, built-in functions, and built-in libraries are subsets
-- of identifiers, Lua programmers find it helpful for the lexer to distinguish
-- between them all. It is perfectly acceptable to just recognize keywords and
-- identifiers.
--
-- In a lexer, tokens consist of a token name and an LPeg pattern that matches a
-- sequence of characters recognized as an instance of that token. Create tokens
-- using the [`token()`](#token) function. Let us examine the "whitespace" token
-- defined in the template shown earlier:
--
--     local ws = token(l.WHITESPACE, l.space^1)
--
-- At first glance, the first argument does not appear to be a string name and
-- the second argument does not appear to be an LPeg pattern. Perhaps you
-- expected something like:
--
--     local ws = token('whitespace', S('\t\v\f\n\r ')^1)
--
-- The `lexer` (`l`) module actually provides a convenient list of common token
-- names and common LPeg patterns for you to use. Token names include
-- [`DEFAULT`](#DEFAULT), [`WHITESPACE`](#WHITESPACE), [`COMMENT`](#COMMENT),
-- [`STRING`](#STRING), [`NUMBER`](#NUMBER), [`KEYWORD`](#KEYWORD),
-- [`IDENTIFIER`](#IDENTIFIER), [`OPERATOR`](#OPERATOR), [`ERROR`](#ERROR),
-- [`PREPROCESSOR`](#PREPROCESSOR), [`CONSTANT`](#CONSTANT),
-- [`VARIABLE`](#VARIABLE), [`FUNCTION`](#FUNCTION), [`CLASS`](#CLASS),
-- [`TYPE`](#TYPE), [`LABEL`](#LABEL), [`REGEX`](#REGEX), and
-- [`EMBEDDED`](#EMBEDDED). Patterns include [`any`](#any), [`ascii`](#ascii),
-- [`extend`](#extend), [`alpha`](#alpha), [`digit`](#digit), [`alnum`](#alnum),
-- [`lower`](#lower), [`upper`](#upper), [`xdigit`](#xdigit), [`cntrl`](#cntrl),
-- [`graph`](#graph), [`print`](#print), [`punct`](#punct), [`space`](#space),
-- [`newline`](#newline), [`nonnewline`](#nonnewline),
-- [`nonnewline_esc`](#nonnewline_esc), [`dec_num`](#dec_num),
-- [`hex_num`](#hex_num), [`oct_num`](#oct_num), [`integer`](#integer),
-- [`float`](#float), and [`word`](#word). You may use your own token names if
-- none of the above fit your language, but an advantage to using predefined
-- token names is that your lexer's tokens will inherit the universal syntax
-- highlighting color theme used by your text editor.
--
-- #### Example Tokens
--
-- So, how might you define other tokens like comments, strings, and keywords?
-- Here are some examples.
--
-- **Comments**
--
-- Line-style comments with a prefix character(s) are easy to express with LPeg:
--
--     local shell_comment = token(l.COMMENT, '#' * l.nonnewline^0)
--     local c_line_comment = token(l.COMMENT, '//' * l.nonnewline_esc^0)
--
-- The comments above start with a '#' or "//" and go to the end of the line.
-- The second comment recognizes the next line also as a comment if the current
-- line ends with a '\' escape character.
--
-- C-style "block" comments with a start and end delimiter are also easy to
-- express:
--
--     local c_comment = token(l.COMMENT, '/*' * (l.any - '*/')^0 * P('*/')^-1)
--
-- This comment starts with a "/\*" sequence and contains anything up to and
-- including an ending "\*/" sequence. The ending "\*/" is optional so the lexer
-- can recognize unfinished comments as comments and highlight them properly.
--
-- **Strings**
--
-- It is tempting to think that a string is not much different from the block
-- comment shown above in that both have start and end delimiters:
--
--     local dq_str = '"' * (l.any - '"')^0 * P('"')^-1
--     local sq_str = "'" * (l.any - "'")^0 * P("'")^-1
--     local simple_string = token(l.STRING, dq_str + sq_str)
--
-- However, most programming languages allow escape sequences in strings such
-- that a sequence like "\\&quot;" in a double-quoted string indicates that the
-- '&quot;' is not the end of the string. The above token incorrectly matches
-- such a string. Instead, use the [`delimited_range()`](#delimited_range)
-- convenience function.
--
--     local dq_str = l.delimited_range('"')
--     local sq_str = l.delimited_range("'")
--     local string = token(l.STRING, dq_str + sq_str)
--
-- In this case, the lexer treats '\' as an escape character in a string
-- sequence.
--
-- **Keywords**
--
-- Instead of matching _n_ keywords with _n_ `P('keyword_`_`n`_`')` ordered
-- choices, use another convenience function: [`word_match()`](#word_match). It
-- is much easier and more efficient to write word matches like:
--
--     local keyword = token(l.KEYWORD, l.word_match{
--       'keyword_1', 'keyword_2', ..., 'keyword_n'
--     })
--
--     local case_insensitive_keyword = token(l.KEYWORD, l.word_match({
--       'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
--     }, nil, true))
--
--     local hyphened_keyword = token(l.KEYWORD, l.word_match({
--       'keyword-1', 'keyword-2', ..., 'keyword-n'
--     }, '-'))
--
-- By default, characters considered to be in keywords are in the set of
-- alphanumeric characters and underscores. The last token demonstrates how to
-- allow '-' (hyphen) characters to be in keywords as well.
--
-- **Numbers**
--
-- Most programming languages have the same format for integer and float tokens,
-- so it might be as simple as using a couple of predefined LPeg patterns:
--
--     local number = token(l.NUMBER, l.float + l.integer)
--
-- However, some languages allow postfix characters on integers.
--
--     local integer = P('-')^-1 * (l.dec_num * S('lL')^-1)
--     local number = token(l.NUMBER, l.float + l.hex_num + integer)
--
-- Your language may need other tweaks, but it is up to you how fine-grained you
-- want your highlighting to be. After all, you are not writing a compiler or
-- interpreter!
--
-- ### Rules
--
-- Programming languages have grammars, which specify valid token structure. For
-- example, comments usually cannot appear within a string. Grammars consist of
-- rules, which are simply combinations of tokens. Recall from the lexer
-- template the `_rules` table, which defines all the rules used by the lexer
-- grammar:
--
--     M._rules = {
--       {'whitespace', ws},
--     }
--
-- Each entry in a lexer's `_rules` table consists of a rule name and its
-- associated pattern. Rule names are completely arbitrary and serve only to
-- identify and distinguish between different rules. Rule order is important: if
-- text does not match the first rule, the lexer tries the second rule, and so
-- on. This simple grammar says to match whitespace tokens under a rule named
-- "whitespace".
--
-- To illustrate the importance of rule order, here is an example of a
-- simplified Lua grammar:
--
--     M._rules = {
--       {'whitespace', ws},
--       {'keyword', keyword},
--       {'identifier', identifier},
--       {'string', string},
--       {'comment', comment},
--       {'number', number},
--       {'label', label},
--       {'operator', operator},
--     }
--
-- Note how identifiers come after keywords. In Lua, as with most programming
-- languages, the characters allowed in keywords and identifiers are in the same
-- set (alphanumerics plus underscores). If the lexer specified the "identifier"
-- rule before the "keyword" rule, all keywords would match identifiers and thus
-- incorrectly highlight as identifiers instead of keywords. The same idea
-- applies to function, constant, etc. tokens that you may want to distinguish
-- between: their rules should come before identifiers.
--
-- So what about text that does not match any rules? For example in Lua, the '!'
-- character is meaningless outside a string or comment. Normally the lexer
-- skips over such text. If instead you want to highlight these "syntax errors",
-- add an additional end rule:
--
--     M._rules = {
--       {'whitespace', ws},
--       {'error', token(l.ERROR, l.any)},
--     }
--
-- This identifies and highlights any character not matched by an existing
-- rule as an `ERROR` token.
--
-- Even though the rules defined in the examples above contain a single token,
-- rules may consist of multiple tokens. For example, a rule for an HTML tag
-- could consist of a tag token followed by an arbitrary number of attribute
-- tokens, allowing the lexer to highlight all tokens separately. The rule might
-- look something like this:
--
--     {'tag', tag_start * (ws * attributes)^0 * tag_end^-1}
--
-- Note however that lexers with complex rules like these are more prone to lose
-- track of their state.
--
-- ### Summary
--
-- Lexers primarily consist of tokens and grammar rules. At your disposal are a
-- number of convenience patterns and functions for rapidly creating a lexer. If
-- you choose to use predefined token names for your tokens, you do not have to
-- define how the lexer highlights them. The tokens will inherit the default
-- syntax highlighting color theme your editor uses.
--
-- ## Advanced Techniques
--
-- ### Styles and Styling
--
-- The most basic form of syntax highlighting is assigning different colors to
-- different tokens. Instead of highlighting with just colors, Scintilla allows
-- for more rich highlighting, or "styling", with different fonts, font sizes,
-- font attributes, and foreground and background colors, just to name a few.
-- The unit of this rich highlighting is called a "style". Styles are simply
-- strings of comma-separated property settings. By default, lexers associate
-- predefined token names like `WHITESPACE`, `COMMENT`, `STRING`, etc. with
-- particular styles as part of a universal color theme. These predefined styles
-- include [`STYLE_CLASS`](#STYLE_CLASS), [`STYLE_COMMENT`](#STYLE_COMMENT),
-- [`STYLE_CONSTANT`](#STYLE_CONSTANT), [`STYLE_ERROR`](#STYLE_ERROR),
-- [`STYLE_EMBEDDED`](#STYLE_EMBEDDED), [`STYLE_FUNCTION`](#STYLE_FUNCTION),
-- [`STYLE_IDENTIFIER`](#STYLE_IDENTIFIER), [`STYLE_KEYWORD`](#STYLE_KEYWORD),
-- [`STYLE_LABEL`](#STYLE_LABEL), [`STYLE_NUMBER`](#STYLE_NUMBER),
-- [`STYLE_OPERATOR`](#STYLE_OPERATOR),
-- [`STYLE_PREPROCESSOR`](#STYLE_PREPROCESSOR), [`STYLE_REGEX`](#STYLE_REGEX),
-- [`STYLE_STRING`](#STYLE_STRING), [`STYLE_TYPE`](#STYLE_TYPE),
-- [`STYLE_VARIABLE`](#STYLE_VARIABLE), and
-- [`STYLE_WHITESPACE`](#STYLE_WHITESPACE). Like with predefined token names
-- and LPeg patterns, you may define your own styles. At their core, styles are
-- just strings, so you may create new ones and/or modify existing ones. Each
-- style consists of the following comma-separated settings:
--
-- Setting        | Description
-- ---------------|------------
-- font:_name_    | The name of the font the style uses.
-- size:_int_     | The size of the font the style uses.
-- [not]bold      | Whether or not the font face is bold.
-- [not]italics   | Whether or not the font face is italic.
-- [not]underlined| Whether or not the font face is underlined.
-- fore:_color_   | The foreground color of the font face.
-- back:_color_   | The background color of the font face.
-- [not]eolfilled | Does the background color extend to the end of the line?
-- case:_char_    | The case of the font ('u': upper, 'l': lower, 'm': normal).
-- [not]visible   | Whether or not the text is visible.
-- [not]changeable| Whether the text is changeable or read-only.
-- [not]hotspot   | Whether or not the text is clickable.
--
-- Specify font colors in either "#RRGGBB" format, "0xBBGGRR" format, or the
-- decimal equivalent of the latter. As with token names, LPeg patterns, and
-- styles, there is a set of predefined color names, but they vary depending on
-- the current color theme in use. Therefore, it is generally not a good idea to
-- manually define colors within styles in your lexer since they might not fit
-- into a user's chosen color theme. Try to refrain from even using predefined
-- colors in a style because that color may be theme-specific. Instead, the best
-- practice is to either use predefined styles or derive new color-agnostic
-- styles from predefined ones. For example, Lua "longstring" tokens use the
-- existing `STYLE_STRING` style instead of defining a new one.
--
-- #### Example Styles
--
-- Defining styles is pretty straightforward. An empty style that inherits the
-- default theme settings is simply an empty string:
--
--     local style_nothing = ''
--
-- A similar style but with a bold font face looks like this:
--
--     local style_bold = 'bold'
--
-- If you want the same style, but also with an italic font face, define the new
-- style in terms of the old one:
--
--     local style_bold_italic = style_bold..',italics'
--
-- This allows you to derive new styles from predefined ones without having to
-- rewrite them. This operation leaves the old style unchanged. Thus if you
-- had a "static variable" token whose style you wanted to base off of
-- `STYLE_VARIABLE`, it would probably look like:
--
--     local style_static_var = l.STYLE_VARIABLE..',italics'
--
-- The color theme files in the *lexers/themes/* folder give more examples of
-- style definitions.
--
-- ### Token Styles
--
-- Lexers use the `_tokenstyles` table to assign tokens to particular styles.
-- Recall the token definition and `_tokenstyles` table from the lexer template:
--
--     local ws = token(l.WHITESPACE, l.space^1)
--
--     ...
--
--     M._tokenstyles = {
--
--     }
--
-- Why is a style not assigned to the `WHITESPACE` token? As mentioned earlier,
-- lexers automatically associate tokens that use predefined token names with a
-- particular style. Only tokens with custom token names need manual style
-- associations. As an example, consider a custom whitespace token:
--
--     local ws = token('custom_whitespace', l.space^1)
--
-- Assigning a style to this token looks like:
--
--     M._tokenstyles = {
--       custom_whitespace = l.STYLE_WHITESPACE
--     }
--
-- Do not confuse token names with rule names. They are completely different
-- entities. In the example above, the lexer assigns the "custom_whitespace"
-- token the existing style for `WHITESPACE` tokens. If instead you want to
-- color the background of whitespace a shade of grey, it might look like:
--
--     local custom_style = l.STYLE_WHITESPACE..',back:$(color.grey)'
--     M._tokenstyles = {
--       custom_whitespace = custom_style
--     }
--
-- Notice that the lexer peforms Scintilla/SciTE-style "$()" property expansion.
-- You may also use "%()". Remember to refrain from assigning specific colors in
-- styles, but in this case, all user color themes probably define the
-- "color.grey" property.
--
-- ### Line Lexers
--
-- By default, lexers match the arbitrary chunks of text passed to them by
-- Scintilla. These chunks may be a full document, only the visible part of a
-- document, or even just portions of lines. Some lexers need to match whole
-- lines. For example, a lexer for the output of a file "diff" needs to know if
-- the line started with a '+' or '-' and then style the entire line
-- accordingly. To indicate that your lexer matches by line, use the
-- `_LEXBYLINE` field:
--
--     M._LEXBYLINE = true
--
-- Now the input text for the lexer is a single line at a time. Keep in mind
-- that line lexers do not have the ability to look ahead at subsequent lines.
--
-- ### Embedded Lexers
--
-- Lexers embed within one another very easily, requiring minimal effort. In the
-- following sections, the lexer being embedded is called the "child" lexer and
-- the lexer a child is being embedded in is called the "parent". For example,
-- consider an HTML lexer and a CSS lexer. Either lexer stands alone for styling
-- their respective HTML and CSS files. However, CSS can be embedded inside
-- HTML. In this specific case, the CSS lexer is the "child" lexer with the HTML
-- lexer being the "parent". Now consider an HTML lexer and a PHP lexer. This
-- sounds a lot like the case with CSS, but there is a subtle difference: PHP
-- _embeds itself_ into HTML while CSS is _embedded in_ HTML. This fundamental
-- difference results in two types of embedded lexers: a parent lexer that
-- embeds other child lexers in it (like HTML embedding CSS), and a child lexer
-- that embeds itself within a parent lexer (like PHP embedding itself in HTML).
--
-- #### Parent Lexer
--
-- Before embedding a child lexer into a parent lexer, the parent lexer needs to
-- load the child lexer. This is done with the [`load()`](#load) function. For
-- example, loading the CSS lexer within the HTML lexer looks like:
--
--     local css = l.load('css')
--
-- The next part of the embedding process is telling the parent lexer when to
-- switch over to the child lexer and when to switch back. The lexer refers to
-- these indications as the "start rule" and "end rule", respectively, and are
-- just LPeg patterns. Continuing with the HTML/CSS example, the transition from
-- HTML to CSS is when the lexer encounters a "style" tag with a "type"
-- attribute whose value is "text/css":
--
--     local css_tag = P('<style') * P(function(input, index)
--       if input:find('^[^>]+type="text/css"', index) then
--         return index
--       end
--     end)
--
-- This pattern looks for the beginning of a "style" tag and searches its
-- attribute list for the text "`type="text/css"`". (In this simplified example,
-- the Lua pattern does not consider whitespace between the '=' nor does it
-- consider that using single quotes is valid.) If there is a match, the
-- functional pattern returns a value instead of `nil`. In this case, the value
-- returned does not matter because we ultimately want to style the "style" tag
-- as an HTML tag, so the actual start rule looks like this:
--
--     local css_start_rule = #css_tag * tag
--
-- Now that the parent knows when to switch to the child, it needs to know when
-- to switch back. In the case of HTML/CSS, the switch back occurs when the
-- lexer encounters an ending "style" tag, though the lexer should still style
-- the tag as an HTML tag:
--
--     local css_end_rule = #P('</style>') * tag
--
-- Once the parent loads the child lexer and defines the child's start and end
-- rules, it embeds the child with the [`embed_lexer()`](#embed_lexer) function:
--
--     l.embed_lexer(M, css, css_start_rule, css_end_rule)
--
-- The first parameter is the parent lexer object to embed the child in, which
-- in this case is `M`. The other three parameters are the child lexer object
-- loaded earlier followed by its start and end rules.
--
-- #### Child Lexer
--
-- The process for instructing a child lexer to embed itself into a parent is
-- very similar to embedding a child into a parent: first, load the parent lexer
-- into the child lexer with the [`load()`](#load) function and then create
-- start and end rules for the child lexer. However, in this case, swap the
-- lexer object arguments to [`embed_lexer()`](#embed_lexer). For example, in
-- the PHP lexer:
--
--     local html = l.load('hypertext')
--     local php_start_rule = token('php_tag', '<?php ')
--     local php_end_rule = token('php_tag', '?>')
--     l.embed_lexer(html, M, php_start_rule, php_end_rule)
--
-- ## Code Folding
--
-- When reading source code, it is occasionally helpful to temporarily hide
-- blocks of code like functions, classes, comments, etc. This is the concept of
-- "folding". In the Textadept and SciTE editors for example, little indicators
-- in the editor margins appear next to code that can be folded at places called
-- "fold points". When the user clicks an indicator, the editor hides the code
-- associated with the indicator until the user clicks the indicator again. The
-- lexer specifies these fold points and what code exactly to fold.
--
-- The fold points for most languages occur on keywords or character sequences.
-- Examples of fold keywords are "if" and "end" in Lua and examples of fold
-- character sequences are '{', '}', "/\*", and "\*/" in C for code block and
-- comment delimiters, respectively. However, these fold points cannot occur
-- just anywhere. For example, lexers should not recognize fold keywords that
-- appear within strings or comments. The lexer's `_foldsymbols` table allows
-- you to conveniently define fold points with such granularity. For example,
-- consider C:
--
--     M._foldsymbols = {
--       [l.OPERATOR] = {['{'] = 1, ['}'] = -1},
--       [l.COMMENT] = {['/*'] = 1, ['*/'] = -1},
--       _patterns = {'[{}]', '/%*', '%*/'}
--     }
--
-- The first assignment states that any '{' or '}' that the lexer recognized as
-- an `OPERATOR` token is a fold point. The integer `1` indicates the match is
-- a beginning fold point and `-1` indicates the match is an ending fold point.
-- Likewise, the second assignment states that any "/\*" or "\*/" that the lexer
-- recognizes as part of a `COMMENT` token is a fold point. The lexer does not
-- consider any occurences of these characters outside their defined tokens
-- (such as in a string) as fold points. Finally, every `_foldsymbols` table
-- must have a `_patterns` field that contains a list of [Lua patterns][] that
-- match fold points. If the lexer encounters text that matches one of those
-- patterns, the lexer looks up the matched text in its token's table to
-- determine whether or not the text is a fold point. In the example above, the
-- first Lua pattern matches any '{' or '}' characters. When the lexer comes
-- across one of those characters, it checks if the match is an `OPERATOR`
-- token. If so, the lexer identifies the match as a fold point. The same idea
-- applies for the other patterns. (The '%' is in the other patterns because
-- '\*' is a special character in Lua patterns that needs escaping.) How do you
-- specify fold keywords? Here is an example for Lua:
--
--     M._foldsymbols = {
--       [l.KEYWORD] = {
--         ['if'] = 1, ['do'] = 1, ['function'] = 1,
--         ['end'] = -1, ['repeat'] = 1, ['until'] = -1
--       },
--       _patterns = {'%l+'}
--     }
--
-- Any time the lexer encounters a lower case word, if that word is a `KEYWORD`
-- token and in the associated list of fold points, the lexer identifies the
-- word as a fold point.
--
-- If your lexer needs to do some additional processing to determine if a match
-- is a fold point, assign a function that returns an integer. Returning `1` or
-- `-1` indicates the match is a fold point. Returning `0` indicates it is not.
-- For example:
--
--     local function fold_strange_token(text, pos, line, s, match)
--       if ... then
--         return 1 -- beginning fold point
--       elseif ... then
--         return -1 -- ending fold point
--       end
--       return 0
--     end
--
--     M._foldsymbols = {
--       ['strange_token'] = {['|'] = fold_strange_token},
--       _patterns = {'|'}
--     }
--
-- Any time the lexer encounters a '|' that is a "strange_token", it calls the
-- `fold_strange_token` function to determine if '|' is a fold point. The lexer
-- calls these functions with the following arguments: the text to fold, the
-- position of the start of the current line in the text to fold, the current
-- line's text, the position in the current line the matched text starts at, and
-- the matched text itself.
--
-- [Lua patterns]: http://www.lua.org/manual/5.2/manual.html#6.4.1
--
-- ## Using Lexers
--
-- ### Textadept
--
-- Put your lexer in your *~/.textadept/lexers/* directory so you do not
-- overwrite it when upgrading Textadept. Also, lexers in this directory
-- override default lexers. Thus, Textadept loads a user *lua* lexer instead of
-- the default *lua* lexer. This is convenient for tweaking a default lexer to
-- your liking. Then add a [file type][] for your lexer if necessary.
--
-- [file type]: _M.textadept.file_types.html
--
-- ### SciTE
--
-- Create a *.properties* file for your lexer and `import` it in either your
-- *SciTEUser.properties* or *SciTEGlobal.properties*. The contents of the
-- *.properties* file should contain:
--
--     file.patterns.[lexer_name]=[file_patterns]
--     lexer.$(file.patterns.[lexer_name])=[lexer_name]
--
-- where `[lexer_name]` is the name of your lexer (minus the *.lua* extension)
-- and `[file_patterns]` is a set of file extensions to use your lexer for.
--
-- Please note that Lua lexers ignore any styling information in *.properties*
-- files. Your theme file in the *lexers/themes/* directory contains styling
-- information.
--
-- ## Considerations
--
-- ### Performance
--
-- There might be some slight overhead when initializing a lexer, but loading a
-- file from disk into Scintilla is usually more expensive. On modern computer
-- systems, I see no difference in speed between LPeg lexers and Scintilla's C++
-- ones. Optimize lexers for speed by re-arranging rules in the `_rules` table
-- so that the most common rules match first. Do keep in mind that order matters
-- for similar rules.
--
-- ### Limitations
--
-- Embedded preprocessor languages like PHP cannot completely embed in their
-- parent languages in that the parent's tokens do not support start and end
-- rules. This mostly goes unnoticed, but code like
--
--     <div id="<?php echo $id; ?>">
--
-- or
--
--     <div <?php if ($odd) { echo 'class="odd"'; } ?>>
--
-- will not style correctly.
--
-- ### Troubleshooting
--
-- Errors in lexers can be tricky to debug. Lexers print Lua errors to
-- `io.stderr` and `_G.print()` statements to `io.stdout`. Running your editor
-- from a terminal is the easiest way to see errors as they occur.
--
-- ### Risks
--
-- Poorly written lexers have the ability to crash Scintilla (and thus its
-- containing application), so unsaved data might be lost. However, I have only
-- observed these crashes in early lexer development, when syntax errors or
-- pattern errors are present. Once the lexer actually starts styling text
-- (either correctly or incorrectly, it does not matter), I have not observed
-- any crashes.
--
-- ### Acknowledgements
--
-- Thanks to Peter Odding for his [lexer post][] on the Lua mailing list
-- that inspired me, and thanks to Roberto Ierusalimschy for LPeg.
--
-- [lexer post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html
-- @field DEFAULT (string)
--   The token name for default tokens.
-- @field WHITESPACE (string)
--   The token name for whitespace tokens.
-- @field COMMENT (string)
--   The token name for comment tokens.
-- @field STRING (string)
--   The token name for string tokens.
-- @field NUMBER (string)
--   The token name for number tokens.
-- @field KEYWORD (string)
--   The token name for keyword tokens.
-- @field IDENTIFIER (string)
--   The token name for identifier tokens.
-- @field OPERATOR (string)
--   The token name for operator tokens.
-- @field ERROR (string)
--   The token name for error tokens.
-- @field PREPROCESSOR (string)
--   The token name for preprocessor tokens.
-- @field CONSTANT (string)
--   The token name for constant tokens.
-- @field VARIABLE (string)
--   The token name for variable tokens.
-- @field FUNCTION (string)
--   The token name for function tokens.
-- @field CLASS (string)
--   The token name for class tokens.
-- @field TYPE (string)
--   The token name for type tokens.
-- @field LABEL (string)
--   The token name for label tokens.
-- @field REGEX (string)
--   The token name for regex tokens.
-- @field STYLE_CLASS (string)
--   The style typically used for class definitions.
-- @field STYLE_COMMENT (string)
--   The style typically used for code comments.
-- @field STYLE_CONSTANT (string)
--   The style typically used for constants.
-- @field STYLE_ERROR (string)
--   The style typically used for erroneous syntax.
-- @field STYLE_FUNCTION (string)
--   The style typically used for function definitions.
-- @field STYLE_KEYWORD (string)
--   The style typically used for language keywords.
-- @field STYLE_LABEL (string)
--   The style typically used for labels.
-- @field STYLE_NUMBER (string)
--   The style typically used for numbers.
-- @field STYLE_OPERATOR (string)
--   The style typically used for operators.
-- @field STYLE_REGEX (string)
--   The style typically used for regular expression strings.
-- @field STYLE_STRING (string)
--   The style typically used for strings.
-- @field STYLE_PREPROCESSOR (string)
--   The style typically used for preprocessor statements.
-- @field STYLE_TYPE (string)
--   The style typically used for static types.
-- @field STYLE_VARIABLE (string)
--   The style typically used for variables.
-- @field STYLE_WHITESPACE (string)
--   The style typically used for whitespace.
-- @field STYLE_EMBEDDED (string)
--   The style typically used for embedded code.
-- @field STYLE_IDENTIFIER (string)
--   The style typically used for identifier words.
-- @field STYLE_DEFAULT (string)
--   The style all styles are based off of.
-- @field STYLE_LINENUMBER (string)
--   The style used for all margins except fold margins.
-- @field STYLE_BRACELIGHT (string)
--   The style used for highlighted brace characters.
-- @field STYLE_BRACEBAD (string)
--   The style used for unmatched brace characters.
-- @field STYLE_CONTROLCHAR (string)
--   The style used for control characters.
--   Color attributes are ignored.
-- @field STYLE_INDENTGUIDE (string)
--   The style used for indentation guides.
-- @field STYLE_CALLTIP (string)
--   The style used by call tips if `buffer.call_tip_use_style` is set.
--   Only the font name, size, and color attributes are used.
-- @field any (pattern)
--   A pattern that matches any single character.
-- @field ascii (pattern)
--   A pattern that matches any ASCII character (codes 0 to 127).
-- @field extend (pattern)
--   A pattern that matches any ASCII extended character (codes 0 to 255).
-- @field alpha (pattern)
--   A pattern that matches any alphabetic character ('A'-'Z', 'a'-'z').
-- @field digit (pattern)
--   A pattern that matches any digit ('0'-'9').
-- @field alnum (pattern)
--   A pattern that matches any alphanumeric character ('A'-'Z', 'a'-'z',
--     '0'-'9').
-- @field lower (pattern)
--   A pattern that matches any lower case character ('a'-'z').
-- @field upper (pattern)
--   A pattern that matches any upper case character ('A'-'Z').
-- @field xdigit (pattern)
--   A pattern that matches any hexadecimal digit ('0'-'9', 'A'-'F', 'a'-'f').
-- @field cntrl (pattern)
--   A pattern that matches any control character (ASCII codes 0 to 31).
-- @field graph (pattern)
--   A pattern that matches any graphical character ('!' to '~').
-- @field print (pattern)
--   A pattern that matches any printable character (' ' to '~').
-- @field punct (pattern)
--   A pattern that matches any punctuation character not alphanumeric ('!' to
--   '/', ':' to '@', '[' to ''', '{' to '~').
-- @field space (pattern)
--   A pattern that matches any whitespace character ('\t', '\v', '\f', '\n',
--   '\r', space).
-- @field newline (pattern)
--   A pattern that matches any newline characters.
-- @field nonnewline (pattern)
--   A pattern that matches any non-newline character.
-- @field nonnewline_esc (pattern)
--   A pattern that matches any non-newline character, excluding newlines
--   escaped with '\'.
-- @field dec_num (pattern)
--   A pattern that matches a decimal number.
-- @field hex_num (pattern)
--   A pattern that matches a hexadecimal number.
-- @field oct_num (pattern)
--   A pattern that matches an octal number.
-- @field integer (pattern)
--   A pattern that matches a decimal, hexadecimal, or octal number.
-- @field float (pattern)
--   A pattern that matches a floating point number.
-- @field word (pattern)
--   A pattern that matches a typical word starting with a letter or underscore
--   and then any alphanumeric or underscore characters.
-- @field FOLD_BASE (number)
--   The initial (root) fold level.
-- @field FOLD_BLANK (number)
--   Flag indicating that the line is blank.
-- @field FOLD_HEADER (number)
--   Flag indicating the line is fold point.
-- @field fold_level (table, Read-only)
--   Table of fold level bit-masks for line numbers starting from zero.
--   Fold level masks are composed of an integer level combined with any of the
--   following bits:
--
--   * `lexer.FOLDBASE`
--     The initial fold level.
--   * `lexer.FOLD_BLANK`
--     The line is blank.
--   * `lexer.FOLD_HEADER`
--     The line is a header, or fold point.
-- @field indent_amount (table, Read-only)
--   Table of indentation amounts in character columns, for line numbers
--   starting from zero.
-- @field property (table)
--   Map of key-value string pairs.
-- @field property_expanded (table, Read-only)
--   Map of key-value string pairs with `$()` and `%()` variable replacement
--   performed in values.
-- @field property_int (table, Read-only)
--   Map of key-value pairs with values interpreted as numbers, or `0` if not
--   found.
-- @field style_at (table, Read-only)
--   Table of style names at positions in the buffer starting from zero.
module('lexer')]=]

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

local num_styles
-- Adds a new Scintilla style to Scintilla.
-- @param lexer The lexer to add the given style to.
-- @param token_name The name of the token associated with this style.
-- @param style A Scintilla style created from `style()`.
-- @see style
local function add_style(lexer, token_name, style)
  if num_styles == 32 then num_styles = num_styles + 8 end -- skip predefined
  if num_styles >= 255 then print('Too many styles defined (255 MAX)') end
  -- Since parent lexers inherit child lexer tokens and styles, ensure the style
  -- is not added again since the child added it first.
  if not lexer._TOKENS[token_name] then
    lexer._TOKENS[token_name], num_styles = num_styles, num_styles + 1
    M.property['style.'..token_name] = style
  end
end

-- (Re)constructs `lexer._TOKENRULE`.
-- @param parent The parent lexer.
local function join_tokens(lexer)
  local patterns, order = lexer._RULES, lexer._RULEORDER
  local token_rule = patterns[order[1]]
  for i = 2, #order do token_rule = token_rule + patterns[order[i]] end
  lexer._TOKENRULE = token_rule + M.token(M.DEFAULT, M.any)
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
  nothing      = 0,
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
  embedded     = 17,
  -- Predefined styles.
  default      = 32,
  linenumber   = 33,
  bracelight   = 34,
  bracebad     = 35,
  controlchar  = 36,
  indentguide  = 37,
  calltip      = 38,
}
num_styles = 18 -- 0 to 17 are used
local string_upper = string.upper
for k in pairs(tokens) do
  local K = string_upper(k)
  M[K], M['STYLE_'..K] = k, '$(style.'..k..')'
end

---
-- Initializes or loads lexer *lexer_name* and returns the lexer object.
-- Scintilla calls this function to load a lexer. Parent lexers also call this
-- function to load child lexers and vice-versa.
-- @param lexer_name The name of the lexing language.
-- @param alt_name The alternate name of the lexing language. This is useful for
--   embedding the same child lexer with multiple sets of start and end tokens.
-- @return lexer object
-- @name load
function M.load(lexer_name, alt_name)
  -- Load the lexer module with its rules, styles, etc.
  package.loaded['lexers.'..lexer_name] = nil
  M.WHITESPACE = (alt_name or lexer_name)..'_whitespace'
  local lexer = require('lexers.'..lexer_name or 'null')
  if alt_name then lexer._NAME = alt_name end
  lexer._TOKENS = tokens
  -- If the lexer is a proxy (loads parent and child lexers to embed) and does
  -- not declare a parent, try and find one and use its rules.
  if not lexer._rules and not lexer._lexer then
    for m, l in pairs(package.loaded) do
      if m:match'^lexers%.' and m ~= 'lexers.lexer' then
			if l._CHILDREN then lexer._lexer = l end
		end
    end
  end
  -- If the lexer is a proxy or a child that embedded itself, add its rules and
  -- styles to the parent lexer. Then set the parent to be the main lexer.
  if lexer._lexer then
    local l, _r, _s = lexer._lexer, lexer._rules, lexer._tokenstyles
    if not l._tokenstyles then l._tokenstyles = {} end
    for _, r in ipairs(_r or {}) do
      -- Prevent rule id clashes.
      l._rules[#l._rules + 1] = {lexer._NAME..'_'..r[1], r[2]}
    end
    for token, style in pairs(_s or {}) do l._tokenstyles[token] = style end
    lexer = l
  end
  -- Add the lexer's styles and build its grammar.
  if lexer._rules then
    for token, style in pairs(lexer._tokenstyles or {}) do
      add_style(lexer, token, style)
    end
    for _, r in ipairs(lexer._rules) do add_rule(lexer, r[1], r[2]) end
    build_grammar(lexer)
  end
  -- Add the lexer's unique whitespace style.
  add_style(lexer, lexer._NAME..'_whitespace', M.STYLE_WHITESPACE)
  -- Process the lexer's fold symbols.
  if lexer._foldsymbols and lexer._foldsymbols._patterns then
    local patterns = lexer._foldsymbols._patterns
    for i = 1, #patterns do patterns[i] = '()('..patterns[i]..')' end
  end
  -- Finished.
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
  local fold = M.property_int['fold'] > 0
  local lexer = _G._LEXER
  local FOLD_BASE = M.FOLD_BASE
  local FOLD_HEADER, FOLD_BLANK  = M.FOLD_HEADER, M.FOLD_BLANK
  if fold and lexer._fold then
    return lexer._fold(text, start_pos, start_line, start_level)
  elseif fold and lexer._foldsymbols then
    local lines = {}
    for p, l in text:gmatch('()(.-)\r?\n') do lines[#lines + 1] = {p, l} end
    lines[#lines + 1] = {text:match('()([^\r\n]*)$')}
    local fold_symbols = lexer._foldsymbols
    local fold_symbols_patterns = fold_symbols._patterns
    local style_at = M.style_at
    local line_num, prev_level = start_line, start_level
    local current_level = prev_level
    for i = 1, #lines do
      local pos, line = lines[i][1], lines[i][2]
      if line ~= '' then
        for j = 1, #fold_symbols_patterns do
          for s, match in line:gmatch(fold_symbols_patterns[j]) do
            local symbols = fold_symbols[style_at[start_pos + pos + s - 1]]
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
  elseif fold and M.property_int['fold.by.indentation'] > 0 then
    local indent_amount = M.indent_amount
    -- Indentation based folding.
    local current_line, prev_level = start_line, start_level
    for _, line in text:gmatch('([\t ]*)(.-)\r?\n') do
      if line ~= '' then
        local current_level = FOLD_BASE + indent_amount[current_line]
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

---
-- Creates and returns a pattern that matches a range of text bounded by
-- *chars* characters.
-- This is a convenience function for matching more complicated delimited ranges
-- like strings with escape characters and balanced parentheses. *single_line*
-- indicates whether or not ranges must be on a single line, *no_escape*
-- indicates whether or not to treat '\' character as an escape character, and
-- *balanced* indicates whether or not to handle balanced ranges like
-- parentheses and requires *chars* to be composed of two characters.
-- @param chars The character(s) that bound the matched range.
-- @param single_line Optional flag indicating whether or not the range must be
--   on a single line.
-- @param no_escape Optional flag indicating whether or not the range end
--   character may be escaped by a '\\' character.
-- @param balanced Optional flag indicating whether or not to match a balanced
--   range, like the "%b" Lua pattern. This flag only applies if *chars*
--   consists of two different characters (e.g. "()").
-- @return pattern
-- @usage local dq_str_escapes = l.delimited_range('"')
-- @usage local dq_str_noescapes = l.delimited_range('"', false, true)
-- @usage local unbalanced_parens = l.delimited_range('()')
-- @usage local balanced_parens = l.delimited_range('()', false, false, true)
-- @see nested_pair
-- @name delimited_range
function M.delimited_range(chars, single_line, no_escape, balanced)
  local s = chars:sub(1, 1)
  local e = #chars == 2 and chars:sub(2, 2) or s
  local range
  local b = balanced and s or ''
  local n = single_line and '\n' or ''
  if no_escape then
    local invalid = lpeg_S(e..n..b)
    range = M.any - invalid
  else
    local invalid = lpeg_S(e..n..b) + '\\'
    range = M.any - invalid + '\\' * M.any
  end
  if balanced and s ~= e then
    return lpeg_P{s * (range + lpeg_V(1))^0 * e}
  else
    return s * range^0 * lpeg_P(e)^-1
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
--   l.delimited_range('/')
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
-- delimiters *start_chars* and *end_chars*.
-- With single-character delimiters, this function is identical to
-- `delimited_range(start_chars..end_chars, false, true, true)`.
-- @param start_chars The string starting a nested sequence.
-- @param end_chars The string ending a nested sequence.
-- @return pattern
-- @usage local nested_comment = l.nested_pair('/*', '*/')
-- @see delimited_range
-- @name nested_pair
function M.nested_pair(start_chars, end_chars)
  local s, e = start_chars, lpeg_P(end_chars)^-1
  return lpeg_P{s * (M.any - s - end_chars + lpeg_V(1))^0 * e}
end

---
-- Creates and returns a pattern that matches any word in set *words*
-- case-sensitively, unless *case_insensitive* is `true`, with the set of word
-- characters being alphanumerics, underscores, and all of the characters in
-- string *word_chars*.
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
-- Embeds child lexer *child* in parent *parent* with *start_rule* and
-- *end_rule*, patterns that signal the beginning and end of the embedded lexer,
-- respectively.
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
  tokenstyles[child._NAME..'_whitespace'] = M.STYLE_WHITESPACE
  for token, style in pairs(child._tokenstyles or {}) do
    tokenstyles[token] = style
  end
  child._lexer = parent -- use parent's tokens if child is embedding itself
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
  local property_int = M.property_int
  return function(text, pos, line, s)
    if property_int['fold.line.comments'] == 0 then return 0 end
    if s > 1 and line:match('^%s*()') < s then return 0 end
    local prev_line_comment = prev_line_is_comment(prefix, text, pos, line, s)
    local next_line_comment = next_line_is_comment(prefix, text, pos, line, s)
    if not prev_line_comment and next_line_comment then return 1 end
    if prev_line_comment and not next_line_comment then return -1 end
    return 0
  end
end

M.property_expanded = setmetatable({}, {
  -- Returns the string property value associated with string property *key*,
  -- replacing any "$()" and "%()" expressions with the values of their keys.
  __index = function(t, key)
    return M.property[key]:gsub('[$%%]%b()', function(key)
      return t[key:sub(3, -2)]
    end)
  end,
  __newindex = function() error('read-only property') end
})

--[[ The functions and fields below were defined in C.

---
-- Individual lexer fields.
-- @field _NAME The string name of the lexer.
-- @field _rules An ordered list of rules for a lexer grammar.
--   Each rule is a table containing an arbitrary rule name and the LPeg pattern
--   associated with the rule. The order of rules is important as rules are
--   matched sequentially.
--   Child lexers should not use this table to access and/or modify their
--   parent's rules and vice-versa. Use the `_RULES` table instead.
-- @field _tokenstyles A map of non-predefined token names to styles.
--   Remember to use token names, not rule names. It is recommended to use
--   predefined styles or color-agnostic styles derived from predefined styles
--   to ensure compatibility with user color themes.
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
-- @field _lexer The parent lexer object whose rules should be used. This field
--   is only necessary to disambiguate a proxy lexer that loaded parent and
--   child lexers for embedding and ended up having multiple parents loaded.
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
]]

return M
