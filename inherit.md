## `glue.inherit(t, parent) -> t` ##
## `glue.inherit(t, nil) -> t` ##

**Set a table to inherit attributes from a parent table, or clear inheritance.**

If the table has no metatable (and inheritance has to be set, not cleared) make it one.

**Examples:**

Overriding defaults
```
TODO
```

Logging mixin:
```
AbstractLogger = glue.inherit({}, function(t,k) error('abstract '..k) end)
NullLogger = glue.inherit({log = function() end}, AbstractLogger)
PrintLogger = glue.inherit({log = function(self,...) print(...) end}, AbstractLogger)

HttpRequest = glue.inherit({
   perform = function(self, url)
      self:log('Requesting', url, '...')
      ...
   end
}, NullLogger)

LoggedRequest = glue.inherit({log = PrintLogger.log}, HttpRequest)

LoggedRequest:perform'http://lua.org/'

> Requesting	http://lua.org/	...
```

Defining a module in Lua 5.2
```
_ENV = glue.inherit({},_G)
...
```

**Hints:**
  * to get the effect of static (single or multiple) inheritance, use [update](update.md) instead.
  * when setting inheritance, you can pass in a function.

**Design notes**

`t = setmetatable({},{__index=parent})` is not much longer and it's idiomatic, but doesn't shout inheritance at you (you have to process the indirection, like with functional idioms) and you can't use it to change the parent (a minor quibble nevertheless).

Overriding of methods needs an easy way to access the "parent" or to invoke a method on the parent. A top-level class could provide this simply by defining `function Object:parent() return getmetatable(self).__index end`.

See also: http://lua-users.org/wiki/SimpleLuaClasses.