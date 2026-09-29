import ASCII
public import Byte
import Byte

extension RFC_2045 {

    public struct Charset: Sendable {

        public let rawValue: String

        public init(
            __unchecked: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

extension RFC_2045.Charset: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.uppercased())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.uppercased() == rhs.rawValue.uppercased()
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue.uppercased() == rhs.uppercased()
    }
}

public func == (lhs: RFC_2045.Charset?, rhs: String) -> Bool {
    guard let lhs else { return false }
    return lhs.rawValue.uppercased() == rhs.uppercased()
}

extension RFC_2045.Charset: Swift.RawRepresentable {

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_2045.Charset: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

extension RFC_2045.Charset {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        guard !bytes.isEmpty else {
            throw Error.empty
        }

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

        for code in codes {
            guard code.isVisible || code == ASCII.Code.hyphen else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code,
                    reason: "Charset identifiers must contain only printable ASCII characters"
                )
            }
        }

        self.init(
            __unchecked: (),
            rawValue: String(decoding: bytes, as: UTF8.self).uppercased()
        )
    }
}

extension RFC_2045.Charset {

    public static let utf8 = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-8")

    public static let usASCII = RFC_2045.Charset(__unchecked: (), rawValue: "US-ASCII")

    public static let iso88591 = RFC_2045.Charset(__unchecked: (), rawValue: "ISO-8859-1")

    public static let utf16 = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-16")

    public static let utf16BE = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-16BE")

    public static let utf16LE = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-16LE")

    public static let utf32 = RFC_2045.Charset(__unchecked: (), rawValue: "UTF-32")

    public static let iso88592 = RFC_2045.Charset(__unchecked: (), rawValue: "ISO-8859-2")

    public static let iso885915 = RFC_2045.Charset(__unchecked: (), rawValue: "ISO-8859-15")

    public static let windows1252 = RFC_2045.Charset(__unchecked: (), rawValue: "WINDOWS-1252")
}
