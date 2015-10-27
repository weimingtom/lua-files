## `glue.unprotect(ok,result,...) -> result,... | nil,result,...` ##

In Lua, API functions conventionally signal errors by returning nil and an error message instead of raising exceptions. In the implementation however, using assert() and error() is preferred to coding explicit conditional flows to cover exceptional cases. Use this function to convert error-raising functions to nice nil,error-returning functions:

```
function my_API_function()
  return glue.unprotect(pcall(function()
    ...
    assert(...)
    ...
    error(...)
    ...
    return result_value
  end))
end
```