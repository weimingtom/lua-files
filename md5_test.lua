local sum = require'md5'.sum

assert(sum'your momma is fat' == 'f208dff3c12214035c3e53498275a2cb')
assert(sum'it\'s all int the game yo' == '58e00aee91545abffe9ce1b3da72271f')

-- test some known sums
assert(sum('') == 'd41d8cd98f00b204e9800998ecf8427e')
assert(sum('a') == '0cc175b9c0f1b6a831c399e269772661')
assert(sum('abc') == '900150983cd24fb0d6963f7d28e17f72')
assert(sum('message sum') == '7806a73c70c943615354a1caa6e05095')
assert(sum('abcdefghijklmnopqrstuvwxyz') == 'c3fcd3d76192e4007dfb496cca67e13b')
assert(sum('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789')
 == 'd174ab98d277d9f5a5611c2c9f419d9f')

-- test padding borders
assert(sum(string.rep('a',53)) == 'e9e7e260dce84ffa6e0e7eb5fd9d37fc')
assert(sum(string.rep('a',54)) == 'eced9e0b81ef2bba605cbc5e2e76a1d0')
assert(sum(string.rep('a',55)) == 'ef1772b6dff9a122358552954ad0df65')
assert(sum(string.rep('a',56)) == '3b0c8ac703f828b04c6c197006d17218')
assert(sum(string.rep('a',57)) == '652b906d60af96844ebd21b674f35e93')
assert(sum(string.rep('a',63)) == 'b06521f39153d618550606be297466d5')
assert(sum(string.rep('a',64)) == '014842d480b571495a4a0363793f7367')
assert(sum(string.rep('a',65)) == 'c743a45e0d2e6a95cb859adae0248435')
assert(sum(string.rep('a',255)) == '46bc249a5a8fc5d622cf12c42c463ae0')
assert(sum(string.rep('a',256)) == '81109eec5aa1a284fb5327b10e9c16b9')

assert(sum(
'12345678901234567890123456789012345678901234567890123456789012345678901234567890')
	== '57edf4a22be3c955ac49da2e2107b67a')
