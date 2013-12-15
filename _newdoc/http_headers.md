http header value parser

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/http_headers.lua) | [test](http://code.google.com/p/lua-files/source/browse/http_headers_test.lua)

## `local http_headers = require'http_headers'`

Parsing of HTTP/1.1 header values.

## `http_headers.parse_value(header, value) -> parsed_value | nil,error`

Parse a normalized http header name/value pair, as the ones returned by [http_parser http_parser.headers].

## `http_headers.parse_values(headers_t) -> parsed_headers_t, errors`

Parse a table of normalized http headers, as the one returned by [http_parser http_parser.headers]. Values for unknown headers are returned unchanged. Invalid values are returned separately in the errors table.

## `http_headers.lazy_parse(headers_t) -> lazy_headers_t`

Like above, but returns a lazy table in which values are only parsed when the table is indexed.

## `http_headers.parsers -> {header_name = parser_function}`

The list of value parsers, open for extending for parsing of any non-standard headers. `parser_function(s) -> v | nil[,error]`.
