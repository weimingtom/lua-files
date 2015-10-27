v1.0 | [code](http://code.google.com/p/lua-files/source/browse/color.lua) | [demo](http://code.google.com/p/lua-files/source/browse/color_demo.lua) | Lua 5.1, Lua 5.2, LuaJIT 2

## `local color = require'color'` ##

Color computation in HSL space. Shamelessly ripped off and modified from [Sputnik's colors lib](http://sputnik.freewisdom.org/lib/colors/), by Yuri Takhteyev.

  * `r, g, b, s, L` are in 0..1 range.
  * `h` is in 0..360 range.

### API ###

| `color.hsl_to_rgb(h, s, L) -> r, g, b` | HSL -> RGB; h is modulo 360; s, L are clamped to range |
|:---------------------------------------|:-------------------------------------------------------|
| `color.rgb_to_hsl(r, g, b) -> h, s, L` | RGB -> HSL; r, g, b are clamped to range               |
| `color.rgb_to_string(r, g, b) -> s`    | generate '#rrggbb' hex color                           |
| `color.string_to_rgb(s) -> r, g, b | nil` | parse a '#rrggbb' hex color                            |
| `color.rgba_to_string(r, g, b, a) -> s` | generate a '#rrggbbaa' hex color                       |
| `color.string_to_rgba(s) -> r, g, b, a | nil` | parse a '#rrggbbaa' hex color (the 'aa' part is optional) |

### OOP API ###

| `color('#rrggbb') -> col` | create a new HSL color object from a RGB string |
|:--------------------------|:------------------------------------------------|
| `color(h, s, L) -> col`   | create a new HSL color object from HSL values   |
| `col.h, col.s, col.L`     | color fields (for reading and writing)          |
| `col:hsl() -> h, s, L` <br> <code>col() -&gt; h, s, L</code> <table><thead><th> color fields unpacked                           </th></thead><tbody>
<tr><td> <code>col:rgb() -&gt; r, g, b</code> </td><td> convert to RGB                                  </td></tr>
<tr><td> <code>col:tostring() -&gt; '#rrggbb'</code> </td><td> convert to RGB string                           </td></tr>
<tr><td> <code>col:hue_offset(hue_delta) -&gt; color</code> </td><td> create a new color with a different hue         </td></tr>
<tr><td> <code>col:complementary() -&gt; color</code> </td><td> create a complementary color                    </td></tr>
<tr><td> <code>col:neighbors(angle) -&gt; color1, color2</code> </td><td> create two neighboring colors (by hue), offset by "angle" </td></tr>
<tr><td> <code>col:triadic() -&gt; color1, color2</code> </td><td> create two new colors to make a triadic color scheme </td></tr>
<tr><td> <code>col:split_complementary(angle) -&gt; color1, color2</code> </td><td> create two new colors, offset by angle from a color's complementary </td></tr>
<tr><td> <code>col:desaturate_to(saturation) -&gt; color</code> </td><td> create a new color with saturation set to a new value </td></tr>
<tr><td> <code>col:desaturate_by(r) -&gt; color</code> </td><td> create a new color with saturation set to a old saturation times r </td></tr>
<tr><td> <code>col:lighten_to(lightness) -&gt; color</code> </td><td> create a new color with lightness set to a new value </td></tr>
<tr><td> <code>col:lighten_by(r) -&gt; color</code> </td><td> create a new color with lightness set to its lightness times r </td></tr>
<tr><td> <code>col:variations(f, n) -&gt; {color1, ...}</code> </td><td> create n variations of a color using supplied function and return them as a table </td></tr>
<tr><td> <code>col:tints(n) -&gt; {color1, ...}</code> </td><td> create n tints of a color and return them as a table </td></tr>
<tr><td> <code>col:shades(n) -&gt; {color1, ...}</code> </td><td> create n shades of a color and return them as a table </td></tr>
<tr><td> <code>col:tint(r) -&gt; color</code> </td><td> create a color tint                             </td></tr>
<tr><td> <code>col:shade(r) -&gt; color</code> </td><td> create a color shade                            </td></tr>