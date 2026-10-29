#if Coder
    import ASCII
    import Byte

    extension RFC_2045.Grammar {

        static let tspecialBytes: Set<Byte> = [
            ASCII.Code.leftParenthesis.byte,
            ASCII.Code.rightParenthesis.byte,
            ASCII.Code.lessThanSign.byte,
            ASCII.Code.greaterThanSign.byte,
            ASCII.Code.atSign.byte,
            ASCII.Code.comma.byte,
            ASCII.Code.semicolon.byte,
            ASCII.Code.colon.byte,
            ASCII.Code.reverseSolidus.byte,
            ASCII.Code.quotationMark.byte,
            ASCII.Code.solidus.byte,
            ASCII.Code.leftSquareBracket.byte,
            ASCII.Code.rightSquareBracket.byte,
            ASCII.Code.questionMark.byte,
            ASCII.Code.equalsSign.byte,
        ]

        static func isTokenCharacter(_ byte: Byte) -> Bool {
            guard let code = try? ASCII.Code(byte), code.isVisible else { return false }
            return !tspecialBytes.contains(byte)
        }

        static func requiresQuoting(_ value: String) -> Bool {
            value.isEmpty || !value.utf8.allSatisfy { isTokenCharacter(Byte(bitPattern: $0)) }
        }

        static func quoted(_ value: String) -> [Byte] {
            var out: [Byte] = [ASCII.Code.quotationMark.byte]
            for byte in value.utf8.lazy.map(Byte.init(bitPattern:)) {
                if byte == ASCII.Code.quotationMark.byte || byte == ASCII.Code.reverseSolidus.byte {
                    out.append(ASCII.Code.reverseSolidus.byte)
                }
                out.append(byte)
            }
            out.append(ASCII.Code.quotationMark.byte)
            return out
        }
    }
#endif
