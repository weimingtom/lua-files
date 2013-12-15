*0.1a* | [WinapiDesign doc] | [code](http://code.google.com/p/lua-files/source/browse/#hg%2Fwinapi) | LuaJIT 2

### Scope
Windows, common controls, auxiliary objects, dialogs, message loop.

### Design
Procedural API with object API on top.

### Status
In development, not active. Currently, windows and basic controls (buttons, edits, combos, tab controls etc.), as well as dialogs (color chooser, file open) and resource objects (image lists, fonts, cursors, etc.) are implemented, with a fair degree of feature coverage and some cherry on top.

I also started working on a [windesigner designer] app that would serve as feature showcase, live testing environment, and ultimately as a GUI designer.

### Installation

Downloading `lua-files` will get you the winapi modules, the designer, and the luajit binary so you can start coding right away.<br>
Just add `lua-files` to your `LUA_PATH` or `package.path` and run a few demos to make sure everything is properly found.

The winapi modules are all in the `winapi` folder, you don't need any other modules outside of it except `glue.lua`.

### Example
~~~{.lua}
winapi = require'winapi'
require'winapi.messageloop'

local main = winapi.Window{
   title = 'Demo',
   w = 600, h = 400,
   autoquit = true,
}

os.exit(winapi.MessageLoop())
~~~

### Documentation, or lack thereof

There's no method-by-method documentation, but there's [WinapiDesign technical documentation], [WinapiBinding developer documentation], and a [WinapiHistory narrative] which should give you more context.
