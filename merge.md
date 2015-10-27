## `glue.merge(dt,t1,...) -> dt` ##

**Update a table with elements of other tables skipping on any existing keys.**
  * nil arguments are skipped.

**Examples**

Normalize a data object with default values:
```
glue.merge(t, defaults)
```

**See also:** [update](update.md).