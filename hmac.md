v1.0 | [code](http://code.google.com/p/lua-files/source/browse/hmac.lua) | [hmac-md5](http://code.google.com/p/lua-files/source/browse/hmac_md5.lua) | [hmac-md5 test](http://code.google.com/p/lua-files/source/browse/hmac_md5_test.lua) | [hmac-sha2](http://code.google.com/p/lua-files/source/browse/hmac_sha2.lua) | [hmac-sha2 test](http://code.google.com/p/lua-files/source/browse/hmac_sha2_test.lua) | LuaJIT 2

## `local hmac = require'hmac'` ##

[HMAC](http://en.wikipedia.org/wiki/HMAC) algorithm per [RFC 2104](http://tools.ietf.org/html/rfc2104).

## `hmac.compute(key, message, hash_function, blocksize[, opad][, ipad]) -> hash, opad, ipad` ##

Any hash function that takes a string as single argument works, like `md5.sum`. `blocksize` is that of the underlying hash function, i.e. 64 for MD5 and SHA-256, 128 for SHA-384 and SHA-512.

## `hmac.new(hash_function, block_size) -> hmac_function` ##
> ## `hmac_function(message, key) -> hash` ##

Returns a HMAC function that can be used with a specific hash function.

## `hmac.md5(message, key) -> HMAC-MD5 hash` ##

Computes HMAC-MD5 (requires [md5](md5.md)).

## `hmac.sha256(message, key) -> HMAC-SHA256 hash` ##
## `hmac.sha384(message, key) -> HMAC-SHA384 hash` ##
## `hmac.sha512(message, key) -> HMAC-SHA512 hash` ##

Compute HMAC-SHA2 (requires [sha2](sha2.md)).