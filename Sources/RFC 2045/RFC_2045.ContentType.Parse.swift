public import Parser_Primitives

extension RFC_2045.ContentType {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_2045.ContentType.Parse {
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

    public typealias Error = __MIMEContentTypeParserError
}

extension RFC_2045.ContentType.Parse: Parser.`Protocol` {
    public typealias Failure = __MIMEContentTypeParserError

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {

        let type: Input
        do throws(__MIMETokenParserError) {
            type = try RFC_2045.Parse.Token<Input>().parse(&input)
        } catch {
            throw .expectedToken
        }

        guard input.startIndex < input.endIndex,
            input[input.startIndex] == 0x2F
        else {
            throw .expectedSolidus
        }
        input = input[input.index(after: input.startIndex)...]

        let subtype: Input
        do throws(__MIMETokenParserError) {
            subtype = try RFC_2045.Parse.Token<Input>().parse(&input)
        } catch {
            throw .expectedToken
        }

        var parameters: [Parameter] = []

        while input.startIndex < input.endIndex {

            Self._skipOWS(&input)

            guard input.startIndex < input.endIndex,
                input[input.startIndex] == 0x3B
            else {
                break
            }
            input = input[input.index(after: input.startIndex)...]

            Self._skipOWS(&input)

            let name: Input
            do throws(__MIMETokenParserError) {
                name = try RFC_2045.Parse.Token<Input>().parse(&input)
            } catch {
                break
            }

            guard input.startIndex < input.endIndex,
                input[input.startIndex] == 0x3D
            else {
                break
            }
            input = input[input.index(after: input.startIndex)...]

            let value: Input
            if input.startIndex < input.endIndex && input[input.startIndex] == 0x22 {
                do throws(__MIMEQuotedStringParserError) {
                    value = try RFC_2045.Parse.QuotedString<Input>().parse(&input)
                } catch {
                    break
                }
            } else {
                do throws(__MIMETokenParserError) {
                    value = try RFC_2045.Parse.Token<Input>().parse(&input)
                } catch {
                    break
                }
            }

            parameters.append(Parameter(name: name, value: value))
        }

        return Output(type: type, subtype: subtype, parameters: parameters)
    }

    @inlinable
    package static func _skipOWS(_ input: inout Input) {
        while input.startIndex < input.endIndex {
            let byte = input[input.startIndex]
            guard byte == 0x20 || byte == 0x09 else { break }
            input = input[input.index(after: input.startIndex)...]
        }
    }
}
