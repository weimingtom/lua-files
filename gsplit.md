## `glue.gsplit(s,sep[,plain]) -> iterator<e[,captures...]>` ##

**Split a string by a separator pattern (or plain string) and iterate over the elements.**

  * if sep is "" return the entire string in one iteration
  * if s is "" return s in one iteration
  * empty strings between separators are always returned, eg. `glue.gsplit(',', ',')` produces 2 empty strings
  * captures are allowed in sep and they are returned after the element, except for the last element for which they don't match (by definition).

**Examples**
```
for s in glue.gsplit('Spam eggs spam spam and ham', '%s*spam%s*') do
   print('"'..s..'"')
end

> "Spam eggs"
> ""
> "and ham"
```

TODO: find an enlightening example with captures in the separator

**Design notes**
  * name choice: associate with `gmatch` and `gsub` (although I don't like these names, would have preferred `matchall` and `replace` or `subst`... too late now as they're already imprinted into our collective memory)
  * problems: allowing captures in `sep` doesn't have very readable semantics