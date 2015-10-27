lanes 3.6.2 | Lua 5.1 | Lua 5.2 | LuaJIT 2

  * lanes is now hosted on [github](https://github.com/LuaLanes/lanes) - ignore the official website.
  * the default value of `protect_allocator` was changed to `true` in `lanes.lua` - LuaJIT2 crashes without that.
  * you can read the up-to-date documentation [here](https://lua-files.googlecode.com/hg/csrc/lanes/docs/index.html) until lanes will have it online.
  * to use ffi inside lanes you have to require the ffi module inside the lane, since the ffi module cannot be transferred as an upvalue to your lane (you will get an error about "destination transfer database").
    * this also means that **other modules** that depend on ffi cannot be upvalues and must be required explicitly inside the lane or luajit will crash.