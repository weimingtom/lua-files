## `glue.escape(s[,mode]) -> pat` ##

**Escape magic characters of the string `s` so that it can be used as a pattern to string matching functions**
  * the optional argument `mode` can have the value `"*i"` (for case insensitive), in which case each alphabetical character in `s` will also be escaped as `[aA]` so that it matches both its lowercase and uppercase variants.
  * escapes embedded zeroes as the `%z` pattern.

**Uses**
  * workaround for lack of pattern syntax for "this part of a match is an arbitrary string"
  * workaround for lack of a case-insensitive flag in pattern matching functions

**Examples**

```
TODO
```

**Design notes**

Test the performance of the case-insensitive hack to see if it's feasible.