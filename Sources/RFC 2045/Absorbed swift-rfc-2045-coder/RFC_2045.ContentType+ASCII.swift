#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_2045.ContentType: ASCII.Parseable {}

    extension RFC_2045.ContentType: ASCII.Serializable,
        Binary.Serializable
    {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.ContentType,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            buffer.append(
                contentsOf: canonical(value).lazy.map { ASCII.Code(unchecked: $0) }
            )
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.ContentType,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            buffer.append(contentsOf: canonical(value))
        }

        static func canonical(_ value: RFC_2045.ContentType) -> [Byte] {

            var buffer: [Byte] = []
            buffer.reserveCapacity(
                value.type.count + 1 + value.subtype.count + (value.parameters.count * 30)
            )

            Scan.append(value.type, into: &buffer)
            buffer.append(ASCII.Code.solidus.byte)
            Scan.append(value.subtype, into: &buffer)

            for (name, parameterValue) in value.parameters.sorted(by: { $0.key < $1.key }) {

                buffer.append(ASCII.Code.semicolon.byte)
                buffer.append(ASCII.Code.space.byte)
                Scan.append(name.rawValue, into: &buffer)
                buffer.append(ASCII.Code.equalsSign.byte)

                if RFC_2045.Grammar.requiresQuoting(parameterValue) {
                    buffer.append(contentsOf: RFC_2045.Grammar.quoted(parameterValue))
                } else {
                    Scan.append(parameterValue, into: &buffer)
                }
            }

            return buffer
        }
    }

    extension RFC_2045.ContentType: Swift::RawRepresentable {

        public var rawValue: String {
            String(decoding: RFC_2045.ContentType.canonical(self), as: UTF8.self)
        }

        public init?(rawValue: String) {
            do throws(Error) {
                try self.init(rawValue)
            } catch {
                return nil
            }
        }
    }

    extension RFC_2045.ContentType: CustomStringConvertible {

        public var description: String {
            rawValue
        }
    }

    extension RFC_2045.ContentType {

        public var headerValue: String {
            rawValue
        }
    }

    extension [Byte] {

        public init(_ contentType: RFC_2045.ContentType) {
            self = RFC_2045.ContentType.canonical(contentType)
        }

        public init(_ contentType: RFC_2045.ContentType.Type) {
            self = [Byte]("Content-Type".utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }
#endif
