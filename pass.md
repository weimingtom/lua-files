## `glue.pass(...) -> ...` ##

**The identity function. Does nothing, returns back all arguments.**

**Examples**

Default value for optional callback arguments:
```
function urlopen(url, callback, errback)
   callback = callback or glue.pass
   errback = errback or glue.pass
   ...
   callback()
end
```