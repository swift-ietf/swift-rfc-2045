// RFC_2045.Parameter.Name Tests.swift
// swift-rfc-2045
//
// Tests for RFC_2045.Parameter.Name MIME parameter name

import Testing
import Testing_Extras

@testable import RFC_2045

// MARK: - Parsing Tests

@Suite
struct `Parameter.Name - Parsing Tests` {
    @Suite
    struct `Valid Names` {
        @Test
        func `parse charset`() throws {
            let name = try RFC_2045.Parameter.Name(ascii: Array("charset".utf8))
            #expect(name.rawValue == "charset")
        }

        @Test
        func `parse boundary`() throws {
            let name = try RFC_2045.Parameter.Name(ascii: Array("boundary".utf8))
            #expect(name.rawValue == "boundary")
        }

        @Test
        func `parse custom parameter`() throws {
            let name = try RFC_2045.Parameter.Name(ascii: Array("x-custom".utf8))
            #expect(name.rawValue == "x-custom")
        }

        @Test
        func `parse with digits`() throws {
            let name = try RFC_2045.Parameter.Name(ascii: Array("param123".utf8))
            #expect(name.rawValue == "param123")
        }

        @Test
        func `parse mixed case becomes lowercase`() {
            let name = RFC_2045.Parameter.Name(rawValue: "CHARSET")
            #expect(name.rawValue == "charset")
        }
    }

    @Suite
    struct `Error Cases` {
        @Test
        func `empty bytes throws empty error`() {
            #expect(throws: RFC_2045.Parameter.Name.Error.empty) {
                try RFC_2045.Parameter.Name(ascii: [UInt8]())
            }
        }

        @Test
        func `space character throws error`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: Array("char set".utf8))
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `control character throws error`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: [0x00])
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `equals sign throws error (tspecial)`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: Array("param=value".utf8))
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `semicolon throws error (tspecial)`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: Array("param;name".utf8))
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `solidus throws error (tspecial)`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: Array("param/name".utf8))
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `quotation mark throws error (tspecial)`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: Array("param\"name".utf8))
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `left parenthesis throws error (tspecial)`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: Array("param(name".utf8))
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }

        @Test
        func `at sign throws error (tspecial)`() {
            #expect {
                try RFC_2045.Parameter.Name(ascii: Array("param@name".utf8))
            } throws: { error in
                guard case RFC_2045.Parameter.Name.Error.invalidCharacter = error else {
                    return false
                }
                return true
            }
        }
    }
}

// MARK: - Static Constants Tests

@Suite
struct `Parameter.Name - Static Constants Tests` {
    @Test
    func `charset constant`() {
        #expect(RFC_2045.Parameter.Name.charset.rawValue == "charset")
    }

    @Test
    func `boundary constant`() {
        #expect(RFC_2045.Parameter.Name.boundary.rawValue == "boundary")
    }

    @Test
    @available(*, deprecated)
    func `name constant (deprecated)`() {
        #expect(RFC_2045.Parameter.Name.name.rawValue == "name")
    }
}

// MARK: - Equality Tests

@Suite
struct `Parameter.Name - Equality Tests` {
    @Test
    func `equal names are equal`() {
        let name1 = RFC_2045.Parameter.Name.charset
        let name2 = RFC_2045.Parameter.Name.charset
        #expect(name1 == name2)
    }

    @Test
    func `case insensitive equality`() {
        let name1 = RFC_2045.Parameter.Name(rawValue: "charset")
        let name2 = RFC_2045.Parameter.Name(rawValue: "CHARSET")
        #expect(name1 == name2)
    }

    @Test
    func `equality with string - same case`() {
        let name = RFC_2045.Parameter.Name.charset
        #expect(name == "charset")
    }

    @Test
    func `equality with string - different case`() {
        let name = RFC_2045.Parameter.Name.charset
        #expect(name == "CHARSET")
    }

    @Test
    func `different names are not equal`() {
        let name1 = RFC_2045.Parameter.Name.charset
        let name2 = RFC_2045.Parameter.Name.boundary
        #expect(name1 != name2)
    }
}

// MARK: - Hashable Tests

@Suite
struct `Parameter.Name - Hashable Tests` {
    @Test
    func `same name produces same hash`() {
        let name1 = RFC_2045.Parameter.Name.charset
        let name2 = RFC_2045.Parameter.Name(rawValue: "charset")
        #expect(name1.hashValue == name2.hashValue)
    }

    @Test
    func `case insensitive hashing`() {
        let name1 = RFC_2045.Parameter.Name(rawValue: "charset")
        let name2 = RFC_2045.Parameter.Name(rawValue: "CHARSET")
        #expect(name1.hashValue == name2.hashValue)
    }

    @Test
    func `names work in Set`() {
        var set: Set<RFC_2045.Parameter.Name> = []
        set.insert(.charset)
        set.insert(RFC_2045.Parameter.Name(rawValue: "CHARSET"))
        #expect(set.count == 1)
    }

    @Test
    func `names work as Dictionary keys`() {
        var dict: [RFC_2045.Parameter.Name: String] = [:]
        dict[.charset] = "first"
        dict[RFC_2045.Parameter.Name(rawValue: "CHARSET")] = "second"
        #expect(dict.count == 1)
        #expect(dict[.charset] == "second")
    }
}

// MARK: - Comparable Tests

@Suite
struct `Parameter.Name - Comparable Tests` {
    @Test
    func `boundary comes before charset`() {
        #expect(RFC_2045.Parameter.Name.boundary < RFC_2045.Parameter.Name.charset)
    }

    @Test
    func `case insensitive comparison`() {
        let name1 = RFC_2045.Parameter.Name(rawValue: "ALPHA")
        let name2 = RFC_2045.Parameter.Name(rawValue: "beta")
        #expect(name1 < name2)
    }

    @Test
    func `sorting works correctly`() {
        let names: [RFC_2045.Parameter.Name] = [
            .charset,
            .boundary,
            RFC_2045.Parameter.Name(rawValue: "x-custom"),
        ]
        let sorted = names.sorted()
        #expect(sorted[0] == .boundary)
        #expect(sorted[1] == .charset)
        #expect(sorted[2].rawValue == "x-custom")
    }
}

// MARK: - Serialization Tests

@Suite
struct `Parameter.Name - Serialization Tests` {
    @Test(arguments: [
        RFC_2045.Parameter.Name.charset,
        RFC_2045.Parameter.Name.boundary,
        RFC_2045.Parameter.Name(rawValue: "x-custom"),
    ])
    func `round-trip serialization`(name: RFC_2045.Parameter.Name) throws {
        let bytes = [UInt8](name)
        let parsed = try RFC_2045.Parameter.Name(ascii: bytes)
        #expect(name == parsed)
    }

    @Test
    func `description matches rawValue`() {
        let name = RFC_2045.Parameter.Name.charset
        #expect(name.description == name.rawValue)
    }

    @Test
    func `byte serialization produces lowercase`() {
        let name = RFC_2045.Parameter.Name(rawValue: "CHARSET")
        let bytes = [UInt8](name)
        #expect(bytes == Array("charset".utf8))
    }
}

// MARK: - CaseInsensitive String Initialization Tests

@Suite
struct `Parameter.Name - CaseInsensitive Initialization Tests` {
    @Test
    func `init from CaseInsensitive string`() {
        let caseInsensitive = String.CaseInsensitive("Charset")
        let name = RFC_2045.Parameter.Name(caseInsensitive)
        #expect(name.rawValue == "charset")
    }
}

// MARK: - Performance Tests

@Suite
struct `Parameter.Name - Performance` {
    @Test(.timed(threshold: .milliseconds(500)))
    func `parse 100K names`() throws {
        for _ in 0..<100_000 {
            _ = try RFC_2045.Parameter.Name(ascii: Array("charset".utf8))
        }
    }

    @Test(.timed(threshold: .milliseconds(500)))
    func `serialize 100K names`() {
        let name = RFC_2045.Parameter.Name.charset
        for _ in 0..<100_000 {
            _ = [UInt8](name)
        }
    }
}
