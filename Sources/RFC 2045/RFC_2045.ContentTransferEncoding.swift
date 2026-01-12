//
//  RFC_2045.ContentTransferEncoding.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import ASCII

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

extension [UInt8] {
    public init(
        _ contentTransferEncoding: RFC_2045.ContentTransferEncoding.Type
    ) {
        self = Array("Content-Transfer-Encoding".utf8)
    }
}

// MARK: - Serializable

extension RFC_2045.ContentTransferEncoding: Binary.ASCII.Serializable {
    static public func serialize<Buffer>(
        _ encoding: RFC_2045.ContentTransferEncoding,
        into buffer: inout Buffer
    ) where Buffer: RangeReplaceableCollection, Buffer.Element == UInt8 {
        buffer.append(contentsOf: Array(encoding.rawValue.utf8))
    }

    public static func serialize<Buffer>(
        ascii encoding: RFC_2045.ContentTransferEncoding,
        into buffer: inout Buffer
    ) where Buffer: RangeReplaceableCollection, Buffer.Element == UInt8 {
        buffer.append(contentsOf: Array(encoding.rawValue.utf8))
    }

    /// Parses a Content-Transfer-Encoding header from canonical byte representation
    ///
    /// - Parameter bytes: The ASCII byte representation of the header value
    /// - Throws: `RFC_2045.ContentTransferEncoding.Error` if the encoding is not recognized
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        // Trim linear whitespace (LWSP per RFC 822) and normalize to lowercase
        let trimmed = bytes.ascii.trimming([.ascii.space, .ascii.htab])

        guard !trimmed.isEmpty else {
            throw Error.empty
        }

        let normalized = trimmed.ascii.lowercased()

        // Match byte sequences directly (zero String allocation)
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

extension [UInt8] {
    static let `7bit`: Self = [.ascii.`7`, .ascii.b, .ascii.i, .ascii.t]
    static let `8bit`: Self = [.ascii.`8`, .ascii.b, .ascii.i, .ascii.t]
    static let base64: Self = [.ascii.b, .ascii.a, .ascii.s, .ascii.e, .ascii.`6`, .ascii.`4`]
    static let binary: Self = [.ascii.b, .ascii.i, .ascii.n, .ascii.a, .ascii.r, .ascii.y]
    static let quotedPrintable: Self = [
        .ascii.q, .ascii.u, .ascii.o, .ascii.t, .ascii.e, .ascii.d, .ascii.hyphen,
        .ascii.p, .ascii.r, .ascii.i, .ascii.n, .ascii.t, .ascii.a, .ascii.b, .ascii.l, .ascii.e,
    ]
}

// MARK: - Protocol Conformances

// Note: Uses Binary.ASCII.Serializable (not RawRepresentable) to get
// serialize(ascii:) default that uses native enum rawValue

extension RFC_2045.ContentTransferEncoding: CustomStringConvertible {}
extension RFC_2045.ContentTransferEncoding: RawRepresentable {}
