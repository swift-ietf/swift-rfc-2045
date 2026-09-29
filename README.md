# swift-rfc-2045

Domain model for RFC 2045, the MIME message body format: `RFC_2045.ContentType` with its `RFC_2045.Parameter.Name` keys, `RFC_2045.ContentTransferEncoding`, `RFC_2045.Charset`, and the MIME entries of `RFC_5322.Header.Name`. Every type validates on construction and reads its RFC text form through `init(_:)` / `init(ascii:)`; `ContentType` is also built from structured parts, and the well-known values are static members (`.textPlain`, `.utf8`, `.base64`, `.charset`). The `RFC 2045 Foundation Integration` product bridges the types to `Codable`. Text forms and wire coders — `ContentType.description`, `headerValue` and `rawValue`, the `ASCII.Parseable`, `ASCII.Serializable` and `Binary.Serializable` conformances, `[Byte].init(_:)`, the nested `Coder` types and the `RFC_5322.Header` initializers — live in [swift-rfc-2045-coder](https://github.com/swift-ietf/swift-rfc-2045-coder).

```swift
import RFC_2045

let contentType = try RFC_2045.ContentType("text/html; charset=UTF-8")
contentType.type                                     // "text"
contentType.charset                                  // RFC_2045.Charset.utf8
contentType == RFC_2045.ContentType.textHTMLUTF8     // true

let encoding = try RFC_2045.ContentTransferEncoding("quoted-printable")
encoding.isEncoded                                   // true

let attachment = RFC_2045.ContentType.applicationPDF(name: "invoice.pdf")
attachment.parameters[.name]                         // "invoice.pdf"
```
