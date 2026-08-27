public import Parser

extension RFC_2045.Parse {

    public struct Token<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_2045.Parse.Token {

    public typealias Error = __MIMETokenParserError
}

extension RFC_2045.Parse.Token: Parser.`Protocol` {
    public typealias Output = Input
    public typealias Failure = __MIMETokenParserError

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

    @inlinable
    package static func _isTokenChar(_ byte: UInt8) -> Bool {
        RFC_2045.Parse._isTokenChar(byte)
    }
}

extension RFC_2045.Parse {

    @inlinable
    package static func _isTokenChar(_ byte: UInt8) -> Bool {
        guard byte >= 0x21 && byte <= 0x7E else { return false }
        return switch byte {
        case 0x28, 0x29: false
        case 0x3C, 0x3E: false
        case 0x40: false
        case 0x2C: false
        case 0x3B: false
        case 0x3A: false
        case 0x5C: false
        case 0x22: false
        case 0x2F: false
        case 0x5B, 0x5D: false
        case 0x3F: false
        case 0x3D: false
        default: true
        }
    }
}
