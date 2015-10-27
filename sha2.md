v1.0 | [code](http://code.google.com/p/lua-files/source/browse/sha2.lua) | [test](http://code.google.com/p/lua-files/source/browse/sha2_test.lua) | [benchmark](https://code.google.com/p/lua-files/source/browse/hash_benchmark.lua) | sha2-1.0 | LuaJIT 2

## `local sha2 = require'sha2'` ##

A ffi binding of Aaron Gifford's [SHA-2 implementation](http://www.aarongifford.com/computers/sha.html).

## `sha2.sha256(s[, size]) -> s` ##
## `sha2.sha256(cdata, size) -> s` ##

## `sha2.sha384(s[, size]) -> s` ##
## `sha2.sha384(cdata, size) -> s` ##

## `sha2.sha512(s[, size]) -> s` ##
## `sha2.sha512(cdata, size) -> s` ##

Compute the SHA-2 hash of a string or a cdata buffer. Returns the  binary representation of the hash. To get the hex representation, use [glue.tohex](tohex.md).

## `sha2.sha256_digest() -> digest` ##
## `sha2.sha384_digest() -> digest` ##
## `sha2.sha512_digest() -> digest` ##
> ## `digest(s[, size])` ##
> ## `digest(cdata, size)` ##
> ## `digest() -> s` ##

Get a SHA-2 digest function that can consume multiple data chunks until called with no arguments when it returns the final SHA hash.

## Building ##

C sources and build scripts included. Binary also included.


---

See also: [md5](md5.md).