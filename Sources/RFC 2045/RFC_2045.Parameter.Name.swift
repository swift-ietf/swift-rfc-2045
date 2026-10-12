import ASCII
public import Byte

extension RFC_2045.Parameter {

    public struct Name: Sendable {

        public let rawValue: String

        public init(
            __unchecked: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

extension RFC_2045.Parameter.Name: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue.lowercased())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue.lowercased() == rhs.lowercased()
    }
}

extension RFC_2045.Parameter.Name: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.lowercased() < rhs.rawValue.lowercased()
    }
}

extension RFC_2045.Parameter.Name: Swift::RawRepresentable {

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_2045.Parameter.Name: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

extension RFC_2045.Parameter.Name {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift::Collection>(ascii bytes: Bytes) throws(Error)
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

            guard code.isVisible else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code,
                    reason: "Parameter names must not contain control characters or space"
                )
            }

            guard !RFC_2045.Grammar.tspecials.contains(code) else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code,
                    reason: "Parameter names must not contain tspecials: ()<>@,;:\\\"/[]?="
                )
            }
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

extension RFC_2045.Parameter.Name {

    public static let charset = Self(__unchecked: (), rawValue: "charset")

    public static let boundary = Self(__unchecked: (), rawValue: "boundary")

    public static let name = Self(__unchecked: (), rawValue: "name")
}
