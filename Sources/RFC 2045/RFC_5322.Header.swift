public import RFC_5322

extension RFC_5322.Header {

    public init(_ contentType: RFC_2045.ContentType) throws(Value.Error) {
        try self.init(name: .contentType, value: .init(contentType))
    }

    public init(_ encoding: RFC_2045.ContentTransferEncoding) throws(Value.Error) {
        try self.init(name: .contentTransferEncoding, value: .init(encoding))
    }
}
