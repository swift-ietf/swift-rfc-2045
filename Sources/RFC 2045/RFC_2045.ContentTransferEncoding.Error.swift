//
//  RFC_2045.ContentTransferEncoding.Error.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 25/11/2025.
//

extension RFC_2045.ContentTransferEncoding {
    /// ContentTransferEncoding-specific error type for typed throws
    ///
    /// Used when parsing Content-Transfer-Encoding headers from byte or string representations.
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 6.1:
    ///
    /// > The Content-Transfer-Encoding field's value is a single token
    /// > specifying the type of encoding, as enumerated below.
    /// >
    /// > encoding := "Content-Transfer-Encoding" ":" mechanism
    /// > mechanism := "7bit" / "8bit" / "binary" /
    /// >              "quoted-printable" / "base64" /
    /// >              ietf-token / x-token
    public enum Error: Swift.Error, Sendable, Equatable {
        /// Content-Transfer-Encoding input is empty
        case empty

        /// Unrecognized encoding mechanism
        ///
        /// The value does not match any known encoding mechanism.
        /// RFC 2045 defines: 7bit, 8bit, binary, quoted-printable, base64
        case unrecognizedEncoding(String)

        /// Input contains a non-ASCII byte (RFC 2045 encodings are ASCII-only)
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
