//
//  RFC_2045.ContentTransferEncoding.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import ASCII_Serializer_Primitives
public import INCITS_4_1986

extension RFC_2045 {
    /// MIME Content-Transfer-Encoding header
    ///
    /// Specifies the encoding transformation that was applied to the body
    /// to make it suitable for transport over the internet.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let encoding = RFC_2045.ContentTransferEncoding.base64
    /// print(encoding.headerValue) // "base64"
    ///
    /// // Parse from string
    /// let parsed = try RFC_2045.ContentTransferEncoding("quoted-printable")
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 6:
    ///
    /// > The Content-Transfer-Encoding field's value is a single token
    /// > specifying the type of encoding, as enumerated below.
    public enum ContentTransferEncoding: String, Hashable, Sendable, Codable {
        /// 7-bit ASCII (default)
        ///
        /// No encoding. Data must be 7-bit ASCII with lines no longer than 998 characters.
        case sevenBit = "7bit"

        /// 8-bit data
        ///
        /// No encoding. Data may contain 8-bit bytes but lines must be no longer
        /// than 998 characters.
        case eightBit = "8bit"

        /// Binary data
        ///
        /// No encoding. Data may contain arbitrary binary data with no line
        /// length restrictions.
        case binary = "binary"

        /// Quoted-printable encoding
        ///
        /// Encodes data using printable ASCII characters. Suitable for text
        /// that is mostly ASCII with occasional non-ASCII characters.
        case quotedPrintable = "quoted-printable"

        /// Base64 encoding
        ///
        /// Encodes arbitrary binary data into printable ASCII. Most common
        /// encoding for attachments and non-text content.
        case base64 = "base64"

        /// Returns true if this encoding is binary-safe
        ///
        /// Binary-safe encodings (base64, quoted-printable) can represent
        /// arbitrary binary data. Non-binary-safe encodings have restrictions.
        public var isBinarySafe: Bool {
            switch self {
            case .base64, .quotedPrintable:
                return true
            case .sevenBit, .eightBit, .binary:
                return false
            }
        }

        /// Returns true if this encoding requires special handling
        ///
        /// Encoded content (base64, quoted-printable) must be decoded before use.
        public var isEncoded: Bool {
            switch self {
            case .base64, .quotedPrintable:
                return true
            case .sevenBit, .eightBit, .binary:
                return false
            }
        }
    }
}

extension [Byte] {
    public init(
        _ contentTransferEncoding: RFC_2045.ContentTransferEncoding.Type
    ) {
        self = Array<Byte>("Content-Transfer-Encoding".utf8)
    }
}

// MARK: - Serializable

extension RFC_2045.ContentTransferEncoding: Binary.ASCII.Serializable {
    public static func serialize<Buffer>(
        ascii encoding: RFC_2045.ContentTransferEncoding,
        into buffer: inout Buffer
    ) where Buffer: RangeReplaceableCollection, Buffer.Element == Byte {
        buffer.append(contentsOf: Array<Byte>(encoding.rawValue.utf8))
    }

    /// Parses a Content-Transfer-Encoding header from canonical byte representation
    ///
    /// - Parameter bytes: The ASCII byte representation of the header value
    /// - Throws: `RFC_2045.ContentTransferEncoding.Error` if the encoding is not recognized
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == Byte {
        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly. Trimming and lowercasing run
        // in the ASCII.Code domain — token comparison against ASCII.Code
        // letter constants stays exact-match.
        let codes: [ASCII.Code]
        do {
            codes = try Array<ASCII.Code>(bytes)
        } catch {
            throw Error.nonASCII(String(decoding: bytes, as: UTF8.self))
        }

        // Trim linear whitespace (LWSP per RFC 822): SPACE and HTAB
        var trimStart = codes.startIndex
        var trimEnd = codes.endIndex
        while trimStart < trimEnd,
            codes[trimStart] == ASCII.Code.space || codes[trimStart] == ASCII.Code.htab
        {
            trimStart += 1
        }
        while trimEnd > trimStart,
            codes[trimEnd - 1] == ASCII.Code.space || codes[trimEnd - 1] == ASCII.Code.htab
        {
            trimEnd -= 1
        }
        let trimmed = codes[trimStart..<trimEnd]

        guard !trimmed.isEmpty else {
            throw Error.empty
        }

        // Normalize to lowercase in ASCII.Code domain (ASCII letters only)
        let normalized: [ASCII.Code] = trimmed.map { $0.lowercased() }

        // Match code sequences directly (zero String allocation)
        switch normalized.count {
        case 4 where normalized == .`7bit`:
            self = .sevenBit
        case 4 where normalized == .`8bit`:
            self = .eightBit
        case 6 where normalized == .base64:
            self = .base64
        case 6 where normalized == .binary:
            self = .binary
        case 16 where normalized == .quotedPrintable:
            self = .quotedPrintable
        default:
            throw Error.unrecognizedEncoding(String(decoding: bytes, as: UTF8.self))
        }
    }
}

// File-scope alias resolves `ASCII.Code` correctly: INCITS's `[ASCII.Code].ASCII`
// namespace shadows bare `ASCII` inside the `extension [ASCII.Code]` below, so the
// constants reference this alias (resolved here, outside the shadowed scope).
private typealias Code = ASCII.Code

extension [ASCII.Code] {
    // ASCII.Code token constants for normalized-buffer comparison.
    // Constants live in the ASCII.Code domain to match the parser body after
    // the Binary.ASCII.Serializable retyping to Buffer.Element == Byte.
    static let `7bit`: Self = [Code.`7`, Code.b, Code.i, Code.t]
    static let `8bit`: Self = [Code.`8`, Code.b, Code.i, Code.t]
    static let base64: Self = [
        Code.b, Code.a, Code.s, Code.e, Code.`6`, Code.`4`,
    ]
    static let binary: Self = [
        Code.b, Code.i, Code.n, Code.a, Code.r, Code.y,
    ]
    static let quotedPrintable: Self = [
        Code.q, Code.u, Code.o, Code.t, Code.e, Code.d,
        Code.hyphen,
        Code.p, Code.r, Code.i, Code.n, Code.t,
        Code.a, Code.b, Code.l, Code.e,
    ]
}

// MARK: - Protocol Conformances

// Note: Uses Binary.ASCII.Serializable (not RawRepresentable) to get
// serialize(ascii:) default that uses native enum rawValue

extension RFC_2045.ContentTransferEncoding: CustomStringConvertible {}
extension RFC_2045.ContentTransferEncoding: RawRepresentable {}
