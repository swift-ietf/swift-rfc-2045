//
//  RFC_2045.Parse.Token.swift
//  swift-rfc-2045
//
//  MIME token: 1*<any CHAR except SPACE, CTLs, or tspecials>
//

public import Parser_Primitives

extension RFC_2045.Parse {
    /// Parses a MIME token per RFC 2045 Section 5.1.
    ///
    /// `token = 1*<any (US-ASCII) CHAR except SPACE, CTLs, or tspecials>`
    ///
    /// Where tspecials are: `( ) < > @ , ; : \ " / [ ] ? =`
    ///
    /// Returns the raw byte slice.
    public struct Token<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_2045.Parse.Token {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedToken
    }
}

extension RFC_2045.Parse.Token: Parser.`Protocol` {
    public typealias ParseOutput = Input
    public typealias Failure = RFC_2045.Parse.Token<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Input {
        var index = input.startIndex
        guard index < input.endIndex else { throw .expectedToken }

        let first = input[index]
        guard Self._isTokenChar(first) else { throw .expectedToken }
        input.formIndex(after: &index)

        while index < input.endIndex {
            let byte = input[index]
            guard Self._isTokenChar(byte) else { break }
            input.formIndex(after: &index)
        }

        let result = input[input.startIndex..<index]
        input = input[index...]
        return result
    }

    /// Visible ASCII (0x21–0x7E) excluding tspecials.
    @inlinable
    static func _isTokenChar(_ byte: UInt8) -> Bool {
        guard byte >= 0x21 && byte <= 0x7E else { return false }
        return switch byte {
        case 0x28, 0x29: false // ( )
        case 0x3C, 0x3E: false // < >
        case 0x40: false       // @
        case 0x2C: false       // ,
        case 0x3B: false       // ;
        case 0x3A: false       // :
        case 0x5C: false       // \
        case 0x22: false       // "
        case 0x2F: false       // /
        case 0x5B, 0x5D: false // [ ]
        case 0x3F: false       // ?
        case 0x3D: false       // =
        default: true
        }
    }
}
