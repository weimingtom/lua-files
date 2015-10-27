v1.7 | [code](http://code.google.com/p/lua-files/source/browse/glue.lua) | [test](http://code.google.com/p/lua-files/source/browse/glue_test.lua) | [design](gluedesign.md) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local glue = require'`<a href='http://code.google.com/p/lua-files/wiki/glue'><img src='http://wiki.lua-files.googlecode.com/hg/glue.png' /></a>`'` ##

| **tables** ||
|:-----------|:|
|`glue.index(t) -> dt`|[switch keys with values](index.md)|
|`glue.keys(t[, sorted | cmp]) -> dt`|[make a list of all the keys](keys.md)|
|`glue.update(dt,t1,...) -> dt`|[merge tables - overwrites keys](update.md)|
|`glue.merge(dt,t1,...) -> dt`|[merge tables - no overwriting](update.md)|
|`glue.sortedpairs(t[,cmp]) -> iterator<k,v>`|[like pairs() but in key order](sortedpairs.md)|
| **lists**  ||
|`glue.extend(dt,t1,...) -> dt`|[extend a list](extend.md)|
|`glue.append(dt,v1,...) -> dt`|[append values to a list](append.md)|
|`glue.shift(t,i,n) -> t`|[shift list elements](shift.md)|
|`glue.reverse(t) -> t`|[reverse the order of elements in place](reverse.md)|
| **strings** ||
|`glue.gsplit(s,sep[,plain]) -> iterator<e[,captures...]>`|[split a string by a pattern](gsplit.md)|
|`glue.trim(s) -> s`|[remove padding](trim.md)|
|`glue.escape(s[,mode]) -> s`|[escape magic pattern characters](escape.md)|
|`glue.tohex(s) -> s`|[string to hex](tohex.md)|
|`glue.fromhex(s) -> s`|[hex to string](fromhex.md)|
| **iterators** ||
|`glue.collect([i,]iterator) -> t`|[collect iterated values into a list](collect.md)|
|`glue.ipcall(iterator<v1,v2,...>) -> iterator<ok,v1,v2,...>`|[iterator pcall](ipcall.md)|
| **closures** ||
|`glue.pass(...) -> ...`|[does nothing, returns back all arguments](pass.md)|
| **metatables** ||
|`glue.inherit(t,parent) -> t`|[set or clear inheritance](inherit.md)|
| **i/o**    ||
|`glue.fileexists(file) -> true | false`|[check if a file exists and it's readable](fileexists.md)|
|`glue.readfile(file[, format]) -> s`|[read the contents of a file into a string](readfile.md)|
|`glue.writefile(file,s[,format])`|[write a string to a file](writefile.md)|
| **errors** ||
|`glue.assert(v[,message[,args...]])`|[assert with error message formatting](assert.md)|
|`glue.unprotect(ok,result,...) -> result,... | nil,result,...`|[unprotect a protected call](unprotect.md)|
|`glue.pcall(f,...) -> true,... | false,error..'\n'..traceback`|[pcall that appends the traceback to the error message](pcall.md)|
|`glue.fpcall(f,...) -> result | nil,error..'\n'..traceback`<br><code>glue.fcall(f,...) -&gt; result</code><table><thead><th><a href='fpcall.md'>coding with finally and except clauses</a></th></thead><tbody>
<tr><td> <b>modules</b> </td><td></td></tr>
<tr><td><code>glue.autoload(t, submodule_t) -&gt; t</code> </td><td><a href='autoload.md'>autoload table keys from submodules</a></td></tr></tbody></table>

<h3>Tips</h3>

String functions are also in the <code>glue.string</code> table. You can extend the Lua <code>string</code> namespace<br>
<br>
<blockquote><code>glue.update(string, glue.string)</code></blockquote>

so you can use them as string methods:<br>
<br>
<blockquote><code>s = s:trim()</code></blockquote>


<h3>Keywords</h3>
<i>for syntax highlighting...</i>

glue.index, glue.keys, glue.update, glue.merge, glue.extend, glue.append, glue.shift, glue.gsplit, glue.trim, glue.escape, glue.collect, glue.ipcall, glue.pass, glue.inherit, glue.fileexists,<br>
glue.readfile, glue.writefile, glue.assert, glue.unprotect, glue.pcall, glue.fpcall, glue.fcall, glue.autoload