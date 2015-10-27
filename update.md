## `glue.update(dt,t1,...) -> dt` ##

**Update a table with elements of other tables, overwriting any existing keys.**
  * nil arguments are skipped.

**Examples**

Create an options table by merging the options received as an argument (if any) over the default options.
```
function f(opts)
   opts = glue.update({}, default_opts, opts)
end
```

Shallow table copy:
```
t = glue.update({}, t)
```

Static multiple inheritance:
```
C = glue.update({}, A, B) --#TODO: find real-world example of multiple inheritance
```

**See also:** [extend](extend.md), [inherit](inherit.md).