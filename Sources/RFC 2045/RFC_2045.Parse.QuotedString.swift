//
//  RFC_2045.Parse.QuotedString.swift
//  swift-rfc-2045
//
//  MIME quoted-string: DQUOTE *(qtext / quoted-pair) DQUOTE
//

public import Parser_Primitives

extension RFC_2045.Parse {
    /// Parses a MIME quoted-string per RFC 2045 / RFC 822.
    ///
    /// `quoted-string = DQUOTE *(qtext / quoted-pair) DQUOTE`
    ///
    /// Returns the raw byte slice INCLUDING the surrounding quotes.
    /// Unescaping is left to the caller.
    public struct QuotedString<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_2045.Parse.QuotedString {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedQuote
        case unterminatedString
    }
}

extension RFC_2045.Parse.QuotedString: Parser.`Protocol` {
    public typealias ParseOutput = Input
    public typealias Failure = RFC_2045.Parse.QuotedString<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Input {
        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x22  // "
        else {
            throw .expectedQuote
        }

        var index = input.index(after: input.startIndex)
        var escaped = false

        while index < input.endIndex {
            let byte = input[index]
            if escaped {
                escaped = false
            } else if byte == 0x5C {  // backslash
                escaped = true
            } else if byte == 0x22 {  // closing "
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
