//
//  RFC_2045.Parameter.Name.Error.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 25/11/2025.
//

public import ASCII_Serializer_Primitives

extension RFC_2045.Parameter.Name {
    /// Parameter.Name-specific error type for typed throws
    ///
    /// Used when parsing parameter names from byte or string representations.
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 5.1:
    ///
    /// > parameter := attribute "=" value
    /// > attribute := token
    /// > token := 1*<any (US-ASCII) CHAR except SPACE, CTLs, or tspecials>
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Parameter name is empty
        case empty

        /// Invalid character in parameter name
        ///
        /// Parameter names (tokens) must not contain spaces, control characters,
        /// or tspecials: ()<>@,;:\"/[]?=
        ///
        /// - Parameters:
        ///   - input: The original input string
        ///   - byte: The invalid ASCII code encountered
        ///   - reason: Description of why the character is invalid
        case invalidCharacter(String, byte: ASCII.Code, reason: String)
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
        }
    }
}
