import Byte
import RFC_2045
import Testing

@Suite
struct `RFC_2045.ContentType Tests` {

    @Test
    func `a content type is built from a type and a subtype`() throws {
        let contentType = try RFC_2045.ContentType(type: "text", subtype: "plain")
        #expect(contentType.type == "text")
        #expect(contentType.subtype == "plain")
        #expect(contentType.parameters.isEmpty)
    }

    @Test
    func `a content type carries its parameters`() throws {
        let contentType = try RFC_2045.ContentType(
            type: "text",
            subtype: "plain",
            parameters: [.charset: RFC_2045.Charset.utf8.rawValue]
        )
        #expect(contentType.charset == RFC_2045.Charset.utf8)
        #expect(contentType == RFC_2045.ContentType.textPlainUTF8)
    }

    @Test
    func `a multipart content type carries its boundary`() {
        let contentType = RFC_2045.ContentType.multipartMixed(boundary: "----boundary42")
        #expect(contentType.isMultipart)
        #expect(contentType.boundary == "----boundary42")
    }

    @Test
    func `type and subtype are normalised to lower case`() throws {
        let contentType = try RFC_2045.ContentType(type: "TEXT", subtype: "HTML")
        #expect(contentType.type == "text")
        #expect(contentType.subtype == "html")
        #expect(contentType == RFC_2045.ContentType.textHTML)
    }

    @Test
    func `content types compare case-insensitively in type and subtype`() throws {
        #expect(
            try RFC_2045.ContentType(type: "Text", subtype: "Plain")
                == RFC_2045.ContentType(type: "text", subtype: "plain")
        )
    }

    @Test
    func `the text content types classify as text`() {
        #expect(RFC_2045.ContentType.textPlain.isText)
        #expect(RFC_2045.ContentType.textHTML.isText)
        #expect(!RFC_2045.ContentType.applicationJSON.isText)
    }

    @Test
    func `the standard content types spell their registered media types`() {
        #expect(RFC_2045.ContentType.textPlain.subtype == "plain")
        #expect(RFC_2045.ContentType.textHTML.subtype == "html")
        #expect(RFC_2045.ContentType.applicationJSON.type == "application")
        #expect(RFC_2045.ContentType.applicationJSON.subtype == "json")
        #expect(RFC_2045.ContentType.applicationOctetStream.subtype == "octet-stream")
        #expect(RFC_2045.ContentType.imageSVG.subtype == "svg+xml")
        #expect(
            RFC_2045.ContentType.applicationXWWWFormURLEncoded.subtype
                == "x-www-form-urlencoded"
        )
    }

    @Test
    func `a named attachment content type carries the name parameter`() {
        let contentType = RFC_2045.ContentType.applicationPDF(name: "invoice.pdf")
        #expect(contentType.parameters[.name] == "invoice.pdf")
    }

    @Test
    func `an empty type is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.emptyType("")) {
            try RFC_2045.ContentType(type: "", subtype: "plain")
        }
    }

    @Test
    func `an empty subtype is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.emptySubtype("")) {
            try RFC_2045.ContentType(type: "text", subtype: "")
        }
    }

    @Test
    func `a subtype containing a separator is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.self) {
            try RFC_2045.ContentType(type: "text", subtype: "plain/other")
        }
    }

    @Test
    func `a type outside ASCII is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.nonASCII("téxt")) {
            try RFC_2045.ContentType(type: "téxt", subtype: "plain")
        }
    }

    @Test
    func `a content type reads from its text form`() throws {
        let contentType = try RFC_2045.ContentType("text/html; charset=UTF-8")
        #expect(contentType.type == "text")
        #expect(contentType.subtype == "html")
        #expect(contentType.charset == RFC_2045.Charset.utf8)
        #expect(contentType == RFC_2045.ContentType.textHTMLUTF8)
    }

    @Test
    func `a content type reads from ASCII bytes`() throws {
        let contentType = try RFC_2045.ContentType(ascii: [Byte](utf8: "image/png"))
        #expect(contentType == RFC_2045.ContentType.imagePNG)
    }

    @Test
    func `the text form is case-insensitive in type and subtype and ignores surrounding whitespace`() throws {
        #expect(try RFC_2045.ContentType("TEXT/PLAIN").type == "text")
        #expect(try RFC_2045.ContentType("  text / plain  ").subtype == "plain")
    }

    @Test
    func `the text form reads a quoted parameter value and unescapes its quoted pairs`() throws {
        let contentType = try RFC_2045.ContentType(#"multipart/mixed; boundary="----=_Part "1234"""#)
        #expect(contentType.isMultipart)
        #expect(contentType.boundary == #"----=_Part "1234""#)
    }

    @Test
    func `the text form keeps a semicolon inside a quoted parameter value`() throws {
        let contentType = try RFC_2045.ContentType(#"text/plain; name="a;b"; charset=UTF-8"#)
        #expect(contentType.parameters[.name] == "a;b")
        #expect(contentType.charset == RFC_2045.Charset.utf8)
    }

    @Test
    func `parameter names in the text form match case-insensitively`() throws {
        let contentType = try RFC_2045.ContentType("multipart/mixed; BOUNDARY=abc; Charset=UTF-8")
        #expect(contentType.boundary == "abc")
        #expect(contentType.parameters[.charset] == "UTF-8")
    }

    @Test
    func `a trailing semicolon in the text form is tolerated`() throws {
        let contentType = try RFC_2045.ContentType("text/plain; charset=UTF-8;")
        #expect(contentType.charset == RFC_2045.Charset.utf8)
    }

    @Test
    func `an empty text form is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.empty) {
            try RFC_2045.ContentType("")
        }
    }

    @Test
    func `a text form without a solidus is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.missingSeparator("text")) {
            try RFC_2045.ContentType("text")
        }
    }

    @Test
    func `a text form with an empty subtype is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.emptySubtype("text/")) {
            try RFC_2045.ContentType("text/")
        }
    }

    @Test
    func `a text form with a parameter that has no value is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.self) {
            try RFC_2045.ContentType("text/plain; charset")
        }
    }

    @Test
    func `a text form with a parameter name containing a tspecial is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.self) {
            try RFC_2045.ContentType("text/plain; char@set=UTF-8")
        }
    }

    @Test
    func `a text form outside ASCII is refused`() {
        #expect(throws: RFC_2045.ContentType.Error.nonASCII("téxt/plain")) {
            try RFC_2045.ContentType("téxt/plain")
        }
    }
}
