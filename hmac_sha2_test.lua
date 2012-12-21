local hmac = require'hmac'
require'hmac_sha2'
local glue = require'glue'
local unit = require'unit'

local function t(hmac, message, key, with)
	test(glue.tohex(hmac(message, key)), with)
end

t(hmac.sha256, 'dude', 'key', '261d265f880c32f0ffa2b975fc9775ca61edfecc71df605ecdb8c510dfb7ca32')
t(hmac.sha384, 'dude', 'key', '4e2b27f27a8776d9beaf7df2340d9cbdb097d9e106cdaf4fb3222b9d50f1d82aa2db654c3472b52dea113b6ae7f83184')
t(hmac.sha512, 'dude', 'key', '9a7603933e7f2fdd1ef2a6028fac95cf03a9c5f13b2ac8bef69e90e891da43db9094c573f13422405932d63df5fbc50a777d7ec021091b1f916dab3fcc2a37ca')

