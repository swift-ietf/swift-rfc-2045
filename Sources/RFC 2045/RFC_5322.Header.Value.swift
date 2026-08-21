public import RFC_5322

extension RFC_5322.Header.Value {

    public init(_ contentType: RFC_2045.ContentType) throws(Error) {
        try self.init(contentType.description)
    }
}

extension RFC_5322.Header.Value {

    public init(_ encoding: RFC_2045.ContentTransferEncoding) throws(Error) {
        try self.init(encoding.description)
    }
}
