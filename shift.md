## `glue.shift(t,i,n) -> t` ##

**Shift all the list elements starting at index `i`, `n` positions to the left or further to the right.**

For a positive `n`, shift the elements further to the right, effectively creating room for `n` new elements at index `i`. When `n` is 1, the effect is the same as for `table.insert(t, i, t[i])`. The old values at index `i` to `i+n-1` are preserved, so `#t` still works after the shifting.

For a negative `n`, shift the elements to the left, effectively removing the `n` elements at index `i`. When `n` is -1, the effect is the same as for `table.remove(t, i)`.

**Uses**
  * removing a portion of a list or making room for more elements inside the list.

**Examples**

```
TODO
```

**See also:** [extend](extend.md).