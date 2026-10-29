#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_2045.Parameter.Name: ASCII.Parseable {}

    extension RFC_2045.Parameter.Name: ASCII.Serializable,
        Binary.Serializable
    {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.Parameter.Name,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            Scan.append(value.rawValue, into: &buffer)
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.Parameter.Name,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            Scan.append(value.rawValue, into: &buffer)
        }
    }

    extension [Byte] {

        public init(_ name: RFC_2045.Parameter.Name) {
            self = [Byte](name.rawValue.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }
#endif
