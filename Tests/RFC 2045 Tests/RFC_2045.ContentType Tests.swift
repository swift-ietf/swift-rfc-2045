// RFC_2045.ContentType Tests.swift
// swift-rfc-2045
//
// Tests for RFC_2045.ContentType MIME Content-Type header

import Testing
import Testing_Extras

@testable import RFC_2045

// MARK: - Parsing Tests

@Suite
struct `ContentType - Parsing Tests` {
    @Suite
    struct `Valid Content Types` {
        @Test
        func `simple type and subtype`() throws {
            let ct = try RFC_2045.ContentType("text/plain")
            #expect(ct.type == "text")
            #expect(ct.subtype == "plain")
            #expect(ct.parameters.isEmpty)
        }

        @Test
        func `type and subtype with charset parameter`() throws {
            let ct = try RFC_2045.ContentType("text/html; charset=UTF-8")
            #expect(ct.type == "text")
            #expect(ct.subtype == "html")
            #expect(ct.charset?.rawValue == "UTF-8")
        }

        @Test
        func `type and subtype with multiple parameters`() throws {
            let ct = try RFC_2045.ContentType(
                "multipart/mixed; boundary=----=_Part_1234; charset=UTF-8"
            )
            #expect(ct.type == "multipart")
            #expect(ct.subtype == "mixed")
            #expect(ct.boundary == "----=_Part_1234")
            #expect(ct.charset?.rawValue == "UTF-8")
        }

        @Test
        func `quoted parameter value`() throws {
            let ct = try RFC_2045.ContentType("multipart/mixed; boundary=\"----=_Part 1234\"")
            #expect(ct.boundary == "----=_Part 1234")
        }

        @Test
        func `case insensitive type and subtype`() throws {
            let ct1 = try RFC_2045.ContentType("TEXT/PLAIN")
            let ct2 = try RFC_2045.ContentType("text/plain")
            #expect(ct1 == ct2)
        }

        @Test
        func `whitespace handling`() throws {
            let ct = try RFC_2045.ContentType("text/plain ; charset = UTF-8")
            #expect(ct.type == "text")
            #expect(ct.subtype == "plain")
            #expect(ct.charset?.rawValue == "UTF-8")
        }

        @Test
        func `subtype with plus suffix`() throws {
            let ct = try RFC_2045.ContentType("application/json+xml")
            #expect(ct.type == "application")
            #expect(ct.subtype == "json+xml")
        }
    }

    @Suite
    struct `Error Cases` {
        @Test
        func `empty string throws empty error`() {
            #expect(throws: RFC_2045.ContentType.Error.empty) {
                try RFC_2045.ContentType("")
            }
        }

        @Test
        func `missing solidus throws missingSeparator`() {
            #expect {
                try RFC_2045.ContentType("textplain")
            } throws: { error in
                guard case RFC_2045.ContentType.Error.missingSeparator = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `empty type throws emptyType`() {
            #expect {
                try RFC_2045.ContentType("/plain")
            } throws: { error in
                guard case RFC_2045.ContentType.Error.emptyType = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `empty subtype throws emptySubtype`() {
            #expect {
                try RFC_2045.ContentType("text/")
            } throws: { error in
                guard case RFC_2045.ContentType.Error.emptySubtype = error else {
                    return false
                }
                return true
            }
        }
    }
}

// MARK: - Static Constants Tests

@Suite
struct `ContentType - Static Constants Tests` {
    @Test
    func `textPlain constant`() {
        let ct = RFC_2045.ContentType.textPlain
        #expect(ct.type == "text")
        #expect(ct.subtype == "plain")
        #expect(ct.parameters.isEmpty)
        #expect(ct.headerValue == "text/plain")
    }

    @Test
    func `textPlainUTF8 constant`() {
        let ct = RFC_2045.ContentType.textPlainUTF8
        #expect(ct.type == "text")
        #expect(ct.subtype == "plain")
        #expect(ct.charset?.rawValue == "UTF-8")
        #expect(ct.headerValue == "text/plain; charset=UTF-8")
    }

    @Test
    func `textHTML constant`() {
        let ct = RFC_2045.ContentType.textHTML
        #expect(ct.type == "text")
        #expect(ct.subtype == "html")
        #expect(ct.headerValue == "text/html")
    }

    @Test
    func `textHTMLUTF8 constant`() {
        let ct = RFC_2045.ContentType.textHTMLUTF8
        #expect(ct.headerValue == "text/html; charset=UTF-8")
    }

    @Test
    func `applicationJSON constant`() {
        let ct = RFC_2045.ContentType.applicationJSON
        #expect(ct.type == "application")
        #expect(ct.subtype == "json")
    }

    @Test
    func `applicationOctetStream constant`() {
        let ct = RFC_2045.ContentType.applicationOctetStream
        #expect(ct.type == "application")
        #expect(ct.subtype == "octet-stream")
    }

    @Test
    func `imageJPEG constant`() {
        let ct = RFC_2045.ContentType.imageJPEG
        #expect(ct.type == "image")
        #expect(ct.subtype == "jpeg")
    }

    @Test
    func `imagePNG constant`() {
        let ct = RFC_2045.ContentType.imagePNG
        #expect(ct.type == "image")
        #expect(ct.subtype == "png")
    }
}

// MARK: - Factory Methods Tests

@Suite
struct `ContentType - Factory Methods Tests` {
    @Test
    func `multipartAlternative factory`() {
        let ct = RFC_2045.ContentType.multipartAlternative(boundary: "test-boundary")
        #expect(ct.type == "multipart")
        #expect(ct.subtype == "alternative")
        #expect(ct.boundary == "test-boundary")
        #expect(ct.isMultipart)
    }

    @Test
    func `multipartMixed factory`() {
        let ct = RFC_2045.ContentType.multipartMixed(boundary: "----=_Part_1234")
        #expect(ct.type == "multipart")
        #expect(ct.subtype == "mixed")
        #expect(ct.boundary == "----=_Part_1234")
    }

    @Test
    func `applicationOctetStream with name`() {
        let ct = RFC_2045.ContentType.applicationOctetStream(name: "file.bin")
        #expect(ct.type == "application")
        #expect(ct.subtype == "octet-stream")
        #expect(ct.parameters[.init(rawValue: "name")] == "file.bin")
    }

    @Test
    func `imagePNG with name`() {
        let ct = RFC_2045.ContentType.imagePNG(name: "image.png")
        #expect(ct.parameters[.init(rawValue: "name")] == "image.png")
    }
}

// MARK: - Computed Properties Tests

@Suite
struct `ContentType - Computed Properties Tests` {
    @Test
    func `isMultipart returns true for multipart types`() {
        let ct = RFC_2045.ContentType.multipartMixed(boundary: "test")
        #expect(ct.isMultipart)
    }

    @Test
    func `isMultipart returns false for non-multipart types`() {
        let ct = RFC_2045.ContentType.textPlain
        #expect(!ct.isMultipart)
    }

    @Test
    func `isText returns true for text types`() {
        let ct = RFC_2045.ContentType.textHTML
        #expect(ct.isText)
    }

    @Test
    func `isText returns false for non-text types`() {
        let ct = RFC_2045.ContentType.imageJPEG
        #expect(!ct.isText)
    }

    @Test
    func `charset accessor returns nil when not present`() {
        let ct = RFC_2045.ContentType.textPlain
        #expect(ct.charset == nil)
    }

    @Test
    func `charset accessor returns value when present`() {
        let ct = RFC_2045.ContentType.textPlainUTF8
        #expect(ct.charset?.rawValue == "UTF-8")
    }
}

// MARK: - Serialization Round-Trip Tests

@Suite
struct `ContentType - Serialization Tests` {
    @Test
    func `round-trip simple content type`() throws {
        let original = RFC_2045.ContentType.textPlain
        let bytes = [UInt8](original)
        let parsed = try RFC_2045.ContentType(ascii: bytes)
        #expect(original == parsed)
    }

    @Test
    func `round-trip content type with charset`() throws {
        let original = RFC_2045.ContentType.textPlainUTF8
        let bytes = [UInt8](original)
        let parsed = try RFC_2045.ContentType(ascii: bytes)
        #expect(original == parsed)
    }

    @Test
    func `round-trip multipart with boundary`() throws {
        let original = RFC_2045.ContentType.multipartMixed(boundary: "----=_Part_1234")
        let bytes = [UInt8](original)
        let parsed = try RFC_2045.ContentType(ascii: bytes)
        #expect(original == parsed)
    }

    @Test
    func `string representation matches headerValue`() {
        let ct = RFC_2045.ContentType.textPlainUTF8
        #expect(String(ct) == ct.headerValue)
    }
}

// MARK: - Equality Tests

@Suite
struct `ContentType - Equality Tests` {
    @Test
    func `equal content types are equal`() {
        let ct1 = RFC_2045.ContentType.textPlain
        let ct2 = RFC_2045.ContentType.textPlain
        #expect(ct1 == ct2)
    }

    @Test
    func `case insensitive equality`() throws {
        let ct1 = try RFC_2045.ContentType("TEXT/PLAIN")
        let ct2 = try RFC_2045.ContentType("text/plain")
        #expect(ct1 == ct2)
    }

    @Test
    func `different types are not equal`() {
        let ct1 = RFC_2045.ContentType.textPlain
        let ct2 = RFC_2045.ContentType.textHTML
        #expect(ct1 != ct2)
    }

    @Test
    func `same type different parameters are not equal`() {
        let ct1 = RFC_2045.ContentType.textPlain
        let ct2 = RFC_2045.ContentType.textPlainUTF8
        #expect(ct1 != ct2)
    }
}

// MARK: - Performance Tests

@Suite
struct `ContentType - Performance` {
    @Test(.timed(threshold: .milliseconds(1000)))
    func `parse 10K content types`() throws {
        for _ in 0..<10_000 {
            _ = try RFC_2045.ContentType("text/html; charset=UTF-8")
        }
    }

    @Test(.timed(threshold: .milliseconds(1000)))
    func `serialize 10K content types`() {
        let ct = RFC_2045.ContentType.textHTMLUTF8
        for _ in 0..<10_000 {
            _ = [UInt8](ct)
        }
    }
}
