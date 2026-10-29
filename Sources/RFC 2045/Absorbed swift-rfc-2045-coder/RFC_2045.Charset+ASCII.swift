#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_2045.Charset: ASCII.Parseable {}

    extension RFC_2045.Charset: ASCII.Serializable, Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.Charset,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            Scan.append(value.rawValue, into: &buffer)
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.Charset,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            Scan.append(value.rawValue, into: &buffer)
        }
    }

    extension [Byte] {

        public init(_ charset: RFC_2045.Charset) {
            self = [Byte](charset.rawValue.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }
#endif
