v1.0 | [code](http://code.google.com/p/lua-files/source/browse/md5.lua) | [test](http://code.google.com/p/lua-files/source/browse/md5_test.lua) | [benchmark](https://code.google.com/p/lua-files/source/browse/hash_benchmark.lua) | (md5.c 2001, unversioned) | LuaJIT 2

## `local md5 = require'md5'` ##

A ffi binding of the popular [MD5 implementation](http://openwall.info/wiki/people/solar/software/public-domain-source-code/md5) by Alexander Peslyak.

## `md5.sum(s[, size]) -> s` ##
## `md5.sum(cdata, size) -> s` ##

Compute the MD5 sum of a string or a cdata buffer. Returns the binary representation of the hash. To get the hex representation, use [glue.tohex](tohex.md).

## `md5.digest() -> digest` ##
> ## `digest(s[, size])` ##
> ## `digest(cdata, size)` ##
> ## `digest() -> s` ##

Get a MD5 digest function that can consume multiple data chunks until called with no arguments when it returns the final binary MD5 hash.

## Building ##

C sources and build scripts included. Binary also included.


---

See also: [sha2](sha2.md).