import Byte
import Byte
import RFC_2045
import Testing

@Suite
struct `RFC_2045.ContentTransferEncoding Tests` {

    @Test
    func `an encoding reads from its text form`() throws {
        #expect(try RFC_2045.ContentTransferEncoding("base64") == .base64)
        #expect(try RFC_2045.ContentTransferEncoding("quoted-printable") == .quotedPrintable)
        #expect(try RFC_2045.ContentTransferEncoding("7bit") == .sevenBit)
        #expect(try RFC_2045.ContentTransferEncoding("8bit") == .eightBit)
        #expect(try RFC_2045.ContentTransferEncoding("binary") == .binary)
    }

    @Test
    func `an encoding reads from ASCII bytes`() throws {
        let encoding = try RFC_2045.ContentTransferEncoding(ascii: [Byte](utf8: "base64"))
        #expect(encoding == .base64)
    }

    @Test
    func `an encoding name is case-insensitive and ignores surrounding whitespace`() throws {
        #expect(try RFC_2045.ContentTransferEncoding("BASE64") == .base64)
        #expect(try RFC_2045.ContentTransferEncoding("  Quoted-Printable  ") == .quotedPrintable)
    }

    @Test
    func `an encoding spells its RFC 2045 mechanism name`() {
        #expect(RFC_2045.ContentTransferEncoding.sevenBit.description == "7bit")
        #expect(RFC_2045.ContentTransferEncoding.eightBit.description == "8bit")
        #expect(RFC_2045.ContentTransferEncoding.binary.description == "binary")
        #expect(RFC_2045.ContentTransferEncoding.quotedPrintable.description == "quoted-printable")
        #expect(RFC_2045.ContentTransferEncoding.base64.description == "base64")
    }

    @Test
    func `the encoded mechanisms are the ones that survive a seven-bit transport`() {
        #expect(RFC_2045.ContentTransferEncoding.base64.isEncoded)
        #expect(RFC_2045.ContentTransferEncoding.quotedPrintable.isEncoded)
        #expect(!RFC_2045.ContentTransferEncoding.sevenBit.isEncoded)
        #expect(!RFC_2045.ContentTransferEncoding.eightBit.isEncoded)
        #expect(!RFC_2045.ContentTransferEncoding.binary.isEncoded)

        #expect(RFC_2045.ContentTransferEncoding.base64.isBinarySafe)
        #expect(!RFC_2045.ContentTransferEncoding.binary.isBinarySafe)
    }

    @Test
    func `an empty encoding name is refused`() {
        #expect(throws: RFC_2045.ContentTransferEncoding.Error.empty) {
            try RFC_2045.ContentTransferEncoding("   ")
        }
    }

    @Test
    func `an unknown encoding name is refused`() {
        #expect(throws: RFC_2045.ContentTransferEncoding.Error.unrecognizedEncoding("uuencode")) {
            try RFC_2045.ContentTransferEncoding("uuencode")
        }
    }
}
