v1.7 | LuaJIT 2, Lua 5.1, Lua 5.2

### `local glue = require'glue'`

-------------------------------------------- --------------------------------------------
__tables__

glue.index(t) -> dt                          [switch keys with values](##index)

glue.keys(t[, sorted | cmp]) -> dt           [make a list of all the keys](#keys)

glue.update(dt,t1,...) -> dt                 [merge tables - overwrites keys](#update)

glue.merge(dt,t1,...) -> dt                  [merge tables - no overwriting](#update)

glue.sortedpairs(t[, cmp])-> iterator<k,v>   [like pairs() but in key order](#sortedpairs)

__lists__

glue.extend(dt,t1,...) -> dt                 [extend a list](#extend)

glue.append(dt,v1,...) -> dt                 [append values to a list](#append)

glue.shift(t,i,n) -> t                       [shift list elements](#shift)

glue.reverse(t) -> t                         [reverse the order of elements in place](#reverse)

__strings__

glue.gsplit(s,sep[, plain]) ->               [split a string by a pattern](#gsplit)
  iterator<e[,captures...]>

glue.trim(s) -> s                            [remove padding](#trim)

glue.escape(s[-> s                           [escape escape magic pattern characters](#,mode]))

glue.tohex(s) -> s                           [string to hex](#tohex)

glue.fromhex(s) -> s                         [hex to string](#fromhex)

__iterators__

glue.collect([i,]iterator)-> t               [collect iterated values into a list](#collect)

glue.ipcall(iterator<v1,v2,...>) ->          [iterator pcall](#ipcall)
  iterator<ok,v1,v2,...>

__closures__

glue.pass(...) -> ...                        [does nothing, returns back all arguments](#pass)

__metatables__

glue.inherit(t,parent) -> t                  [set or clear inheritance](#inherit)

__i/o__

glue.fileexists(file) -> true | false        [check if a file exists and it's readable](#fileexists)

glue.readfile(file[format]) -> s             [read the contents of a file into a string](#readfile)

glue.writefile(file,s[,format])              [write a string to a file](#writefile)

__errors__

glue.assert(v,[message[,args...]]) -> args   [assert with error message formatting](#assert)

glue.unprotect(ok,result,...) ->             [unprotect a protected call](#unprotect)
	result,...  nil,result,...

glue.pcall(f,...) ->                         [pcall that appends the traceback to the error message](#pcall)
	true,... | false,error..'\n'..traceback

glue.fpcall(f,...) ->                        [coding with finally and except clauses](#fpcall)
	result | nil,error..'\n'..traceback

glue.fcall(f,...) -> result

__modules__

glue.autoload(t, submodule_t) -> t           [autoload table keys from submodules](#autoload)

-------------------------------------------- --------------------------------------------

-----------------------------------------------------------------------------------------

### Tips

String functions are also in the `glue.string` table. You can extend the Lua `string` namespace:

	glue.update(string, glue.string)

so you can use them as string methods:

	s = s:trim()


### Keywords
_for syntax highlighting_

glue.index, glue.keys, glue.update, glue.merge, glue.extend, glue.append, glue.shift, glue.gsplit, glue.trim,
glue.escape, glue.collect, glue.ipcall, glue.pass, glue.inherit, glue.fileexists,
glue.readfile, glue.writefile, glue.assert, glue.unprotect, glue.pcall, glue.fpcall, glue.fcall, glue.autoload
