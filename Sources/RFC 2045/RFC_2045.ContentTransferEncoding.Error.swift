extension RFC_2045.ContentTransferEncoding {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case unrecognizedEncoding(String)

        case nonASCII(String)
    }
}

extension RFC_2045.ContentTransferEncoding.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Content-Transfer-Encoding cannot be empty"

        case .unrecognizedEncoding(let value):
            return
                "Unrecognized encoding '\(value)' (must be: 7bit, 8bit, binary, quoted-printable, or base64)"

        case .nonASCII(let value):
            return "Non-ASCII byte in '\(value)'"
        }
    }
}
