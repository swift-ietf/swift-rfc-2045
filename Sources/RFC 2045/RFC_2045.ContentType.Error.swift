public import ASCII_Serializer_Primitives

extension RFC_2045.ContentType {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case missingSeparator(String)

        case emptyType(String)

        case emptySubtype(String)

        case invalidCharacter(String, byte: ASCII.Code, reason: String)

        case invalidParameter(String, reason: String)

        case nonASCII(String)
    }
}

extension RFC_2045.ContentType.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Content-Type cannot be empty"

        case .missingSeparator(let value):
            return "Missing '/' separator in '\(value)'"

        case .emptyType(let value):
            return "Type component is empty in '\(value)'"

        case .emptySubtype(let value):
            return "Subtype component is empty in '\(value)'"

        case .invalidCharacter(let value, let byte, let reason):
            return
                "Invalid byte 0x\(String(byte, radix: 16).uppercased()) in '\(value)': \(reason)"

        case .invalidParameter(let value, let reason):
            return "Invalid parameter in '\(value)': \(reason)"

        case .nonASCII(let value):
            return "Non-ASCII byte in '\(value)'"
        }
    }
}
