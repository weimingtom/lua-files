local glue = require'glue'
local pdfgen = require'pdfgen'

pdf = pdfgen.FilePDF('test.pdf', 300, 400)
local resources = [[
<<
/ProcSet [ /PDF /Text /ImageB /ImageC /ImageI ]
/Font << /F1 7 0 R >>
>>
]]
local end_stream = pdf.stream()
pdf.S[[
1 w
100 100 100 100 re
S
]]
local contents = end_stream()
pdf.page(contents)
pdf.page(contents, 90)
pdf.close()
print(glue.readfile('test.pdf'))
