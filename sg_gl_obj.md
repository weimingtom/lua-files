v1.0 | [code](http://code.google.com/p/lua-files/source/browse/sg_gl_obj.lua)

## `require'sg_gl_obj'` ##

Extends [sg\_gl](sg_gl.md) to render obj type objects. Uses [obj\_loader](obj_loader.md) to parse obj files into [mesh objects](sg_gl_mesh.md).
## Wavefront obj objects ##

```
<obj_object> = {
  type = 'obj',
  file = {
    path = S, 
    use_cache = true | false (false),
  },
}
```


---

See also: [sg\_gl\_mesh](sg_gl_mesh.md), [obj\_loader](obj_loader.md).