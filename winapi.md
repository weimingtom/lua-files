**0.1a** | [doc](WinapiDesign.md) | [code](http://code.google.com/p/lua-files/source/browse/#hg%2Fwinapi) | LuaJIT 2

### Scope ###
Windows, common controls, auxiliary objects, dialogs, message loop.

### Design ###
Procedural API with object API on top.

### Status ###
In development, not active. Currently, windows and basic controls (buttons, edits, combos, tab controls etc.), as well as dialogs (color chooser, file open) and resource objects (image lists, fonts, cursors, etc.) are implemented, with a fair degree of feature coverage and some cherry on top.

I also started working on a [designer](windesigner.md) app that would serve as feature showcase, live testing environment, and ultimately as a GUI designer.

### Installation ###

Downloading `lua-files` will get you the winapi modules, the designer, and the luajit binary so you can start coding right away.<br>
Just add <code>lua-files</code> to your <code>LUA_PATH</code> or <code>package.path</code> and run a few demos to make sure everything is properly found.<br>
<br>
The winapi modules are all in the <code>winapi</code> folder, you don't need any other modules outside of it except <code>glue.lua</code>.<br>
<br>
<h3>Example</h3>
<pre><code>winapi = require'winapi'<br>
require'winapi.messageloop'<br>
<br>
local main = winapi.Window{<br>
   title = 'Demo',<br>
   w = 600, h = 400,<br>
   autoquit = true,<br>
}<br>
<br>
os.exit(winapi.MessageLoop())<br>
</code></pre>

<h3>Documentation, or lack thereof</h3>

There's no method-by-method documentation, but there's <a href='WinapiDesign.md'>technical documentation</a>, <a href='WinapiBinding.md'>developer documentation</a>, and a <a href='WinapiHistory.md'>narrative</a> which should give you more context.