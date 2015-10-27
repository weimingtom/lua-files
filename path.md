v0.0 (in active development) | [API](path_api.md) | [code](http://code.google.com/p/lua-files/source/browse/path.lua) | LuaJIT 2, Lua 5.1, Lua 5.2

## `local path = require'path'` ##

Fast, full-featured 2D geometry library.<br>
Includes construction, drawing, measuring, hit testing and editing of 2D paths.<br>
<br>
<h3>Overview</h3>
<ul><li>written in Lua<br>
</li><li>modular, bottom-up style programming (procedural, no state, no objects)<br>
</li><li>dynamic allocations avoided throughout<br>
</li><li>all features available under <a href='affine2d.md'>affine transformation</a>, with fast code paths for special cases<br>
</li><li>full support for SVG path command set and semantics and more.</li></ul>

<h3>Geometric types</h3>
<ul><li><a href='path_line.md'>lines</a>, with horizontal and vertical variations<br>
</li><li><a href='path_bezier2.md'>quadratic</a> bezier curves and <a href='path_bezier3.md'>cubic bezier curves</a>, with smooth and symmetrical variations<br>
</li><li>absolute and relative-to-current-point variations for all commands<br>
</li><li><a href='path_arc.md'>elliptic arcs</a>, <a href='path_arc_3p.md'>3-point circular arcs</a> and <a href='path_svgarc.md'>svg-style</a> elliptic arcs and <a href='path_circle_3p.md'>3-point circles</a>
</li><li>composite <a href='path_shapes.md'>shapes</a>:<br>
<ul><li>rectangles, including round-corner and elliptic-corner variations<br>
</li><li>circles and ellipses, and 3-point circles<br>
</li><li>1-anchor-point and 2-anchor-point stars, and regular polygons<br>
</li><li>superformula<br>
</li></ul></li><li><a href='path_text.md'>text</a>, using <a href='freetype.md'>freetype</a>, <a href='harfbuzz.md'>harfbuzz</a>, <a href='libunibreak.md'>libunibreak</a> for fonts and shaping (NYI)<br>
</li><li><a href='path_catmull.md'>catmull-rom</a> splines (NYI)<br>
</li><li><a href='path_spline3.md'>cubic splines</a> (NYI)<br>
</li><li><a href='path_spiro.md'>spiro curves</a> (NYI, GPL but darn hot)</li></ul>

<h3>Measuring</h3>
<ul><li>bounding box<br>
</li><li>length at time t<br>
</li><li>point at time t<br>
</li><li>arc length parametrization (NYI)</li></ul>

<h3>Hit testing</h3>
<ul><li>shortest distance from point<br>
</li><li>inside/outside testing for closed subpaths (NYI)</li></ul>

<h3>Drawing</h3>
<ul><li>simplification (decomposing into primitive operations)<br>
</li><li>adaptive interpolation of quad and cubic bezier curves<br>
</li><li>polygon offseting with different line join and line cap styles (NYI)<br>
</li><li>dash generation (NYI)<br>
</li><li>text-to-path (NYI)<br>
</li><li>conversion to cairo paths for drawing with <a href='cairo.md'>cairo</a> or with <a href='sg_cairo.md'>sg_cairo</a>
</li><li>conversion to OpenVG paths for drawing with the <a href='openvg.md'>openvg</a> API (NYI)</li></ul>

<h3>Editing</h3>
<ul><li>adding, removing and updating commands<br>
</li><li>splitting of lines, curves and arcs at time t<br>
</li><li>joining of lines, curves and arcs (NYI)<br>
</li><li>conversion between lines, curves, arcs and composite shapes (NYI).<br>
</li><li>direct manipulation <a href='path_edit.md'>path editor</a> with chained updates and constraints, making it easy to customize and extend to support new command types (TODO).</li></ul>

<h3>Help needed</h3>

<ul><li>I am far from being an expert at floating point math. I'm sure there are many opportunities for preserving precision and avoiding degenerate cases that I've haven't thought about. A code review by someone experienced in this area would help greatly.</li></ul>

<ul><li>When an elliptic (or circular) arc is approximated with bezier curves, the arc t value (sweep time) is almost the same as the curve t value (parametric time). Almost, but not quite. The error is contained by increasing the number of segments that make up the arc. But instead of increasing the number of segments for larger arcs, I would prefer to have a formula to synchronize the t values for a chosen number of segments, assuming such formula is easy enough to compute.