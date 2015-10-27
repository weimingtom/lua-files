v1.0 | [binding](http://code.google.com/p/lua-files/source/browse/libunibreak.lua) | [demo](http://code.google.com/p/lua-files/source/browse/libunibreak_demo.lua) |libunibreak 0.6.21 | LuaJIT 2
## `local ub = require'libunibreak'` ##

A ffi binding to [libunibreak](http://vimgadgets.sourceforge.net/libunibreak/), a C library implementing the [unicode line breaking algorithm](http://www.unicode.org/reports/tr14/) and word breaking from [unicode text segmentation](http://www.unicode.org/reports/tr29/).

## Line breaking ##

| `ub.linebreaks_utf8(s[,size[,lang]]) -> line_breaks` | get the line breaks |
|:-----------------------------------------------------|:--------------------|
| `ub.linebreaks_utf16(s[,size[,lang]]) -> line_breaks` | get the line breaks |
| `ub.linebreaks_utf32(s[,size[,lang]]) -> line_breaks` | get the line breaks |

The returned `line_breaks` is a 0-based array of flags, one for each byte of the input string:

| 0 | Break is mandatory.   |
|:--|:----------------------|
| 1 | Break is allowed.     |
| 2 | No break is possible. |
| 3 | A UTF-8/16 sequence is unfinished. |

## Word breaking ##

| `ub.wordbreaks_utf8(s[,size[,lang]]) -> word_breaks` | get the word breaks |
|:-----------------------------------------------------|:--------------------|
| `ub.wordbreaks_utf16(s[,size[,lang]]) -> word_breaks` | get the word breaks |
| `ub.wordbreaks_utf32(s[,size[,lang]]) -> word_breaks` | get the word breaks |

The returned `word_breaks` is a 0-based array of flags, one for each byte of the input string:

| 0 | Break is allowed.    |
|:--|:---------------------|
| 1 | No break is allowed. |
| 2 | A UTF-8/16 sequence is unfinished. |

## Unicode helpers ##

| `ub.chars_utf8(s) -> iter() -> i, codepoint` | codepoint iterator |
|:---------------------------------------------|:-------------------|
| `ub.chars_utf16(s) -> iter() -> i, codepoint` | codepoint iterator |
| `ub.chars_utf32(s) -> iter() -> i, codepoint` | codepoint iterator |
| `ub.len_utf8(s[,size]) -> len`               | number of codepoints in string |
| `ub.len_utf16(s[,size]) -> len`              | number of codepoints in string |
| `ub.len_utf32(s[,size]) -> len`              | number of codepoints in string |