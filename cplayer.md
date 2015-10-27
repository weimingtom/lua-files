v1.0 | [code](http://code.google.com/p/lua-files/source/browse/cplayer.lua) | [demo](http://code.google.com/p/lua-files/source/browse/cplayer_demo.lua) | LuaJIT 2 | Windows

## `local player = require'cplayer'` ##

cplayer is a sandbox environment for making tests and demos of the various 2D libraries around here.

## Features ##
  * single rendering event receiving a cairo context to draw the frame with
  * simplified access to keyboard and mouse state
  * a bunch of very easy to use immediate mode GUI widgets for making interactive demos
  * user-selectable color themes

## How it works ##

1. You define the function `player:on_render(cr)` in which you draw your frame using the `cr` argument which is a [cairo](cairo.md) context. The function gets called continuously on a `1 ms` timer. The current framerate is displayed on the title bar.

2. You call `player:play()` to display the player's main window and enter the Windows message loop. The function returns after the user has closed the window.

**Quick example:**
```
local player = require'cplayer'

function player:on_render(cr)
    --draw a red square
    cr:set_source_rgb(1, 0, 0)
    cr:rectangle(100, 100, 100, 100)
    cr:fill()
end

player:play()
```

### Mouse state ###

| `self.mousex`<br><code>self.mousey</code> <table><thead><th> mouse coordinates in device space<br>use <code>cr:device_to_user()</code> to translate them </th></thead><tbody>
<tr><td> <code>self.clicked</code>                 </td><td> true if the left mouse button was clicked (one-shot)                                        </td></tr>
<tr><td> <code>self.rightclick</code>              </td><td> true if the right mouse button was clicked (one-shot)                                       </td></tr>
<tr><td> <code>self.doubleclicked</code>           </td><td> true if the left mouse button was double-clicked (one-shot)                                 </td></tr>
<tr><td> <code>self.lbutton</code>                 </td><td> true if the left mouse button is down                                                       </td></tr>
<tr><td> <code>self.rbutton</code>                 </td><td> true if the right mouse button is down                                                      </td></tr>
<tr><td> <code>self.wheel_delta</code>             </td><td> mouse wheel movement as number of scroll pages (one-shot)                                   </td></tr>
<tr><td> <code>self:hotbox(x, y, w, h) -&gt; true | false</code> </td><td> check if the mouse hovers a rectangle                                                       </td></tr></tbody></table>

<h3>Keyboard state</h3>

<table><thead><th> <code>self.key</code>    </th><th> set if a key was pressed (one-shot); values are 'left', 'right', etc. (see source for complete list of key names; one-shot) </th></thead><tbody>
<tr><td> <code>self.char</code>   </td><td> set if a key combination representing a unicode character was pressed (one-shot); value is the character in utf-8           </td></tr>
<tr><td> <code>self.shift</code>  </td><td> true if shift key is pressed; only check it when <code>self.key</code> is set                                               </td></tr>
<tr><td> <code>self.ctrl</code>   </td><td> true if alt key is pressed; only check it when <code>self.key</code> is set                                                 </td></tr>
<tr><td> <code>self.alt</code>    </td><td> true if control key is pressed; only check it when <code>self.key</code> is set                                             </td></tr>
<tr><td> <code>self:keypressed(keyname) -&gt; true | false</code> </td><td> check if a key is pressed                                                                                                   </td></tr></tbody></table>

<b>Note:</b> one-shot means that the value is only available for the current frame, then it is cleared. With very slow framerates, some mouse or key events could be lost (for simplicity, there's no event queue).<br>
<br>
<h3>Wall clock</h3>

A wall clock in milliseconds is available as <code>self.clock</code>. Interpolating your animations over clock deltas will result in framerate-independent animations. Currently, it is used to blink the editbox caret.<br>
<br>
<h3>Mouse cursor</h3>

<ul><li><code>self.cursor = &lt;name&gt;</code></li></ul>

Changes the mouse pointer to one of the standard pointers: 'link', 'text', 'busy', etc. Look at the <code>cursors</code> table for the full list. The variable is not retained between frames, so it must be set every time to keep the mouse pointer changed otherwise the pointer will revert back to normal.<br>
<br>
<h3>Theme-aware API</h3>

<ul><li><code>self:setcolor(color)</code>
</li><li><code>self:fill(color)</code>
</li><li><code>self:stroke(color[, line_width])</code>
</li><li><code>self:fillstroke([fill_color], [stroke_color][, line_width])</code></li></ul>

The color argument can be either a color name from the current theme, a hex color in <code>#rrggbb</code> or <code>#rrggbbaa</code> format, or a table of form <code>{r, g, b, a}</code> where each channel is in the <code>0..1</code> range. Look at <code>player.themes.*</code> tables for available themes and color names. To change the current theme just set <code>self.theme</code> to a different theme table. Controls also have a <code>theme</code> parameter.<br>
<br>
<h3>Drawing helpers</h3>
<ul><li><code>self:dot(x, y, r, [fill_color], [stroke_color][, line_width])</code>
</li><li><code>self:rect(x, y, w, h, [fill_color], [stroke_color][, line_width])</code>
</li><li><code>self:circle(x, y, r, [fill_color], [stroke_color][, line_width])</code>
</li><li><code>self:line(x1, y1, x2, y2, [stroke_color][, line_width])</code>
</li><li><code>self:curve(x1, y1, x2, y2, x3, y3, x4, y4, [stroke_color][, line_width])</code>
</li><li><code>self:text(text, font_size, color, halign, valign, x, y, w, h)</code>
</li><li><code>self:text_path(text, font_size, halign, valign, x, y, w, h)</code>
<ul><li>halign = 'center', 'left', 'right'<br>
</li><li>valign = 'middle', 'top', 'bottom'</li></ul></li></ul>

<h3>GUI widgets</h3>

The GUI Widgets are implemented in <code>cplayer/*.lua</code>. The modules are loaded automatically as needed. For the full list of available widgets and the module where each is implemented in, look for <code>autoload</code> in the code. The player demo should also include a usage example for each widget.<br>
<br>
<b>Quick example:</b>
<pre><code>if self:button{id = 'ok', x = 100, y = 100, w = 100, h = 24, text = 'Okay'} then<br>
  print'button pressed'<br>
end<br>
</code></pre>

<h3>Additional windows</h3>

You can create and show additional windows from the main window with <code>self:window()</code>. Windows are not like other widget methods: each invocation of <code>self:window()</code> creates a new window on screen that doesn't close when the frame ends, but persists until the user closes it (I'll probably change that in the future and have a unique window per id and activate it when invoked and set <code>self.active</code> or something).<br>
<br>
<pre><code>local window = self:window{<br>
   w = 500, h = 300, title = 'Ima window',<br>
   on_render = function(cr)<br>
      ...<br>
   end}<br>
</code></pre>