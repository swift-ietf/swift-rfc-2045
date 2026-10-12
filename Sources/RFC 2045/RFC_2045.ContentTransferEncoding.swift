import ASCII
public import Byte

extension RFC_2045 {

    public enum ContentTransferEncoding: String, Hashable, Sendable {

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

extension RFC_2045.ContentTransferEncoding: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

extension RFC_2045.ContentTransferEncoding {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift::Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            var built: [ASCII.Code] = []
            built.reserveCapacity(bytes.count)
            for byte in bytes {
                built.append(try ASCII.Code(byte))
            }
            codes = built
        } catch {
            throw Error.nonASCII(String(decoding: bytes, as: UTF8.self))
        }

        var trimStart = codes.startIndex
        var trimEnd = codes.endIndex
        while trimStart < trimEnd,
            codes[trimStart] == ASCII.Code.space || codes[trimStart] == ASCII.Code.htab
        {
            trimStart += 1
        }
        while trimEnd > trimStart,
            codes[trimEnd - 1] == ASCII.Code.space || codes[trimEnd - 1] == ASCII.Code.htab
        {
            trimEnd -= 1
        }
        let trimmed = codes[trimStart..<trimEnd]

        guard !trimmed.isEmpty else {
            throw Error.empty
        }

        let normalized = String(
            decoding: trimmed.lazy.map { $0.lowercased().underlying },
            as: UTF8.self
        )

        guard let encoding = RFC_2045.ContentTransferEncoding(rawValue: normalized) else {
            throw Error.unrecognizedEncoding(String(decoding: bytes, as: UTF8.self))
        }

        self = encoding
    }
}
