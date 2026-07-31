import Testing

@testable import RFC_2045

@Suite
struct `README Verification` {

    @Test
    func `Example from README: Content-Type Examples`() throws {
        // Simple text type using static constant
        let plain = RFC_2045.ContentType.textPlain
        #expect(plain.type == "text")
        #expect(plain.subtype == "plain")

        // Parse from string using Binary.ASCII.Serializable protocol
        let html = try RFC_2045.ContentType("text/html; charset=UTF-8")
        #expect(html.headerValue == "text/html; charset=UTF-8")

        // Multipart with boundary
        let multipart = RFC_2045.ContentType.multipartAlternative(boundary: "----=_Part_1234")
        #expect(multipart.isMultipart == true)
        #expect(multipart.boundary == "----=_Part_1234")

        // Use in email headers
        let headers = [
            "Content-Type": html.headerValue  // "text/html; charset=UTF-8"
        ]
        #expect(headers["Content-Type"] == "text/html; charset=UTF-8")
    }

    @Test
    func `Example from README: Content-Transfer-Encoding`() throws {
        // Common encodings
        let base64 = RFC_2045.ContentTransferEncoding.base64
        _ = RFC_2045.ContentTransferEncoding.quotedPrintable
        _ = RFC_2045.ContentTransferEncoding.sevenBit

        // Use in email headers
        let headers = [
            "Content-Transfer-Encoding": base64.description  // "base64"
        ]
        #expect(headers["Content-Transfer-Encoding"] == "base64")

        // Check encoding properties
        #expect(base64.isBinarySafe == true)
        #expect(base64.isEncoded == true)
    }

    @Test
    func `Example from README: Common Content Types`() {
        // Preset content types
        let textPlain = RFC_2045.ContentType.textPlain
        #expect(textPlain.headerValue == "text/plain")

        let textPlainUTF8 = RFC_2045.ContentType.textPlainUTF8
        #expect(textPlainUTF8.charset == "UTF-8")

        let textHTML = RFC_2045.ContentType.textHTML
        #expect(textHTML.headerValue == "text/html")

        let textHTMLUTF8 = RFC_2045.ContentType.textHTMLUTF8
        #expect(textHTMLUTF8.headerValue == "text/html; charset=UTF-8")

        // Multipart types with boundary
        let alternative = RFC_2045.ContentType.multipartAlternative(boundary: "----=_Part_1234")
        #expect(alternative.isMultipart == true)

        let mixed = RFC_2045.ContentType.multipartMixed(boundary: "----=_Part_5678")
        #expect(mixed.boundary == "----=_Part_5678")
    }

    @Test
    func `Example from README: Parsing Headers`() throws {
        // Parse Content-Type header using Binary.ASCII.Serializable protocol
        let contentType = try RFC_2045.ContentType("text/html; charset=UTF-8")

        #expect(contentType.type == "text")
        #expect(contentType.subtype == "html")
        #expect(contentType.charset == "UTF-8")

        // Parse Content-Transfer-Encoding header using Binary.ASCII.Serializable protocol
        let encoding = try RFC_2045.ContentTransferEncoding("base64")
        #expect(encoding.description == "base64")
    }

    @Test
    func `Typed throws error handling`() {
        // Test that typed throws work correctly
        do throws(RFC_2045.ContentType.Error) {
            _ = try RFC_2045.ContentType("")
        } catch {
            #expect(error == .empty)
        }

        do throws(RFC_2045.ContentType.Error) {
            _ = try RFC_2045.ContentType("invalid")
        } catch {
            switch error {
            case .missingSeparator:
                break  // Expected

            default:
                Issue.record("Expected missingSeparator error")
            }
        }

        do throws(RFC_2045.ContentTransferEncoding.Error) {
            _ = try RFC_2045.ContentTransferEncoding("")
        } catch {
            #expect(error == .empty)
        }

        do throws(RFC_2045.ContentTransferEncoding.Error) {
            _ = try RFC_2045.ContentTransferEncoding("unknown")
        } catch {
            switch error {
            case .unrecognizedEncoding:
                break  // Expected

            default:
                Issue.record("Expected unrecognizedEncoding error")
            }
        }
    }
}
