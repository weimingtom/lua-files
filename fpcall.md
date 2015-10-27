## `glue.fpcall(f,...) -> result | nil,error..'\n'..traceback` ##
## `glue.fcall(f,...) -> result` ##

These constructs bring the ubiquitous try/finally/except clauses to Lua. The first variant returns nil,error when errors occur while the second re-raises the error.

Pseudo-example:
```
local result = glue.fpcall(function(finally, except, ...)
  local temporary_resource = acquire_resource()
  finally(function() temporary_resource:free() end)
  ...
  local final_resource = acquire_resource()
  except(function() final_resource:free() end)
  ... code that might break ...
  return final_resource
end, ...)
```