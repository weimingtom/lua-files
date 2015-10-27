v2.0 | [code & demo](http://code.google.com/p/lua-files/source/browse/hunspell.lua) | hunspell 1.3.2 | LuaJIT 2

## `local hunspell = require'hunspell'` ##

ffi binding of the popular spell checking library [hunspell](http://hunspell.sourceforge.net/).

## API ##

| **spell-checking and suggestions** | |
|:-----------------------------------|:|
| `hunspell.new(aff_filepath, dic_filepath[, key]) -> h` | create a hunspell instance |
| `h:free()`                         | free the hunspell instance |
| `h:spell(word) -> true[, 'warn'] | false` | spell-check a word (the 'warn' flag indicates a rare word, which often is a spelling mistake) |
| `h:suggest(word) -> words_t`       | suggest correct words for a possibly bad word |
| **advanced use**                   | |
| `h:analyze(word) -> words_t`       | morphological analysis of a word |
| `h:stem(word) -> words_t`          | stems of a word |
| `h:generate(word, example) -> words_t` | generate word(s) by example |
| `h:generate(word, desc_t) -> words_t` | generate word(s) by description (dictionary dependent) |
| `h:add_word(word)`                 | add a word to the dictionary (in memory) |
| `h:remove_word(word)`              | remove a word from the dictionary (in memory) |
| `h:get_dic_encoding() -> string`   | return the current encoding (dictionary dependent) |
| **extras** (available with the included `hunspell.dll`) | |
| `h:add_dic(dic_filepath[, key])`   | add a dictionary file to the hunspell instance |