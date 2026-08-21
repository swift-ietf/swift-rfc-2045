public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import INCITS_4_1986
public import Parseable_ASCII_Primitives

private typealias Code = ASCII.Code

extension RFC_2045 {

    public struct Charset: Sendable, Codable {

        public let rawValue: String

        init(
            __unchecked: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {

            self.rawValue = rawValue.uppercased()
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

extension RFC_2045.Charset: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {

    public init?(rawValue: String) {
        self.init(rawValue)
    }

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

extension RFC_2045.Charset: ASCII.Parseable {

    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            codes = try [ASCII.Code](bytes)
        } catch {
            throw Error.nonASCII(String(decoding: bytes, as: UTF8.self))
        }

        for code in codes {
            guard code.isVisible || code == Code.hyphen else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code,
                    reason: "Charset identifiers must contain only printable ASCII characters"
                )
            }
        }

        let rawValue = String(decoding: bytes, as: UTF8.self).uppercased()
        self.init(__unchecked: (), rawValue: rawValue)
    }
}

extension [Byte] {

    public init(_ charset: RFC_2045.Charset) {
        self = [Byte](charset.rawValue.utf8)
    }
}

extension RFC_2045.Charset: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
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
