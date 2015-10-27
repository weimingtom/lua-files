## `glue.autoload(t, submodules) -> t` ##

**Assign a metatable to `t` such that when a missing key is accessed, the module said to contain the key is require'd automatically.**

The `submodules` argument is a table of form `{key = module_name | load_function}` specifying the corresponding Lua module (or load function) that make each key available to `t`.

**Example:**

main module (foo.lua):
```

local function bar() --function is implemented in the main module
  ...
end

--at the end of the module file, create/return the module table

return glue.autoload({
   ...
   bar = bar,
}, {
   baz = 'foo_baz', --autoloaded function, implemented in a submodule
})
```

submodule (foo\_baz.lua):
```
local foo = require'foo'

function foo.baz(...)
  ...
end
```

user module:
```
local foo = require'foo'

foo.baz(...) -- foo_baz.lua was require'd automatically
```

**Motivation**

Module autoloading allows you to split the implementation of a module in many submodules containing optional, self-contained functionality, without having to make this visible in the user API. This effectively separates how you split your APIs from how you split the implementation, allowing you to change the way the implementation is split at a later time while keeping the API intact.