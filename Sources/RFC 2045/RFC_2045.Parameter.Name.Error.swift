public import ASCII_Serializer_Primitives

extension RFC_2045.Parameter.Name {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case invalidCharacter(String, byte: ASCII.Code, reason: String)

        case nonASCII(String)
    }
}

extension RFC_2045.Parameter.Name.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Parameter name cannot be empty"

        case .invalidCharacter(let value, let byte, let reason):
            return
                "Invalid byte 0x\(String(byte, radix: 16).uppercased()) in '\(value)': \(reason)"

        case .nonASCII(let value):
            return "Non-ASCII byte in '\(value)'"
        }
    }
}
