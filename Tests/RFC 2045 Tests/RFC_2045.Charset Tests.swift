// RFC_2045.Charset Tests.swift
// swift-rfc-2045
//
// Tests for RFC_2045.Charset MIME character set identifier

import Testing
import Testing_Extras

@testable import RFC_2045

// MARK: - Parsing Tests

@Suite
struct `Charset - Parsing Tests` {
    @Suite
    struct `Valid Charsets` {
        @Test
        func `parse UTF-8`() throws {
            let charset = try RFC_2045.Charset(ascii: Array("UTF-8".utf8))
            #expect(charset.rawValue == "UTF-8")
        }

        @Test
        func `parse US-ASCII`() throws {
            let charset = try RFC_2045.Charset(ascii: Array("US-ASCII".utf8))
            #expect(charset.rawValue == "US-ASCII")
        }

        @Test
        func `parse ISO-8859-1`() throws {
            let charset = try RFC_2045.Charset(ascii: Array("ISO-8859-1".utf8))
            #expect(charset.rawValue == "ISO-8859-1")
        }

        @Test
        func `case insensitive parsing - lowercase becomes uppercase`() {
            let charset = RFC_2045.Charset("utf-8")
            #expect(charset.rawValue == "UTF-8")
        }

        @Test
        func `case insensitive parsing - mixed case becomes uppercase`() {
            let charset = RFC_2045.Charset("Utf-8")
            #expect(charset.rawValue == "UTF-8")
        }
    }

    @Suite
    struct `Error Cases` {
        @Test
        func `empty bytes throws empty error`() {
            #expect(throws: RFC_2045.Charset.Error.empty) {
                try RFC_2045.Charset(ascii: [UInt8]())
            }
        }

        @Test
        func `control character throws error`() {
            #expect {
                try RFC_2045.Charset(ascii: [0x00])
            } throws: { error in
                guard case RFC_2045.Charset.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `space character throws error`() {
            #expect {
                try RFC_2045.Charset(ascii: Array("UTF 8".utf8))
            } throws: { error in
                guard case RFC_2045.Charset.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }
    }
}

// MARK: - Static Constants Tests

@Suite
struct `Charset - Static Constants Tests` {
    @Test
    func `utf8 constant`() {
        #expect(RFC_2045.Charset.utf8.rawValue == "UTF-8")
    }

    @Test
    func `usASCII constant`() {
        #expect(RFC_2045.Charset.usASCII.rawValue == "US-ASCII")
    }

    @Test
    func `iso88591 constant`() {
        #expect(RFC_2045.Charset.iso88591.rawValue == "ISO-8859-1")
    }

    @Test
    func `utf16 constant`() {
        #expect(RFC_2045.Charset.utf16.rawValue == "UTF-16")
    }

    @Test
    func `utf16BE constant`() {
        #expect(RFC_2045.Charset.utf16BE.rawValue == "UTF-16BE")
    }

    @Test
    func `utf16LE constant`() {
        #expect(RFC_2045.Charset.utf16LE.rawValue == "UTF-16LE")
    }

    @Test
    func `utf32 constant`() {
        #expect(RFC_2045.Charset.utf32.rawValue == "UTF-32")
    }

    @Test
    func `iso88592 constant`() {
        #expect(RFC_2045.Charset.iso88592.rawValue == "ISO-8859-2")
    }

    @Test
    func `iso885915 constant`() {
        #expect(RFC_2045.Charset.iso885915.rawValue == "ISO-8859-15")
    }

    @Test
    func `windows1252 constant`() {
        #expect(RFC_2045.Charset.windows1252.rawValue == "WINDOWS-1252")
    }
}

// MARK: - Equality Tests

@Suite
struct `Charset - Equality Tests` {
    @Test
    func `equal charsets are equal`() {
        let charset1 = RFC_2045.Charset.utf8
        let charset2 = RFC_2045.Charset.utf8
        #expect(charset1 == charset2)
    }

    @Test
    func `case insensitive equality`() {
        let charset1 = RFC_2045.Charset("utf-8")
        let charset2 = RFC_2045.Charset("UTF-8")
        #expect(charset1 == charset2)
    }

    @Test
    func `equality with string - same case`() {
        let charset = RFC_2045.Charset.utf8
        #expect(charset == "UTF-8")
    }

    @Test
    func `equality with string - different case`() {
        let charset = RFC_2045.Charset.utf8
        #expect(charset == "utf-8")
    }

    @Test
    func `optional equality with string - some`() {
        let charset: RFC_2045.Charset? = .utf8
        #expect(charset == "UTF-8")
    }

    @Test
    func `optional equality with string - nil`() {
        let charset: RFC_2045.Charset? = nil
        #expect(!(charset == "UTF-8"))
    }

    @Test
    func `different charsets are not equal`() {
        let charset1 = RFC_2045.Charset.utf8
        let charset2 = RFC_2045.Charset.usASCII
        #expect(charset1 != charset2)
    }
}

// MARK: - Hashable Tests

@Suite
struct `Charset - Hashable Tests` {
    @Test
    func `same charset produces same hash`() {
        let charset1 = RFC_2045.Charset.utf8
        let charset2 = RFC_2045.Charset("UTF-8")
        #expect(charset1.hashValue == charset2.hashValue)
    }

    @Test
    func `case insensitive hashing`() {
        let charset1 = RFC_2045.Charset("utf-8")
        let charset2 = RFC_2045.Charset("UTF-8")
        #expect(charset1.hashValue == charset2.hashValue)
    }

    @Test
    func `charsets work in Set`() {
        var set: Set<RFC_2045.Charset> = []
        set.insert(.utf8)
        set.insert(RFC_2045.Charset("utf-8"))
        #expect(set.count == 1)
    }

    @Test
    func `charsets work as Dictionary keys`() {
        var dict: [RFC_2045.Charset: String] = [:]
        dict[.utf8] = "first"
        dict[RFC_2045.Charset("utf-8")] = "second"
        #expect(dict.count == 1)
        #expect(dict[.utf8] == "second")
    }
}

// MARK: - Serialization Tests

@Suite
struct `Charset - Serialization Tests` {
    @Test(arguments: [
        RFC_2045.Charset.utf8,
        RFC_2045.Charset.usASCII,
        RFC_2045.Charset.iso88591,
        RFC_2045.Charset.utf16,
        RFC_2045.Charset.utf16BE,
        RFC_2045.Charset.utf16LE,
        RFC_2045.Charset.windows1252,
    ])
    func `round-trip serialization`(charset: RFC_2045.Charset) throws {
        let bytes = [UInt8](charset)
        let parsed = try RFC_2045.Charset(ascii: bytes)
        #expect(charset == parsed)
    }

    @Test
    func `description matches rawValue`() {
        let charset = RFC_2045.Charset.utf8
        #expect(charset.description == charset.rawValue)
    }

    @Test
    func `byte serialization produces correct output`() {
        let charset = RFC_2045.Charset.utf8
        let bytes = [UInt8](charset)
        #expect(bytes == Array("UTF-8".utf8))
    }
}

// MARK: - Performance Tests

@Suite
struct `Charset - Performance` {
    @Test(.timed(threshold: .milliseconds(500)))
    func `parse 100K charsets`() throws {
        for _ in 0..<100_000 {
            _ = try RFC_2045.Charset(ascii: Array("UTF-8".utf8))
        }
    }

    @Test(.timed(threshold: .milliseconds(500)))
    func `serialize 100K charsets`() {
        let charset = RFC_2045.Charset.utf8
        for _ in 0..<100_000 {
            _ = [UInt8](charset)
        }
    }
}
