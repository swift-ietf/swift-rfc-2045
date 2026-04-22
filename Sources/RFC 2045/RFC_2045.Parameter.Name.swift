//
//  RFC_2045.Parameter.Name.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import ASCII_Serializer_Primitives
public import INCITS_4_1986
public import Format_Primitives

extension RFC_2045.Parameter {
    /// Type-safe MIME parameter name with case-insensitive comparison.
    ///
    /// RFC 2045 Section 5.1 states:
    /// > Both attribute and value are case-insensitive
    ///
    /// This type ensures consistent handling of parameter names across all MIME headers
    /// (Content-Type, Content-Disposition, etc.).
    ///
    /// ## Example
    ///
    /// ```swift
    /// let charset: RFC_2045.Parameter.Name = .charset
    /// let custom = try RFC_2045.Parameter.Name("Custom-Param")
    ///
    /// // Case-insensitive comparison
    /// charset == RFC_2045.Parameter.Name(rawValue: "CHARSET") // true
    /// ```
    public struct Name: Sendable, Codable {
        /// The case-insensitive parameter name (internal to avoid protocol rawValue shadowing)
        internal let storage: Format.Case.Insensitive

        /// Creates a Parameter.Name WITHOUT validation
        ///
        /// **Warning**: Bypasses all RFC validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to indicate unchecked initialization
        ///   - rawValue: The parameter name string
        init(
            __unchecked: Void,
            rawValue: String
        ) {
            self.storage = Format.Case.Insensitive(rawValue)
        }

        /// The canonical lowercased parameter name.
        public var rawValue: String {
            storage.value.lowercased()
        }

        /// Creates a parameter name from a raw string value.
        ///
        /// - Parameter rawValue: The parameter name string (case-insensitive).
        public init(rawValue: String) {
            self.storage = Format.Case.Insensitive(rawValue)
        }

        /// Creates a parameter name from a case-insensitive string.
        ///
        /// - Parameter caseInsensitive: The case-insensitive parameter name.
        public init(_ caseInsensitive: Format.Case.Insensitive) {
            self.storage = caseInsensitive
        }
    }
}

// MARK: - Hashable

extension RFC_2045.Parameter.Name: Hashable {
    /// Hash value (case-insensitive)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }

    /// Equality comparison (case-insensitive)
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    /// Equality comparison with raw value (case-insensitive)
    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue.lowercased() == rhs.lowercased()
    }
}

// MARK: - Serializable

extension RFC_2045.Parameter.Name: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii name: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: name.rawValue.utf8)
    }

    /// Parses a parameter name from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// Parameter names are ASCII tokens per RFC 2045.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2045.Parameter.Name (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Parameter.Name
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 5.1:
    /// > token := 1*<any (US-ASCII) CHAR except SPACE, CTLs, or tspecials>
    /// > tspecials := "(" / ")" / "<" / ">" / "@" / "," / ";" / ":" /
    /// >              "\" / <"> / "/" / "[" / "]" / "?" / "="
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("charset".utf8)
    /// let name = try RFC_2045.Parameter.Name(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the parameter name
    /// - Throws: `RFC_2045.Parameter.Name.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // tspecials that are not allowed in tokens
        let tspecials: Set<UInt8> = [
            .ascii.leftParenthesis,  // (
            .ascii.rightParenthesis,  // )
            .ascii.lessThanSign,  // <
            .ascii.greaterThanSign,  // >
            .ascii.atSign,  // @
            .ascii.comma,  // ,
            .ascii.semicolon,  // ;
            .ascii.colon,  // :
            .ascii.backslash,  // \
            .ascii.quotationMark,  // "
            .ascii.solidus,  // /
            .ascii.leftSquareBracket,  // [
            .ascii.rightSquareBracket,  // ]
            .ascii.questionMark,  // ?
            .ascii.equalsSign,  // =
        ]

        // Validate all bytes are valid token characters
        for byte in bytes {
            // Must not be control character or space
            guard byte > 0x20 && byte < 0x7F else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Parameter names must not contain control characters or space"
                )
            }

            // Must not be tspecial
            guard !tspecials.contains(byte) else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Parameter names must not contain tspecials: ()<>@,;:\\\"/[]?="
                )
            }
        }

        let rawValue = String(decoding: bytes, as: UTF8.self)
        self.init(__unchecked: (), rawValue: rawValue)
    }
}

// MARK: - Protocol Conformances

extension RFC_2045.Parameter.Name: RawRepresentable {}
extension RFC_2045.Parameter.Name: CustomStringConvertible {}

extension RFC_2045.Parameter.Name: Comparable {
    public static func < (lhs: RFC_2045.Parameter.Name, rhs: RFC_2045.Parameter.Name) -> Bool {
        lhs.storage < rhs.storage
    }
}

// MARK: - Common Parameter Names

extension RFC_2045.Parameter.Name {
    /// The charset parameter (RFC 2045 Section 4)
    ///
    /// Specifies the character set used in text/* media types.
    ///
    /// Example: `Content-Type: text/plain; charset=UTF-8`
    public static let charset = Self(__unchecked: (), rawValue: "charset")

    /// The boundary parameter (RFC 2045 Section 5.1)
    ///
    /// Specifies the boundary delimiter for multipart/* media types.
    ///
    /// Example: `Content-Type: multipart/mixed; boundary="----=_Part_1234"`
    public static let boundary = Self(__unchecked: (), rawValue: "boundary")

    /// The name parameter (RFC 2045 Section 2.3, deprecated by RFC 2183)
    ///
    /// Specifies a suggested filename. Deprecated in favor of Content-Disposition
    /// filename parameter per RFC 2183.
    ///
    /// Example: `Content-Type: application/pdf; name="document.pdf"`
    @available(*, deprecated, message: "Use Content-Disposition filename parameter per RFC 2183")
    public static let name = Self(__unchecked: (), rawValue: "name")
}
