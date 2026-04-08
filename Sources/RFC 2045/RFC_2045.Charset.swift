//
//  RFC_2045.Charset.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import ASCII_Serializer_Primitives
public import INCITS_4_1986

extension RFC_2045 {
    /// Character set identifier for MIME content
    ///
    /// Represents character encodings used in MIME content types.
    /// Defined in RFC 2045 Section 5.1 as part of Content-Type parameters.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let utf8 = RFC_2045.Charset.utf8
    /// let custom = try RFC_2045.Charset("ISO-8859-1")
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 5.1:
    ///
    /// > The "charset" parameter specifies the character set used to
    /// > encode the data in the body part.
    ///
    /// ## Common Character Sets
    ///
    /// The most commonly used character sets are available as static properties:
    /// - `utf8`: UTF-8 encoding (recommended for most use cases)
    /// - `usASCII`: US-ASCII encoding
    /// - `iso88591`: ISO-8859-1 (Latin-1) encoding
    ///
    /// Custom character sets can be created using the string-based initializer.
    public struct Charset: Sendable, Codable {
        /// The IANA charset identifier (stored uppercased)
        public let rawValue: String

        /// Creates a Charset WITHOUT validation
        ///
        /// **Warning**: Bypasses all RFC validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to indicate unchecked initialization
        ///   - rawValue: IANA charset identifier (should be uppercased)
        init(
            __unchecked: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }

        /// Creates a charset with the given identifier
        ///
        /// - Parameter rawValue: IANA charset identifier (case-insensitive)
        public init(_ rawValue: String) {
            // Charset identifiers are case-insensitive per RFC 2045
            self.rawValue = rawValue.uppercased()
        }
    }
}

// MARK: - Hashable

extension RFC_2045.Charset: Hashable {
    /// Hash value (case-insensitive)
    ///
    /// Charset identifiers are case-insensitive per RFC 2045.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.uppercased())
    }

    /// Equality comparison (case-insensitive)
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.uppercased() == rhs.rawValue.uppercased()
    }

    /// Equality comparison with raw value (case-insensitive)
    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue.uppercased() == rhs.uppercased()
    }
}

/// Equality comparison with optional charset and raw value (case-insensitive)
public func == (lhs: RFC_2045.Charset?, rhs: String) -> Bool {
    guard let lhs = lhs else { return false }
    return lhs.rawValue.uppercased() == rhs.uppercased()
}

// MARK: - Serializable

extension RFC_2045.Charset: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii charset: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: charset.rawValue.utf8)
    }

    /// Parses a charset identifier from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// Charset identifiers are ASCII-only.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2045.Charset (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → Charset
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("UTF-8".utf8)
    /// let charset = try RFC_2045.Charset(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the charset identifier
    /// - Throws: `RFC_2045.Charset.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // Validate all bytes are printable ASCII
        for byte in bytes {
            guard byte.ascii.isVisible || byte == .ascii.hyphen else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "Charset identifiers must contain only printable ASCII characters"
                )
            }
        }

        let rawValue = String(decoding: bytes, as: UTF8.self).uppercased()
        self.init(__unchecked: (), rawValue: rawValue)
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 2045 Charset
    ///
    /// This is the canonical serialization of charset identifiers to bytes.
    /// Charset identifiers are ASCII-only by definition.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_2045.Charset (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// Charset → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let charset = RFC_2045.Charset.utf8
    /// let bytes = [UInt8](charset)
    /// // bytes represents "UTF-8" as ASCII bytes
    /// ```
    ///
    /// - Parameter charset: The charset to serialize
    public init(_ charset: RFC_2045.Charset) {
        self = Array(charset.rawValue.utf8)
    }
}

// MARK: - Protocol Conformances

extension RFC_2045.Charset: Binary.ASCII.RawRepresentable {}
extension RFC_2045.Charset: CustomStringConvertible {}

// MARK: - Common Charsets

extension RFC_2045.Charset {
    /// UTF-8 character encoding (recommended)
    public static let utf8 = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-8")

    /// US-ASCII character encoding (7-bit)
    public static let usASCII = RFC_2045.Charset(__unchecked: (), rawValue: "US-ASCII")

    /// ISO-8859-1 (Latin-1) character encoding
    public static let iso88591 = RFC_2045.Charset(__unchecked: (), rawValue: "ISO-8859-1")

    /// UTF-16 character encoding
    public static let utf16 = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-16")

    /// UTF-16BE (Big Endian) character encoding
    public static let utf16BE = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-16BE")

    /// UTF-16LE (Little Endian) character encoding
    public static let utf16LE = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-16LE")

    /// UTF-32 character encoding
    public static let utf32 = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-32")

    /// ISO-8859-2 (Latin-2) character encoding
    public static let iso88592 = RFC_2045.Charset(__unchecked: (), rawValue: "ISO-8859-2")

    /// ISO-8859-15 (Latin-9) character encoding
    public static let iso885915 = RFC_2045.Charset(__unchecked: (), rawValue: "ISO-8859-15")

    /// Windows-1252 (Western European) character encoding
    public static let windows1252 = RFC_2045.Charset(__unchecked: (), rawValue: "WINDOWS-1252")
}
