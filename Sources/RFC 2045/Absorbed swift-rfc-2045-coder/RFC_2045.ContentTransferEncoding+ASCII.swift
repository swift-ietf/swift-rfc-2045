#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_2045.ContentTransferEncoding: @retroactive ASCII.Parseable {}

    extension RFC_2045.ContentTransferEncoding: @retroactive ASCII.Serializable,
        @retroactive Binary.Serializable
    {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.ContentTransferEncoding,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            Scan.append(value.rawValue, into: &buffer)
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: RFC_2045.ContentTransferEncoding,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            Scan.append(value.rawValue, into: &buffer)
        }
    }

    extension [Byte] {

        public init(_ contentTransferEncoding: RFC_2045.ContentTransferEncoding) {
            self = [Byte](contentTransferEncoding.rawValue.utf8.lazy.map(Byte.init(bitPattern:)))
        }

        public init(_ contentTransferEncoding: RFC_2045.ContentTransferEncoding.Type) {
            self = [Byte]("Content-Transfer-Encoding".utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }
#endif
