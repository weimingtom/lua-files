## `glue.assert(v[, message[, format_args...]])` ##

Like `assert` but supports formatting of the error message using string.format.

This is better than `assert(string.format(message, format_args...))` because it avoids creating the message string when the assertion is true.

**Example**
```
glue.assert(depth <= maxdepth, 'maximum depth %d exceeded', maxdepth)
```