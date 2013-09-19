--codedit: code editor engine by Cosmin Apreutesei (unlicensed).

--main class
local editor = require'codedit_editor'

--buffer access
require'codedit_undo'    --undo/redo stack
require'codedit_lines'   --line-based interface
require'codedit_cols'    --pos-based interface
require'codedit_tabs'    --tab expansion
require'codedit_indent'  --indent/outdent
require'codedit_blocks'  --block interface

--global text operations
require'codedit_detect'
require'codedit_normal'

--selection & cursor objects
require'codedit_selection'
require'codedit_cursor'

--rendering
require'codedit_margins'
require'codedit_metrics'
require'codedit_scroll'
require'codedit_render'

--controller
require'codedit_keys'
require'codedit_ui'


if not ... then require'codedit_demo' end

return editor
