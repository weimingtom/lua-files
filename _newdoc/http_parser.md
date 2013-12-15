http protocol parser

v1.0 | [code](http://code.google.com/p/lua-files/source/browse/http_parser.lua) | [test](http://code.google.com/p/lua-files/source/browse/http_parser_test.lua)

## `local http_parser = require'http_parser'`

HTTP/1.1 request and response parser.

## `http_parser.request_line(s) -> method, uri, version`

Parse a http request line (without CRLF).

## `http_parser.response_line(s) -> status, message, version`

Parse a http response line (without CRLF).

# =`http_parser.headers(reader) -> {header = value, ...}`

Parse http headers given a [readbuffer]-like object (from which only `readline()` is called). Header names are normalized (lowercase, `'-'` replaced with `'_'`). Duplicate headers are combined, values get separated with a comma. Linear whitespace (LWS) is normalized to one space throughout. Other than that, no attempt is made to further parse header values. Use [http_headers] for that.


## `http_parser.body(reader, headers) -> source`

Parse the http body given a [readbuffer]-like object. The headers table is needed for `Content-Length`, `Content-Encoding` and `Transfer-Encoding`, to decide how to parse the body.

# =`http_parser.decoders -> {encoding_name = decoder, ...}`

The global decoders table, for extending the range of available transfer-encoding/content-encoding decoders. Keys are http encoding names: they reflect in the `Accept-Encoding` header. Decoders are `function(read_function) -> read_function`, so they can be pipelined.
