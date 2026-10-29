#if Coder
    import ASCII
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_2045.Parameter.Name {

        public struct Coder<
            Input: Cursor.`Protocol`<Byte, Never>,
            Buffer: RangeReplaceableCollection<Byte>
        >: Coding {

            public typealias Output = RFC_2045.Parameter.Name

            public typealias Failure = RFC_2045.Parameter.Name.Error

            public init() {}

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
                let start = input.checkpoint
                let bytes = Scan.run(&input, while: RFC_2045.Grammar.isTokenCharacter)
                do throws(Failure) {
                    return try RFC_2045.Parameter.Name(ascii: bytes)
                } catch {
                    input.seek(to: start)
                    throw error
                }
            }

            public borrowing func serialize(
                _ output: Output,
                into buffer: inout Buffer
            ) throws(Failure) {
                Scan.append(output.rawValue, into: &buffer)
            }
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }
#endif
