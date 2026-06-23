//
//  RFC_2045.Charset.Error.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 25/11/2025.
//

public import ASCII_Serializer_Primitives

extension RFC_2045.Charset {
    /// Charset-specific error type for typed throws
    ///
    /// Used when parsing charset parameter values from byte or string representations.
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 5.1:
    ///
    /// > The "charset" parameter is applicable to any "text/*" content type.
    /// > A "charset" parameter may be specified...to indicate the character
    /// > set of the body text for "text/plain" data.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Charset identifier is empty
        case empty

        /// Invalid character in charset identifier
        ///
        /// Charset identifiers should contain only printable ASCII characters.
        ///
        /// - Parameters:
        ///   - input: The original input string
        ///   - byte: The invalid ASCII code encountered
        ///   - reason: Description of why the character is invalid
        case invalidCharacter(String, byte: ASCII.Code, reason: String)

        /// Input contains a non-ASCII byte (RFC 2045 charset identifiers are ASCII-only)
        case nonASCII(String)
    }
}

extension RFC_2045.Charset.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Charset identifier cannot be empty"
        case .invalidCharacter(let value, let byte, let reason):
            return
                "Invalid byte 0x\(String(byte, radix: 16).uppercased()) in '\(value)': \(reason)"
        case .nonASCII(let value):
            return "Non-ASCII byte in '\(value)'"
        }
    }
}
