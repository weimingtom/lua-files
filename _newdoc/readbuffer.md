buffered reading

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/readbuffer.lua) | [test](http://code.google.com/p/lua-files/source/browse/readbuffer_test.lua) | LuaJIT 2, Lua 5.1

## `local readbuffer = require'readbuffer'`

A readbuffer is useful for reading line-based protocols such as http when the data comes in chunks of unknown size unaligned to line boundaries.

## `readbuffer(read[ ,bufsize]) -> reader`

Create a reader object based on a user-provided read function.

The read function is called with a size argument and should return a string no larger than the requested size or false/nil/nothing on eof.

Default bufsize is 64k.

## `reader:flush() -> s`

Flush the buffer returning its contents.

## `reader:readmatch(pattern) -> captures`

Read until a match is found and return the captures. Vreak on eof.

## `reader:readline() -> s`

Read until a full line is captured. Break on eof.

## `reader:readsize(size) -> s`

Read a certain number of bytes. Break on eof.

## `reader:readchunks([size[ ,flushsize]]) -> f; f() -> s | nil`

Return a reader that reads chunks until a certain number of bytes is read. `flushsize` controls buffering and it defaults to `bufsize`.

## `reader:readall([flushsize]) -> f; f() -> s | nil`

Return a reader that reads chunks until eof.
