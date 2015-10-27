v1.0 | [code](http://code.google.com/p/lua-files/source/browse/expat.lua) | [test](http://code.google.com/p/lua-files/source/browse/expat_test.lua) | expat 2.1.0 | LuaJIT 2

## `local expat = require'expat'` ##

A ffi binding for the [Expat XML parser](http://expat.sourceforge.net/).

## `expat.parse(source, callbacks)` ##

Parse a XML from a string, cdata, file, or reader function, calling a callback for each piece of the XML parsed.

```
source = {path = S} | {string = S} | {cdata = CDATA, size = N} | {read = read_function}

callbacks = {
  element         = function(name, model) end,
  attr_list       = function(elem, name, type, dflt, is_required) end,
  xml             = function(version, encoding, standalone) end,
  entity          = function(name, is_param_entity, val, base, sysid, pubid, notation) end,
  start_tag       = function(name, attrs) end,
  end_tag         = function(name) end,
  cdata           = function(s) end,
  pi              = function(target, data) end,
  comment         = function(s) end,
  start_cdata     = function() end,
  end_cdata       = function() end,
  default         = function(s) end,
  default_expand  = function(s) end,
  start_doctype   = function(name, sysid, pubid, has_internal_subset) end,
  end_doctype     = function() end,
  unparsed        = function(name, base, sysid, pubid, notation) end,
  notation        = function(name, base, sysid, pubid) end,
  start_namespace = function(prefix, uri) end,
  end_namespace   = function(prefix) end,
  not_standalone  = function() end,
  ref             = function(parser, context, base, sysid, pubid) end,
  skipped         = function(name, is_parameter_entity) end,
  unknown         = function(name, info) end,
}
```

## `expat.treeparse(source, [known_tags]) -> root_node` ##

Parse a XML to a tree of nodes. known\_tags filters the output so that only the tags that known\_tags indexes are returned.

Nodes look like this:
```
node = {tag=, attrs={<k>=v}, children={node1,...}, tags={<tag> = node}, cdata=}
```

## `expat.children(node, tag) -> iter() -> node` ##

Iterate a node's children that have a specific tag.