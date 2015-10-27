v1.0 | [code](http://code.google.com/p/lua-files/source/browse/dlist.lua) | [test](http://code.google.com/p/lua-files/source/browse/dlist_test.lua) | Lua 5.1, Lua 5.2, LuaJIT 2

## `local dlist = require'dlist'` ##

Doubly linked lists in Lua.

Doubly linked lists make insert, remove and move operations fast, and access by index slow.

In this particular implementation items must be Lua tables for which fields `_prev` and `_next` must be reserved for linking.

## API ##

| `dlist() -> list`<br> <code>dlist:new() -&gt; list</code> <table><thead><th> create a new list </th></thead><tbody>
<tr><td> <code>list:clear()</code>                                 </td><td> clear the list    </td></tr>
<tr><td> <code>list:push(t)</code>                                 </td><td> add an item at end of the list </td></tr>
<tr><td> <code>list:unshift(t)</code>                              </td><td> add an item at the beginning of the list </td></tr>
<tr><td> <code>list:insert(t[, after_t])</code>                    </td><td> add an item after another item (or at the end) </td></tr>
<tr><td> <code>list:pop() -&gt; t</code>                           </td><td> remove and return the last item, if any </td></tr>
<tr><td> <code>list:shift() -&gt; t</code>                         </td><td> remove and return the first item, if any </td></tr>
<tr><td> <code>list:remove(t) -&gt; t</code>                       </td><td> remove and return a specific item </td></tr>
<tr><td> <code>list:next([current]) -&gt; t</code>                 </td><td> next item after some item (or first item) </td></tr>
<tr><td> <code>list:prev([current]) -&gt; t</code>                 </td><td> previous item after some item (or last item) </td></tr>
<tr><td> <code>list:items() -&gt; iterator&lt;item&gt;</code>      </td><td> iterate items     </td></tr>
<tr><td> <code>list:reverse_items() -&gt; iterator&lt;item&gt;</code> </td><td> iterate items in reverse </td></tr>
<tr><td> <code>list:copy() -&gt; new_list</code>                   </td><td> copy the list     </td></tr>