//
//  RFC_2045.ContentType.Error.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 25/11/2025.
//

public import ASCII_Serializer_Primitives

extension RFC_2045.ContentType {
    /// ContentType-specific error type for typed throws
    ///
    /// Used when parsing Content-Type headers from byte or string representations.
    /// All error cases include the original input for diagnostic purposes.
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 5.1:
    ///
    /// > In the Augmented BNF notation of RFC 822, a Content-Type header field
    /// > value is defined as follows:
    /// >
    /// > content := "Content-Type" ":" type "/" subtype
    /// >            *(";" parameter)
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Content-Type input is empty
        case empty

        /// Missing solidus separator between type and subtype
        ///
        /// RFC 2045 requires format: `type "/" subtype`
        case missingSeparator(String)

        /// Type component is empty
        ///
        /// The type (before solidus) cannot be empty.
        case emptyType(String)

        /// Subtype component is empty
        ///
        /// The subtype (after solidus) cannot be empty.
        case emptySubtype(String)

        /// Invalid character encountered in type or subtype
        ///
        /// - Parameters:
        ///   - input: The original input string
        ///   - byte: The invalid ASCII code encountered
        ///   - reason: Description of why the character is invalid
        case invalidCharacter(String, byte: ASCII.Code, reason: String)

        /// Invalid parameter format
        ///
        /// - Parameters:
        ///   - input: The original input string
        ///   - reason: Description of the parameter error
        case invalidParameter(String, reason: String)

        /// Input contains a non-ASCII byte (RFC 2045 Content-Types are ASCII-only)
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
