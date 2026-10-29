#if Coder
    import ASCII
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_2045.ContentType {

        public struct Coder<
            Input: Cursor.`Protocol`<Byte, Never>,
            Buffer: RangeReplaceableCollection<Byte>
        >: Coding {

            public typealias Output = RFC_2045.ContentType

            public typealias Failure = RFC_2045.ContentType.Error

            public init() {}

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {

                let start = input.checkpoint

                Scan.skipWhitespace(&input)

                let typeBytes = Scan.run(&input, while: RFC_2045.Grammar.isTokenCharacter)

                guard !typeBytes.isEmpty else {
                    input.seek(to: start)
                    throw .emptyType("")
                }

                guard Scan.take(&input, ASCII.Code.solidus) else {
                    input.seek(to: start)
                    throw .missingSeparator(String(decoding: typeBytes, as: UTF8.self))
                }

                let subtypeBytes = Scan.run(&input, while: RFC_2045.Grammar.isTokenCharacter)

                guard !subtypeBytes.isEmpty else {
                    input.seek(to: start)
                    throw .emptySubtype(String(decoding: typeBytes, as: UTF8.self))
                }

                var parameters: [RFC_2045.Parameter.Name: String] = [:]

                fields: while true {

                    let mark = input.checkpoint

                    Scan.skipWhitespace(&input)

                    guard Scan.take(&input, ASCII.Code.semicolon) else {
                        input.seek(to: mark)
                        break fields
                    }

                    Scan.skipWhitespace(&input)

                    let nameBytes = Scan.run(&input, while: RFC_2045.Grammar.isTokenCharacter)

                    guard
                        !nameBytes.isEmpty,
                        Scan.take(&input, ASCII.Code.equalsSign)
                    else {
                        input.seek(to: mark)
                        break fields
                    }

                    guard let name = try? RFC_2045.Parameter.Name(ascii: nameBytes) else {
                        input.seek(to: mark)
                        break fields
                    }

                    guard let value = Self.value(&input) else {
                        input.seek(to: mark)
                        break fields
                    }

                    parameters[name] = value
                }

                do throws(Failure) {
                    return try RFC_2045.ContentType(
                        type: String(decoding: typeBytes, as: UTF8.self),
                        subtype: String(decoding: subtypeBytes, as: UTF8.self),
                        parameters: parameters
                    )
                } catch {
                    input.seek(to: start)
                    throw error
                }
            }

            static func value(_ input: inout Input) -> String? {

                guard Scan.take(&input, ASCII.Code.quotationMark) else {
                    let bytes = Scan.run(&input, while: RFC_2045.Grammar.isTokenCharacter)
                    guard !bytes.isEmpty else { return nil }
                    return String(decoding: bytes, as: UTF8.self)
                }

                var bytes: [Byte] = []
                var escaped = false

                while let byte = input.next() {

                    if escaped {
                        bytes.append(byte)
                        escaped = false
                    } else if byte == ASCII.Code.reverseSolidus.byte {
                        escaped = true
                    } else if byte == ASCII.Code.quotationMark.byte {
                        return String(decoding: bytes, as: UTF8.self)
                    } else {
                        bytes.append(byte)
                    }
                }

                return nil
            }

            public borrowing func serialize(
                _ output: Output,
                into buffer: inout Buffer
            ) throws(Failure) {
                buffer.append(contentsOf: RFC_2045.ContentType.canonical(output))
            }
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }
#endif
