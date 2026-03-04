//
//  RFC_2045.Parse.ContentType.swift
//  swift-rfc-2045
//
//  MIME Content-Type: type "/" subtype *(";" parameter)
//

public import Parser_Primitives

extension RFC_2045.Parse {
    /// Parses a MIME Content-Type header per RFC 2045 Section 5.1.
    ///
    /// `content = type "/" subtype *(";" OWS parameter)`
    ///
    /// Where `parameter = token "=" (token / quoted-string)`
    ///
    /// Returns the type, subtype, and parameters as raw byte slices.
    public struct ContentType<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_2045.Parse.ContentType {
    public struct Parameter: Sendable {
        public let name: Input
        public let value: Input

        @inlinable
        public init(name: Input, value: Input) {
            self.name = name
            self.value = value
        }
    }

    public struct Output: Sendable {
        public let type: Input
        public let subtype: Input
        public let parameters: [Parameter]

        @inlinable
        public init(type: Input, subtype: Input, parameters: [Parameter]) {
            self.type = type
            self.subtype = subtype
            self.parameters = parameters
        }
    }

    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedToken
        case expectedSolidus
    }
}

extension RFC_2045.Parse.ContentType: Parser.`Protocol` {
    public typealias ParseOutput = Output
    public typealias Failure = RFC_2045.Parse.ContentType<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        // Parse type token
        let type: Input
        do {
            type = try RFC_2045.Parse.Token<Input>().parse(&input)
        } catch {
            throw .expectedToken
        }

        // Expect '/' (0x2F)
        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x2F
        else {
            throw .expectedSolidus
        }
        input = input[input.index(after: input.startIndex)...]

        // Parse subtype token
        let subtype: Input
        do {
            subtype = try RFC_2045.Parse.Token<Input>().parse(&input)
        } catch {
            throw .expectedToken
        }

        // Parse optional parameters: *(";" OWS token "=" (token / quoted-string))
        var parameters: [Parameter] = []

        while input.startIndex < input.endIndex {
            // Skip OWS
            Self._skipOWS(&input)

            // Expect ';'
            guard input.startIndex < input.endIndex,
                input[input.startIndex] == 0x3B
            else {
                break
            }
            input = input[input.index(after: input.startIndex)...]

            // Skip OWS
            Self._skipOWS(&input)

            // Parse parameter name (token)
            guard let name = try? RFC_2045.Parse.Token<Input>().parse(&input) else {
                break
            }

            // Expect '='
            guard input.startIndex < input.endIndex,
                input[input.startIndex] == 0x3D
            else {
                break
            }
            input = input[input.index(after: input.startIndex)...]

            // Parse value (token or quoted-string)
            let value: Input
            if input.startIndex < input.endIndex && input[input.startIndex] == 0x22 {
                guard let qs = try? RFC_2045.Parse.QuotedString<Input>().parse(&input) else {
                    break
                }
                value = qs
            } else {
                guard let tok = try? RFC_2045.Parse.Token<Input>().parse(&input) else {
                    break
                }
                value = tok
            }

            parameters.append(Parameter(name: name, value: value))
        }

        return Output(type: type, subtype: subtype, parameters: parameters)
    }

    @inlinable
    static func _skipOWS(_ input: inout Input) {
        while input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            guard byte == 0x20 || byte == 0x09 else { break }
            input = input[input.index(after: input.startIndex)...]
        }
    }
}
