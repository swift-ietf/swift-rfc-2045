public import ASCII_Serializer
public import Binary_Serializable
public import Format
import INCITS_4_1986
public import Parseable_ASCII

extension RFC_2045.Parameter {

    public struct Name: Sendable, Codable {

        internal let storage: Format.Case.Insensitive

        init(
            __unchecked: Void,
            rawValue: String
        ) {
            self.storage = Format.Case.Insensitive(rawValue)
        }

        public init(rawValue: String) {
            self.storage = Format.Case.Insensitive(rawValue)
        }

        public init(_ caseInsensitive: Format.Case.Insensitive) {
            self.storage = caseInsensitive
        }
    }
}

extension RFC_2045.Parameter.Name {

    public var rawValue: String {
        storage.value.lowercased()
    }
}

extension RFC_2045.Parameter.Name: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(storage)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue.lowercased() == rhs.lowercased()
    }
}

extension RFC_2045.Parameter.Name: ASCII.Serializable, Binary.Serializable {

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

extension RFC_2045.Parameter.Name: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

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

        let tspecials: Set<ASCII.Code> = [
            ASCII.Code.leftParenthesis,
            ASCII.Code.rightParenthesis,
            ASCII.Code.lessThanSign,
            ASCII.Code.greaterThanSign,
            ASCII.Code.atSign,
            ASCII.Code.comma,
            ASCII.Code.semicolon,
            ASCII.Code.colon,
            ASCII.Code.backslash,
            ASCII.Code.quotationMark,
            ASCII.Code.solidus,
            ASCII.Code.leftSquareBracket,
            ASCII.Code.rightSquareBracket,
            ASCII.Code.questionMark,
            ASCII.Code.equalsSign,
        ]

        for code in codes {

            guard code.isVisible else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code,
                    reason: "Parameter names must not contain control characters or space"
                )
            }

            guard !tspecials.contains(code) else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code,
                    reason: "Parameter names must not contain tspecials: ()<>@,;:\\\"/[]?="
                )
            }
        }

        let rawValue = String(decoding: bytes, as: UTF8.self)
        self.init(__unchecked: (), rawValue: rawValue)
    }
}

extension RFC_2045.Parameter.Name: RawRepresentable {}
extension RFC_2045.Parameter.Name: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_2045.Parameter.Name: Comparable {
    public static func < (lhs: RFC_2045.Parameter.Name, rhs: RFC_2045.Parameter.Name) -> Bool {
        lhs.storage < rhs.storage
    }
}

extension RFC_2045.Parameter.Name {

    public static let charset = Self(__unchecked: (), rawValue: "charset")

    public static let boundary = Self(__unchecked: (), rawValue: "boundary")

    @available(*, deprecated, message: "Use Content-Disposition filename parameter per RFC 2183")
    public static let name = Self(__unchecked: (), rawValue: "name")
}
