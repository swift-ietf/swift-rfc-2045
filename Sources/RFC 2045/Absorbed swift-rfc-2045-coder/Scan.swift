#if Coder
    import ASCII
    import Byte
    import Cursor

    enum Scan {

        static func run<Input: Cursor.`Protocol`<Byte, Never>>(
            _ input: inout Input,
            while predicate: (Byte) -> Bool
        ) -> [Byte] {
            var bytes: [Byte] = []
            while true {
                let mark = input.checkpoint
                guard let byte = input.next(), predicate(byte) else {
                    input.seek(to: mark)
                    return bytes
                }
                bytes.append(byte)
            }
        }

        static func skipWhitespace<Input: Cursor.`Protocol`<Byte, Never>>(_ input: inout Input) {
            _ = run(&input, while: isWhitespace)
        }

        static func take<Input: Cursor.`Protocol`<Byte, Never>>(
            _ input: inout Input,
            _ code: ASCII.Code
        ) -> Bool {
            let mark = input.checkpoint
            guard let next = input.next(), next == code.byte else {
                input.seek(to: mark)
                return false
            }
            return true
        }

        static func isWhitespace(_ byte: Byte) -> Bool {
            byte == ASCII.Code.space.byte || byte == ASCII.Code.htab.byte
        }

        static func append<Buffer: RangeReplaceableCollection<Byte>>(
            _ string: String,
            into buffer: inout Buffer
        ) {
            buffer.append(contentsOf: string.utf8.lazy.map(Byte.init(bitPattern:)))
        }

        static func append<Buffer: RangeReplaceableCollection<ASCII.Code>>(
            _ string: String,
            into buffer: inout Buffer
        ) {
            buffer.append(contentsOf: string.utf8.lazy.map { ASCII.Code($0) })
        }
    }
#endif
