public import Parser

extension RFC_2045.Parse {

    public struct QuotedString<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_2045.Parse.QuotedString {

    public typealias Error = __MIMEQuotedStringParserError
}

extension RFC_2045.Parse.QuotedString: Parser.`Protocol` {
    public typealias Output = Input
    public typealias Failure = __MIMEQuotedStringParserError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Input {
        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x22
        else {
            throw .expectedQuote
        }

        var index = input.index(after: input.startIndex)
        var escaped = false

        while index < input.endIndex {
            let byte = input[index]
            if escaped {
                escaped = false
            } else if byte == 0x5C {
                escaped = true
            } else if byte == 0x22 {
                input.formIndex(after: &index)
                let result = input[input.startIndex..<index]
                input = input[index...]
                return result
            }
            input.formIndex(after: &index)
        }

        throw .unterminatedString
    }
}
