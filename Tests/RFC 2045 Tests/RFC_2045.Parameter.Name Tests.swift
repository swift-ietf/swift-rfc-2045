import Byte
import Byte
import RFC_2045
import Testing

@Suite
struct `RFC_2045.Parameter.Name Tests` {

    @Test
    func `a parameter name reads from its text form`() throws {
        let name = try RFC_2045.Parameter.Name("charset")
        #expect(name == RFC_2045.Parameter.Name.charset)
    }

    @Test
    func `a parameter name reads from ASCII bytes`() throws {
        let name = try RFC_2045.Parameter.Name(ascii: [Byte](utf8: "boundary"))
        #expect(name == RFC_2045.Parameter.Name.boundary)
    }

    @Test
    func `parameter names compare case-insensitively`() throws {
        #expect(try RFC_2045.Parameter.Name("CharSet") == RFC_2045.Parameter.Name("charset"))
        #expect(try RFC_2045.Parameter.Name("BOUNDARY") == "boundary")
    }

    @Test
    func `a parameter name keeps the spelling it was given`() throws {
        let name = try RFC_2045.Parameter.Name("CharSet")
        #expect(name.rawValue == "CharSet")
        #expect(name.description == "CharSet")
    }

    @Test
    func `the standard parameter names spell their RFC 2045 attribute names`() {
        #expect(RFC_2045.Parameter.Name.charset.rawValue == "charset")
        #expect(RFC_2045.Parameter.Name.boundary.rawValue == "boundary")
        #expect(RFC_2045.Parameter.Name.name.rawValue == "name")
    }

    @Test
    func `parameter names order case-insensitively`() throws {
        #expect(try RFC_2045.Parameter.Name("Boundary") < RFC_2045.Parameter.Name("charset"))
    }

    @Test
    func `an empty parameter name is refused`() {
        #expect(throws: RFC_2045.Parameter.Name.Error.empty) {
            try RFC_2045.Parameter.Name("")
        }
    }

    @Test
    func `a parameter name containing a tspecial is refused`() {
        #expect(throws: RFC_2045.Parameter.Name.Error.self) {
            try RFC_2045.Parameter.Name("char;set")
        }
    }

    @Test
    func `a parameter name containing a space is refused`() {
        #expect(throws: RFC_2045.Parameter.Name.Error.self) {
            try RFC_2045.Parameter.Name("char set")
        }
    }

    @Test
    func `a parameter name outside ASCII is refused`() {
        #expect(throws: RFC_2045.Parameter.Name.Error.nonASCII("charsét")) {
            try RFC_2045.Parameter.Name("charsét")
        }
    }
}
