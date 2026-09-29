import ASCII
import Byte

extension RFC_2045 {

    enum Grammar {

        static let tspecials: Set<ASCII.Code> = [
            ASCII.Code.leftParenthesis,
            ASCII.Code.rightParenthesis,
            ASCII.Code.lessThanSign,
            ASCII.Code.greaterThanSign,
            ASCII.Code.atSign,
            ASCII.Code.comma,
            ASCII.Code.semicolon,
            ASCII.Code.colon,
            ASCII.Code.reverseSolidus,
            ASCII.Code.quotationMark,
            ASCII.Code.solidus,
            ASCII.Code.leftSquareBracket,
            ASCII.Code.rightSquareBracket,
            ASCII.Code.questionMark,
            ASCII.Code.equalsSign,
        ]

        static func isTokenCharacter(_ code: ASCII.Code) -> Bool {
            code.isVisible && !tspecials.contains(code)
        }

        static func isWhitespace(_ code: ASCII.Code) -> Bool {
            code == ASCII.Code.space
                || code == ASCII.Code.htab
                || code == ASCII.Code.lf
                || code == ASCII.Code.cr
        }

        static func trimmingWhitespace(
            _ codes: ArraySlice<ASCII.Code>
        ) -> ArraySlice<ASCII.Code> {
            var start = codes.startIndex
            var end = codes.endIndex
            while start < end && isWhitespace(codes[start]) {
                start += 1
            }
            while end > start && isWhitespace(codes[end - 1]) {
                end -= 1
            }
            return codes[start..<end]
        }

        static func codes<Bytes: Swift.Collection>(
            _ bytes: Bytes
        ) throws(ASCII.Code.Error) -> [ASCII.Code] where Bytes.Element == Byte {
            var built: [ASCII.Code] = []
            built.reserveCapacity(bytes.count)
            for byte in bytes {
                built.append(try ASCII.Code(byte))
            }
            return built
        }

        static func string(_ codes: some Swift.Collection<ASCII.Code>) -> String {
            String(decoding: codes.lazy.map(\.underlying), as: UTF8.self)
        }
    }
}
