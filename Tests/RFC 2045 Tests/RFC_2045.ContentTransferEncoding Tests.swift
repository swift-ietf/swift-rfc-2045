// RFC_2045.ContentTransferEncoding Tests.swift
// swift-rfc-2045
//
// Tests for RFC_2045.ContentTransferEncoding MIME Content-Transfer-Encoding header

import Testing
import Testing_Extras

@testable import RFC_2045

// MARK: - Parsing Tests

@Suite
struct `ContentTransferEncoding - Parsing Tests` {
    @Suite
    struct `Valid Encodings` {
        @Test
        func `parse 7bit`() throws {
            let encoding = try RFC_2045.ContentTransferEncoding("7bit")
            #expect(encoding == .sevenBit)
        }

        @Test
        func `parse 8bit`() throws {
            let encoding = try RFC_2045.ContentTransferEncoding("8bit")
            #expect(encoding == .eightBit)
        }

        @Test
        func `parse binary`() throws {
            let encoding = try RFC_2045.ContentTransferEncoding("binary")
            #expect(encoding == .binary)
        }

        @Test
        func `parse base64`() throws {
            let encoding = try RFC_2045.ContentTransferEncoding("base64")
            #expect(encoding == .base64)
        }

        @Test
        func `parse quoted-printable`() throws {
            let encoding = try RFC_2045.ContentTransferEncoding("quoted-printable")
            #expect(encoding == .quotedPrintable)
        }

        @Test
        func `case insensitive parsing`() throws {
            let encoding1 = try RFC_2045.ContentTransferEncoding("BASE64")
            let encoding2 = try RFC_2045.ContentTransferEncoding("Base64")
            let encoding3 = try RFC_2045.ContentTransferEncoding("base64")
            #expect(encoding1 == encoding2)
            #expect(encoding2 == encoding3)
        }

        @Test
        func `whitespace trimming`() throws {
            let encoding = try RFC_2045.ContentTransferEncoding("  base64  ")
            #expect(encoding == .base64)
        }

        @Test
        func `tab trimming`() throws {
            let encoding = try RFC_2045.ContentTransferEncoding("\tbase64\t")
            #expect(encoding == .base64)
        }
    }

    @Suite
    struct `Error Cases` {
        @Test
        func `empty string throws empty error`() {
            #expect(throws: RFC_2045.ContentTransferEncoding.Error.empty) {
                try RFC_2045.ContentTransferEncoding("")
            }
        }

        @Test
        func `whitespace only throws empty error`() {
            #expect(throws: RFC_2045.ContentTransferEncoding.Error.empty) {
                try RFC_2045.ContentTransferEncoding("   ")
            }
        }

        @Test
        func `unrecognized encoding throws error`() {
            #expect {
                try RFC_2045.ContentTransferEncoding("unknown")
            } throws: { error in
                guard case RFC_2045.ContentTransferEncoding.Error.unrecognizedEncoding = error
                else {
                    return false
                }
                return true
            }
        }

        @Test
        func `partial match throws error`() {
            #expect {
                try RFC_2045.ContentTransferEncoding("base")
            } throws: { error in
                guard case RFC_2045.ContentTransferEncoding.Error.unrecognizedEncoding = error
                else {
                    return false
                }
                return true
            }
        }
    }
}

// MARK: - Raw Value Tests

@Suite
struct `ContentTransferEncoding - Raw Value Tests` {
    @Test
    func `sevenBit raw value`() {
        #expect(RFC_2045.ContentTransferEncoding.sevenBit.rawValue == "7bit")
    }

    @Test
    func `eightBit raw value`() {
        #expect(RFC_2045.ContentTransferEncoding.eightBit.rawValue == "8bit")
    }

    @Test
    func `binary raw value`() {
        #expect(RFC_2045.ContentTransferEncoding.binary.rawValue == "binary")
    }

    @Test
    func `base64 raw value`() {
        #expect(RFC_2045.ContentTransferEncoding.base64.rawValue == "base64")
    }

    @Test
    func `quotedPrintable raw value`() {
        #expect(RFC_2045.ContentTransferEncoding.quotedPrintable.rawValue == "quoted-printable")
    }
}

// MARK: - Properties Tests

@Suite
struct `ContentTransferEncoding - Properties Tests` {
    @Suite
    struct `headerValue Property` {
        @Test(arguments: [
            (RFC_2045.ContentTransferEncoding.sevenBit, "7bit"),
            (RFC_2045.ContentTransferEncoding.eightBit, "8bit"),
            (RFC_2045.ContentTransferEncoding.binary, "binary"),
            (RFC_2045.ContentTransferEncoding.base64, "base64"),
            (RFC_2045.ContentTransferEncoding.quotedPrintable, "quoted-printable"),
        ])
        func `headerValue matches expected`(
            encoding: RFC_2045.ContentTransferEncoding,
            expected: String
        ) {
            #expect(encoding.description == expected)
        }
    }

    @Suite
    struct `isBinarySafe Property` {
        @Test
        func `base64 is binary safe`() {
            #expect(RFC_2045.ContentTransferEncoding.base64.isBinarySafe)
        }

        @Test
        func `quotedPrintable is binary safe`() {
            #expect(RFC_2045.ContentTransferEncoding.quotedPrintable.isBinarySafe)
        }

        @Test
        func `sevenBit is not binary safe`() {
            #expect(!RFC_2045.ContentTransferEncoding.sevenBit.isBinarySafe)
        }

        @Test
        func `eightBit is not binary safe`() {
            #expect(!RFC_2045.ContentTransferEncoding.eightBit.isBinarySafe)
        }

        @Test
        func `binary is not binary safe`() {
            #expect(!RFC_2045.ContentTransferEncoding.binary.isBinarySafe)
        }
    }

    @Suite
    struct `isEncoded Property` {
        @Test
        func `base64 is encoded`() {
            #expect(RFC_2045.ContentTransferEncoding.base64.isEncoded)
        }

        @Test
        func `quotedPrintable is encoded`() {
            #expect(RFC_2045.ContentTransferEncoding.quotedPrintable.isEncoded)
        }

        @Test
        func `sevenBit is not encoded`() {
            #expect(!RFC_2045.ContentTransferEncoding.sevenBit.isEncoded)
        }

        @Test
        func `eightBit is not encoded`() {
            #expect(!RFC_2045.ContentTransferEncoding.eightBit.isEncoded)
        }

        @Test
        func `binary is not encoded`() {
            #expect(!RFC_2045.ContentTransferEncoding.binary.isEncoded)
        }
    }
}

// MARK: - Serialization Tests

@Suite
struct `ContentTransferEncoding - Serialization Tests` {
    @Test(arguments: [
        RFC_2045.ContentTransferEncoding.sevenBit,
        RFC_2045.ContentTransferEncoding.eightBit,
        RFC_2045.ContentTransferEncoding.binary,
        RFC_2045.ContentTransferEncoding.base64,
        RFC_2045.ContentTransferEncoding.quotedPrintable,
    ])
    func `round-trip serialization`(encoding: RFC_2045.ContentTransferEncoding) throws {
        let bytes = [UInt8](encoding)
        let parsed = try RFC_2045.ContentTransferEncoding(ascii: bytes)
        #expect(encoding == parsed)
    }

    @Test
    func `description matches headerValue`() {
        let encoding = RFC_2045.ContentTransferEncoding.base64
        #expect(encoding.description == encoding.description)
    }
}

// MARK: - Performance Tests

@Suite
struct `ContentTransferEncoding - Performance` {
    @Test(.timed(threshold: .milliseconds(1000)))
    func `parse 100K encodings`() throws {
        for _ in 0..<100_000 {
            _ = try RFC_2045.ContentTransferEncoding("base64")
        }
    }

    @Test(.timed(threshold: .milliseconds(500)))
    func `serialize 100K encodings`() {
        let encoding = RFC_2045.ContentTransferEncoding.base64
        for _ in 0..<100_000 {
            _ = [UInt8](encoding)
        }
    }
}
