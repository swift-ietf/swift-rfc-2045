public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import INCITS_4_1986
public import Parseable_ASCII_Primitives

extension RFC_2045 {

    public enum ContentTransferEncoding: String, Hashable, Sendable, Codable {

        case sevenBit = "7bit"

        case eightBit = "8bit"

        case binary = "binary"

        case quotedPrintable = "quoted-printable"

        case base64 = "base64"
    }
}

extension RFC_2045.ContentTransferEncoding {

    public var isBinarySafe: Bool {
        switch self {
        case .base64, .quotedPrintable:
            return true

        case .sevenBit, .eightBit, .binary:
            return false
        }
    }

    public var isEncoded: Bool {
        switch self {
        case .base64, .quotedPrintable:
            return true

        case .sevenBit, .eightBit, .binary:
            return false
        }
    }
}

extension [Byte] {
    public init(
        _ contentTransferEncoding: RFC_2045.ContentTransferEncoding.Type
    ) {
        self = [Byte]("Content-Transfer-Encoding".utf8)
    }
}

extension RFC_2045.ContentTransferEncoding: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }
}

extension RFC_2045.ContentTransferEncoding: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            codes = try [ASCII.Code](bytes)
        } catch {
            throw Error.nonASCII(String(decoding: bytes, as: UTF8.self))
        }

        var trimStart = codes.startIndex
        var trimEnd = codes.endIndex
        while trimStart < trimEnd,
            codes[trimStart] == Code.space || codes[trimStart] == Code.htab
        {
            trimStart += 1
        }
        while trimEnd > trimStart,
            codes[trimEnd - 1] == Code.space || codes[trimEnd - 1] == Code.htab
        {
            trimEnd -= 1
        }
        let trimmed = codes[trimStart..<trimEnd]

        guard !trimmed.isEmpty else {
            throw Error.empty
        }

        let normalized: [ASCII.Code] = trimmed.map { $0.lowercased() }

        switch normalized.count {
        case 4 where normalized == .`7bit`:
            self = .sevenBit

        case 4 where normalized == .`8bit`:
            self = .eightBit

        case 6 where normalized == .base64:
            self = .base64

        case 6 where normalized == .binary:
            self = .binary

        case 16 where normalized == .quotedPrintable:
            self = .quotedPrintable

        default:
            throw Error.unrecognizedEncoding(String(decoding: bytes, as: UTF8.self))
        }
    }
}

private typealias Code = ASCII.Code

extension [ASCII.Code] {

    static let `7bit`: Self = [Code.`7`, Code.b, Code.i, Code.t]
    static let `8bit`: Self = [Code.`8`, Code.b, Code.i, Code.t]
    static let base64: Self = [
        Code.b, Code.a, Code.s, Code.e, Code.`6`, Code.`4`,
    ]
    static let binary: Self = [
        Code.b, Code.i, Code.n, Code.a, Code.r, Code.y,
    ]
    static let quotedPrintable: Self = [
        Code.q, Code.u, Code.o, Code.t, Code.e, Code.d,
        Code.hyphen,
        Code.p, Code.r, Code.i, Code.n, Code.t,
        Code.a, Code.b, Code.l, Code.e,
    ]
}

extension RFC_2045.ContentTransferEncoding: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}
