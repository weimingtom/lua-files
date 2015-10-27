## `glue.collect([i, ]iterator) -> t` ##

**Iterate an iterator and collect its i'th return value of every step into a list.**
  * i defaults to 1

**Examples**
```
s = 'a,b,c'
t = glue.collect(s:gmatch'(.-),')
for i=1,#t do print(t[i]) end

> a
> b
> c
```

Implementation of `keys()` and `values()` in terms of `collect()`
```
keys = function(t) return glue.collect(pairs(t)) end
values = function(t) return glue.collect(2,pairs(t)) end
```

**Alt. names**
  * `ipack` - like pack but for iterators; collect is better at suggesting a process done in steps.