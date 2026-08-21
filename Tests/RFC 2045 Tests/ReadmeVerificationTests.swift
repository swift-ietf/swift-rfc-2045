import Testing

@testable import RFC_2045

@Suite
struct `README Verification` {

    @Test
    func `Example from README: Content-Type Examples`() throws {

        let plain = RFC_2045.ContentType.textPlain
        #expect(plain.type == "text")
        #expect(plain.subtype == "plain")

        let html = try RFC_2045.ContentType("text/html; charset=UTF-8")
        #expect(html.headerValue == "text/html; charset=UTF-8")

        let multipart = RFC_2045.ContentType.multipartAlternative(boundary: "----=_Part_1234")
        #expect(multipart.isMultipart == true)
        #expect(multipart.boundary == "----=_Part_1234")

        let headers = [
            "Content-Type": html.headerValue
        ]
        #expect(headers["Content-Type"] == "text/html; charset=UTF-8")
    }

    @Test
    func `Example from README: Content-Transfer-Encoding`() throws {

        let base64 = RFC_2045.ContentTransferEncoding.base64
        _ = RFC_2045.ContentTransferEncoding.quotedPrintable
        _ = RFC_2045.ContentTransferEncoding.sevenBit

        let headers = [
            "Content-Transfer-Encoding": base64.description
        ]
        #expect(headers["Content-Transfer-Encoding"] == "base64")

        #expect(base64.isBinarySafe == true)
        #expect(base64.isEncoded == true)
    }

    @Test
    func `Example from README: Common Content Types`() {

        let textPlain = RFC_2045.ContentType.textPlain
        #expect(textPlain.headerValue == "text/plain")

        let textPlainUTF8 = RFC_2045.ContentType.textPlainUTF8
        #expect(textPlainUTF8.charset == "UTF-8")

        let textHTML = RFC_2045.ContentType.textHTML
        #expect(textHTML.headerValue == "text/html")

        let textHTMLUTF8 = RFC_2045.ContentType.textHTMLUTF8
        #expect(textHTMLUTF8.headerValue == "text/html; charset=UTF-8")

        let alternative = RFC_2045.ContentType.multipartAlternative(boundary: "----=_Part_1234")
        #expect(alternative.isMultipart == true)

        let mixed = RFC_2045.ContentType.multipartMixed(boundary: "----=_Part_5678")
        #expect(mixed.boundary == "----=_Part_5678")
    }

    @Test
    func `Example from README: Parsing Headers`() throws {

        let contentType = try RFC_2045.ContentType("text/html; charset=UTF-8")

        #expect(contentType.type == "text")
        #expect(contentType.subtype == "html")
        #expect(contentType.charset == "UTF-8")

        let encoding = try RFC_2045.ContentTransferEncoding("base64")
        #expect(encoding.description == "base64")
    }

    @Test
    func `Typed throws error handling`() {

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
                break

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
                break

            default:
                Issue.record("Expected unrecognizedEncoding error")
            }
        }
    }
}
