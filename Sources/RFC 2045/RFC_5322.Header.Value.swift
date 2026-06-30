//
//  RFC_5322.Header.Value.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 24/11/2025.
//

public import RFC_5322

extension RFC_5322.Header.Value {
    /// Creates a header value from RFC 2045 ContentType
    ///
    /// Uses the canonical string representation of the content type.
    public init(_ contentType: RFC_2045.ContentType) throws(Error) {
        try self.init(contentType.description)
    }
}

extension RFC_5322.Header.Value {
    /// Creates a header value from RFC 2045 ContentTransferEncoding
    ///
    /// Uses the canonical string representation of the encoding.
    public init(_ encoding: RFC_2045.ContentTransferEncoding) throws(Error) {
        try self.init(encoding.description)
    }
}
