--codedit str submodule for text reflowing
local str = require'codedit_str'
local glue = require'glue'

--split a list of text lines into paragraphs. paragraphs break at empty lines and when indentation changes.
--a paragraph is a list of lines plus the fields indent and newline.
--TODO: we can also have paragraphs for which only the first line is indented.
function str.paragraphs(lines)
	local paragraphs = {}
	local paragraph
	local last_indent
	for _,line in ipairs(lines) do
		local indent = str.first_nonspace(line) --TODO: when comparing indents, compare vcols, not chars
		if indent ~= last_indent or indent > #line then
			paragraph = {
				indent = str.sub(line, 1, indent - 1), --paragraph indent whitespace, verbatim
				newline = indent > #line, --paragraph starts with a newline
			}
			table.insert(paragraphs, paragraph)
		end
		table.insert(paragraph, line)
		last_indent = indent
	end
	return paragraphs
end

--given a line of text, break the text at spaces and return the resulting list of words.
--multiple consecutive spaces and tabs are treated as one space.
--TODO: break at explicit hypenation if it's between two word-chars.
function str.line_words(line, words)
	local words = words or {}
	local i1, i2 --start and end byte indices in s for the current word
	for i in str.byte_indices(line) do
		if not str.isspace(line, i) then
			if not i1 then --start a word
				i1 = i
				i2 = i
			else --continue the word
				i2 = i
			end
		elseif i1 then --end the word and skip other spaces
			table.insert(words, line:sub(i1, i2))
			i1, i2 = nil
		end
	end
	if i1 then
		table.insert(words, line:sub(i1, i2))
	end
	return words
end

--given a list of text lines, break the text into words.
function str.words(lines, words)
	for _,line in ipairs(lines) do
		words = str.line_words(line, words)
	end
	return words
end

--word wrapping algorithms for word wrapping a list of words over a maximum allowed line width.

local wrap = {} --{name = f(words, line_width)}

function str.wrap(words, line_width, how)
	return wrap[how](words, line_width)
end

--produces the minimum amount of lines, but not the most aesthetically pleasing paragraphs.
function wrap.greedy(words, line_width)
	local lines = {}
	local space_left = line_width
	local i1 = 1
	local lasti
	for i,word in ipairs(words) do
		local word_width = str.len(word)
		if word_width + 1 > space_left then
			table.insert(lines, table.concat(words, ' ', i1, i - 1))
			i1 = i
			space_left = line_width - word_width
		else
			space_left = space_left - (word_width + 1)
		end
		lasti = i
	end
	if i1 <= #words then
		table.insert(lines, table.concat(words, ' ', i1, lasti))
	end
	return lines
end

--minimizes the difference between line lengths.
function wrap.knuth(words, line_width)
	assert'NYI'
--[[
Add start of paragraph to list of active breakpoints
For each possible breakpoint (space) B_n, starting from the beginning:
   For each breakpoint in active list as B_a:
      If B_a is too far away from B_n:
          Delete B_a from active list
      else
          Calculate badness of line from B_a to B_n
          Add B_n to active list
          If using B_a minimizes cumulative badness from start to B_n:
             Record B_a and cumulative badness as best path to B_n

The result is a linked list of breakpoints to use.

The badness of lines under consideration can be calculated like this:

Each space is assigned a nominal width, a strechability, and a shrinkability.
The badness is then calculated as the ratio of stretching or shrinking used,
relative to what is allowed, raised e.g. to the third power (in order to
ensure that several slightly bad lines are prefered over one really bad one)
]]
end

--paragraph justification algorithms over word-wrapped lines

local align = {} --alignment algorithms: {name = f(lines, line_width)}

function str.align(lines, line_width, how)
	return align[how](lines, line_width)
end

function align.left(lines, line_width)
	return lines
end

--indent the lines so that they right-aligned to line_width
function align.right(lines, line_width)
	local out_lines = {}
	for i,line in ipairs(lines) do
		out_lines[i] = str.rep(' ', line_width - str.len(line)) .. line
	end
	return out_lines
end

--indent the lines so that they are centered to line_width
function align.center(lines, line_width)
	local out_lines = {}
	for i,line in ipairs(lines) do
		out_lines[i] = str.rep(' ', line_width - str.len(line)) .. line
	end
	return out_lines
end

--for each line, add spaces to existing words at random until lines have the same width.
--TODO: prefer adding spaces after punctuation: ! . ;
function align.justify(lines, line_width)
	local out_lines = {}
	for i = 1, #lines - 1 do
		local line = lines[i]
		local spaces = line_width - str.len(line)
		local words = str.line_words(line)
		while spaces > 0 do
			local pos = math.random(1, #words - 1)
			words[pos] = words[pos] .. ' '
			spaces = spaces - 1
		end
		out_lines[i] = table.concat(words, ' ')
	end
	table.insert(out_lines, lines[#lines])
	return out_lines
end

function str.indent(lines, s)
	local out_lines = {}
	for i,line in ipairs(lines) do
		out_lines[i] = s .. line
	end
	return out_lines
end

function str.reflow(lines, line_width, align, wrap)
	local paragraphs = str.paragraphs(lines)
	local out_lines = {}
	for i,paragraph in ipairs(paragraphs) do
		local words = str.words(paragraph)
		local lines = str.wrap(words, line_width, wrap)
		local lines = str.indent(lines, paragraph.indent)
		local lines = str.align(lines, line_width, align)
		if paragraph.newline then
			table.insert(out_lines, '')
		end
		glue.extend(out_lines, lines)
	end
	return out_lines
end


if not ... then require'codedit_demo' end
