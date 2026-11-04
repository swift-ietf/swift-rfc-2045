# swift-rfc-2045

Use this package when you need to read, build or write the MIME header values of RFC 2045: a `Content-Type` with its parameters, a `Content-Transfer-Encoding`, or a charset name. Start from `RFC_2045.ContentType`, and from `RFC_2045.ContentTransferEncoding` or `RFC_2045.Charset` for those fields alone. For multipart bodies and boundaries, use swift-rfc-2046. To convert a content type to and from the RFC 9110 media type, use swift-media-type-standard.

## Laws

- Type and subtype are stored lowercase, so `TEXT/HTML` and `text/html` give equal values.
- Parameter names keep the spelling they were given but compare, hash and sort case-insensitively, so `BOUNDARY=abc` is found under `RFC_2045.Parameter.Name.boundary`.
- Parameter values are kept and compared exactly as given. `text/plain; charset=utf-8` is therefore not equal to `RFC_2045.ContentType.textPlainUTF8`, whose value is `UTF-8`.
- A charset name is stored uppercase and compares case-insensitively, so `utf-8` reads back as `UTF-8`.
- `RFC_2045.ContentType.charset` is nil both when there is no charset parameter and when its value is not a valid charset name.
- `RFC_2045.ContentType.init(_:)` trims whitespace around the type, subtype, parameter names and values. A parameter value is a token or a quoted string. Quoted pairs are unescaped, and a semicolon inside quotes does not end the parameter. Empty segments, such as a trailing semicolon, are skipped. A parameter without an equals sign, or with an empty unquoted value, is refused.
- `RFC_2045.ContentType.init(type:subtype:parameters:)` validates the type and subtype as tokens but accepts any parameter value.
- A transfer encoding name is read case-insensitively, ignoring surrounding spaces and tabs. Only `7bit`, `8bit`, `binary`, `quoted-printable` and `base64` are accepted.
- `RFC_2045.ContentTransferEncoding.isEncoded` and `RFC_2045.ContentTransferEncoding.isBinarySafe` are both true for `base64` and `quoted-printable` only. `binary` is not binary safe, because it does not survive a seven-bit transport.
- `RFC_2045.ContentType.rawValue` writes `type/subtype`, then each parameter as `; name=value` in case-insensitive name order. A value that is empty or not a token is quoted, with quotation marks and backslashes escaped. Reading that text back gives an equal value.
- The wire coders read only what belongs to the value and leave the rest of the input, such as a trailing CRLF. `RFC_2045.ContentType.Coder` stops before a malformed parameter and leaves it unread instead of failing. When a coder fails, the input is restored to where it started.
- With `RFC 2045 Foundation Integration`, a charset, parameter name or transfer encoding encodes as its text form. A content type encodes as an object with `type`, `subtype` and a `parameters` dictionary keyed by name. Decoding validates the same way the initializers do.
