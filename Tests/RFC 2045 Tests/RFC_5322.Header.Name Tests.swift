import RFC_2045
import RFC_5322
import Testing

@Suite
struct `RFC_5322.Header.Name MIME Tests` {

    @Test
    func `the MIME header names spell their RFC 2045 field names`() {
        #expect(RFC_5322.Header.Name.contentType.rawValue == "Content-Type")
        #expect(RFC_5322.Header.Name.contentTransferEncoding.rawValue
            == "Content-Transfer-Encoding")
        #expect(RFC_5322.Header.Name.mimeVersion.rawValue == "MIME-Version")
        #expect(RFC_5322.Header.Name.contentId.rawValue == "Content-ID")
        #expect(RFC_5322.Header.Name.contentDescription.rawValue == "Content-Description")
    }

    @Test
    func `MIME header names compare case-insensitively`() throws {
        #expect(try RFC_5322.Header.Name("content-type") == .contentType)
    }
}
