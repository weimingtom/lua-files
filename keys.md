## `glue.keys(t[, sorted | cmp]) -> dt` ##

**Make a list of all the keys of `t`, optionally sorted.**

**Examples**

An API expects a list of things but you have them as keys in a table because you are indexing something on them.

For instance:
  * you have a table of the form `{socket = thread}` but `socket.select` wants a list of sockets.

**See also:** [sortedpairs](sortedpairs.md).