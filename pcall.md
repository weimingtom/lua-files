**Note: Lua 5.2 and LuaJIT 2 only.**

## `glue.pcall(f,...) -> true,... | false,error..'\n'..traceback` ##

With Lua's pcall() you lose the stack trace, and with usual uses of pcall() you don't want that, thus this variant that appends the traceback to the error message.