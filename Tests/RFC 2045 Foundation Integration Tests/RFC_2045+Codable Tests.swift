import Foundation
import RFC_2045
import RFC_2045_Foundation_Integration
import Testing

@Suite
struct `RFC_2045+Codable Tests` {

    @Test
    func `a charset codes as its text form`() throws {
        let charset = RFC_2045.Charset.utf8

        let encoded = try JSONEncoder().encode(charset)

        #expect(String(decoding: encoded, as: UTF8.self) == #""UTF-8""#)
        #expect(try JSONDecoder().decode(RFC_2045.Charset.self, from: encoded) == charset)
    }

    @Test
    func `a content transfer encoding codes as its mechanism name`() throws {
        let encoding = RFC_2045.ContentTransferEncoding.quotedPrintable

        let encoded = try JSONEncoder().encode(encoding)

        #expect(String(decoding: encoded, as: UTF8.self) == #""quoted-printable""#)
        #expect(
            try JSONDecoder().decode(RFC_2045.ContentTransferEncoding.self, from: encoded)
                == encoding
        )
    }

    @Test
    func `a parameter name codes as its text form`() throws {
        let name = RFC_2045.Parameter.Name.charset

        let encoded = try JSONEncoder().encode(name)

        #expect(String(decoding: encoded, as: UTF8.self) == #""charset""#)
        #expect(try JSONDecoder().decode(RFC_2045.Parameter.Name.self, from: encoded) == name)
    }

    @Test
    func `a content type codes as its structured parts`() throws {
        let contentType = RFC_2045.ContentType.textPlainUTF8

        let encoded = try JSONEncoder().encode(contentType)

        #expect(
            try JSONDecoder().decode(RFC_2045.ContentType.self, from: encoded) == contentType
        )
    }
}
