TCP/IP socket dispatcher to coroutines


v1.1 | [code](http://code.google.com/p/lua-files/source/browse/socketloop.lua) | [test](http://code.google.com/p/lua-files/source/browse/socketloop_test.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local socketloop = require'socketloop'`

A socket loop enables the multi-process blocking I/O programming model for luasocket TCP/IP sockets, where each process is a coroutine. The concept is similar to [Copas](http://keplerproject.github.com/copas/), the API and the implementation are different.

## `socketloop() -> loop`

Make a new socket loop object. Since we're using select(), it only makes sense to have one loop per CPU thread / Lua state.

## `loop.connect(address,port[,local_address][,local_port]) -> asocket`

Make a TCP/IP connection and return an asynchronous socket object. The (synchronous) luasocket object is accessible as skt.socket.

The socket object has the TCP socket methods `accept()`, `receive()`, `send()` and `close()` (see [luasocket docs](http://w3.impa.br/~diego/software/luasocket/tcp.html) for those), except they are asynchronous. This means that if each socket is used from its own coroutine, different sockets won't block each other waiting for reads and writes, as long as the loop is dispatching them.

## `loop.dispatch([timeout]) -> true|false`

Dispatch currently pending reads and writes to their respective coroutines.

## `loop.start([timeout])`

Dispatch reads and writes continuously in a loop.

## `loop.stop()`

Stop the dispatch loop if started.

## `loop.newthread(handler,...)`

Create and resume a coroutine who's function is handler. The coroutine is resumed with the given arguments.

## `loop.newserver(host, port, handler)`

Create a TCP/IP socket and start accepting connections on it, and call `handler(client_skt)` on a separate coroutine for each accepted connection.

## `loop.wrap(socket) -> async_socket`

Wrap a TCP socket into an asynchronous socket.
