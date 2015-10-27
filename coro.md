v1.0 | [code](http://code.google.com/p/lua-files/source/browse/coro.lua) | [test](http://code.google.com/p/lua-files/source/browse/coro_test.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local coro = require'coro'` ##

Symmetric coroutines are coroutines that allow you to transfer control to a specific coroutine, unlike Lua's standard coroutines which only allow you to suspend execution to the calling coroutine.

This is the implementation from the paper [Coroutines in Lua](http://www.inf.puc-rio.br/~roberto/docs/corosblp.pdf). Changes from the paper:
  * threads created with `coro.create()` finish into the creator thread not main thread, unless otherwise specified.
  * added `coro.wrap()` similar to `coroutine.wrap()`.

## `coro.create(f[, return_thread]) -> coro_thread` ##

Create a symmetric coroutine, optionally specifying the thread which the coroutine should transfer control to when it finishes execution (defaults to `coro.current`.

## `coro.transfer(coro_thread[, send_val]) -> recv_val` ##

Transfer control to a symmetric coroutine, suspending execution. The target coroutine either hasn't started yet, or it is itself suspended in a call to `coro.transfer()`, in which case it resumes and receives `send_val` as the return value of the call. Likewise, the coroutine which transfers execution will stay suspended until `coro.transfer()` is called again with it as target.

## `coro.current -> coro_thread` ##

Currently running symmetric coroutine. Defaults to `coro.main`.

## `coro.main -> coro_thread` ##

The coroutine representing the main thread (the thread that calls `coro.transfer` for the first time).

## `coro.wrap(f) -> f` ##

Similar to `coroutine.wrap` for symmetric coroutines. Useful for creating iterators in an environment of symmetric coroutines in which simply calling `coroutine.yield` is not an option:

```
local parent = coro.current
local iter = coro.wrap(function()
   local function yield(val)
      coro.transfer(parent, val)
   end
   ...
   yield(val)
end)
```