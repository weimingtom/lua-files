local hmac = require'hmac'
require'hmac_md5'
local glue = require'glue'
local unit = require'unit'

test(glue.tohex(hmac.md5('dude', 'key')), 'e9ecd7d5b2d9dc558d1c2cd173be7c38')
