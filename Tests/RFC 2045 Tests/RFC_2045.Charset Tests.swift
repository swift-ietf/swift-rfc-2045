import Byte
import RFC_2045
import Testing

@Suite
struct `RFC_2045.Charset Tests` {

    @Test
    func `a charset reads from its text form`() throws {
        let charset = try RFC_2045.Charset("utf-8")
        #expect(charset == RFC_2045.Charset.utf8)
        #expect(charset.description == "UTF-8")
    }

    @Test
    func `a charset reads from ASCII bytes`() throws {
        let charset = try RFC_2045.Charset(ascii: [Byte](utf8: "iso-8859-1"))
        #expect(charset == RFC_2045.Charset.iso88591)
    }

    @Test
    func `charsets compare case-insensitively`() throws {
        #expect(try RFC_2045.Charset("UTF-8") == RFC_2045.Charset("utf-8"))
        #expect(try RFC_2045.Charset("us-ascii") == "US-ASCII")
    }

    @Test
    func `the standard charsets spell their IANA names`() {
        #expect(RFC_2045.Charset.utf8.rawValue == "UTF-8")
        #expect(RFC_2045.Charset.usASCII.rawValue == "US-ASCII")
        #expect(RFC_2045.Charset.iso88591.rawValue == "ISO-8859-1")
        #expect(RFC_2045.Charset.iso88592.rawValue == "ISO-8859-2")
        #expect(RFC_2045.Charset.iso885915.rawValue == "ISO-8859-15")
        #expect(RFC_2045.Charset.utf16.rawValue == "UTF-16")
        #expect(RFC_2045.Charset.utf16BE.rawValue == "UTF-16BE")
        #expect(RFC_2045.Charset.utf16LE.rawValue == "UTF-16LE")
        #expect(RFC_2045.Charset.utf32.rawValue == "UTF-32")
        #expect(RFC_2045.Charset.windows1252.rawValue == "WINDOWS-1252")
    }

    @Test
    func `an empty charset identifier is refused`() {
        #expect(throws: RFC_2045.Charset.Error.empty) {
            try RFC_2045.Charset("")
        }
    }

    @Test
    func `a charset identifier with a space is refused`() throws {
        #expect(throws: RFC_2045.Charset.Error.self) {
            try RFC_2045.Charset("utf 8")
        }
    }

    @Test
    func `a charset identifier outside ASCII is refused`() {
        #expect(throws: RFC_2045.Charset.Error.nonASCII("utf-8é")) {
            try RFC_2045.Charset("utf-8é")
        }
    }

    @Test
    func `an invalid charset identifier has no raw representation`() {
        #expect(RFC_2045.Charset(rawValue: "") == nil)
    }
}
