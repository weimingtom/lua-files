--scene graph for pdf: converts a 2D scene graph into pdf format.
--some modules are loaded on-demand: look for require() in the code.
local glue = require'glue'
local path_simplify = require'path_simplify'
local PDF = require'pdfgen'

local defaults = require'sg_2d'.defaults

function convert(t)
	local pdf = PDF()

	local gs = {
		line_width = 1,
	}

	local function obj(t)
		local in_page = false
		if t.type == 'page' then
			assert(not in_page, 'page objects not allowed inside a page object')
			local end_stream = pdf.stream()
			local resources = '<< >>'
			local in_page = true
			obj(t.contents)
			local in_page = false
			local contents_id = end_stream()
			pdf.page(contents_id, resources)
		elseif t.type == 'group' then
			for i,t in ipairs(t) do
				obj(t)
			end
		elseif t.type == 'shape' then

			local function setopt(k, op)
				if gs[k] ~= t[k] then
					gs[k] = t[k]
					pdf.cmd(op, t[k])
				end
			end
			if t.stroke then
				setopt('line_width', 'w')
				setopt('line_cap', '')
				setopt('miter_limit', '')
				--TODO: line-dashes
			end

			local first = true
			local function write(cmd, ...)
				if not first then pdf.S' ' else first = false end
				if cmd == 'move' then
					pdf.nums(...); pdf.S' m'
				elseif cmd == 'line' then
					pdf.nums(...); pdf.S' l'
				elseif cmd == 'curve' then
					pdf.nums(...); pdf.S' c'
				elseif cmd == 'close' then
					pdf.S'h'
				end
			end
			path_simplify(write, t.path)

			if t.stroke and t.fill then
				if t.stroke_first then
					pdf.S(t.fill_rule == 'evenodd' and ' B*' or ' B')
				else
					--TODO:
					pdf.S(t.fill_rule == 'evenodd' and ' B*' or ' B')
				end
			elseif t.stroke then
				pdf.S' S'
			else
				pdf.S(t.fill_rule == 'evenodd' and ' f*' or ' f')
			end
		elseif t.type == 'gradient' then

		elseif t.type == 'color' then

		elseif t.type == 'image' then
			--
		end
	end

	obj(t)
	return pdf.done()
end

if not ... then require'sg_pdf_test' end

return convert

