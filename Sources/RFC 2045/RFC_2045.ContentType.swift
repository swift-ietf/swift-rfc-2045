public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import Format_Primitives
import INCITS_4_1986
public import Parseable_ASCII_Primitives

private typealias Code = ASCII.Code

extension RFC_2045 {

    public struct ContentType: Sendable, Codable {

        public let type: String

        public let subtype: String

        public let parameters: [RFC_2045.Parameter.Name: String]

        public init(
            __unchecked: Void,
            type: String,
            subtype: String,
            parameters: [RFC_2045.Parameter.Name: String] = [:]
        ) {
            self.type = type
            self.subtype = subtype
            self.parameters = parameters
        }
    }
}

extension [Byte] {
    public init(
        _ contentType: RFC_2045.ContentType.Type
    ) {
        self = [Byte]("Content-Type".utf8)
    }
}

extension RFC_2045.ContentType: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.lowercased())
        hasher.combine(subtype.lowercased())
        hasher.combine(parameters)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type.lowercased() == rhs.type.lowercased()
            && lhs.subtype.lowercased() == rhs.subtype.lowercased()
            && lhs.parameters == rhs.parameters
    }
}

extension RFC_2045.ContentType: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {

        buffer.append(
            contentsOf: canonicalSerialization(value).map { Code(unchecked: $0) }
        )
    }

    internal static func canonicalSerialization(_ value: Self) -> [Byte] {
        var buffer: [Byte] = []
        let estimatedCapacity =
            value.type.count + 1 + value.subtype.count
            + (value.parameters.count * 30)
        buffer.reserveCapacity(estimatedCapacity)

        buffer.append(contentsOf: value.type.utf8)
        buffer.append(Code.solidus)
        buffer.append(contentsOf: value.subtype.utf8)

        for (name, parameterValue) in value.parameters.sorted(by: { $0.key < $1.key }) {
            buffer.append(Code.semicolon)
            buffer.append(Code.space)

            RFC_2045.Parameter.Name.serialize(name, into: &buffer)
            buffer.append(Code.equalsSign)
            if parameterValueRequiresQuoting(parameterValue) {
                buffer.append(contentsOf: quotedStringBytes(parameterValue))
            } else {
                buffer.append(contentsOf: parameterValue.utf8)
            }
        }
        return buffer
    }

    private static func parameterValueRequiresQuoting(_ value: String) -> Bool {
        value.isEmpty || !value.utf8.allSatisfy(RFC_2045.Parse._isTokenChar)
    }

    private static func quotedStringBytes(_ value: String) -> [UInt8] {
        var out: [UInt8] = [0x22]
        for byte in value.utf8 {
            if byte == 0x22 || byte == 0x5C {
                out.append(0x5C)
            }
            out.append(byte)
        }
        out.append(0x22)
        return out
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ contentType: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: canonicalSerialization(contentType))
    }
}

extension RFC_2045.ContentType: ASCII.Parseable {

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

        let typeSubtypeCodes: ArraySlice<ASCII.Code>
        let parametersCodes: ArraySlice<ASCII.Code>?

        if let firstSemicolon = codes.firstIndex(of: Code.semicolon) {
            typeSubtypeCodes = codes[..<firstSemicolon]
            parametersCodes = codes[(firstSemicolon + 1)...]
        } else {
            typeSubtypeCodes = codes[...]
            parametersCodes = nil
        }

        guard let solidus = typeSubtypeCodes.firstIndex(of: Code.solidus) else {
            throw Error.missingSeparator(String(decoding: bytes, as: UTF8.self))
        }

        let typeCodes = Self.trimmingWhitespace(typeSubtypeCodes[..<solidus])
        let subtypeCodes = Self.trimmingWhitespace(typeSubtypeCodes[(solidus + 1)...])

        guard !typeCodes.isEmpty else {
            throw Error.emptyType(String(decoding: bytes, as: UTF8.self))
        }

        guard !subtypeCodes.isEmpty else {
            throw Error.emptySubtype(String(decoding: bytes, as: UTF8.self))
        }

        let type = String(decoding: typeCodes, as: UTF8.self).lowercased()
        let subtype = String(decoding: subtypeCodes, as: UTF8.self).lowercased()

        var params: [RFC_2045.Parameter.Name: String] = [:]

        if let parametersCodes {
            let pCodes = Array(parametersCodes)
            var segStart = 0

            func processParam(_ lo: Int, _ hi: Int) {
                let segment = pCodes[lo..<hi]
                guard let equalsIndex = segment.firstIndex(of: Code.equalsSign) else {
                    return
                }

                let keyCodes = Self.trimmingWhitespace(segment[..<equalsIndex])
                var valueCodes = Array(
                    Self.trimmingWhitespace(segment[(equalsIndex &+ 1)...])
                )

                guard !keyCodes.isEmpty else {
                    return
                }

                let isQuoted =
                    valueCodes.count >= 2
                    && valueCodes.first == Code.quotationMark
                    && valueCodes.last == Code.quotationMark
                if isQuoted {
                    valueCodes = Array(valueCodes.dropFirst().dropLast())
                    var unescaped: [ASCII.Code] = []
                    unescaped.reserveCapacity(valueCodes.count)
                    var escaped = false
                    for code in valueCodes {
                        if escaped {
                            unescaped.append(code)
                            escaped = false
                        } else if code == Code.reverseSolidus {
                            escaped = true
                        } else {
                            unescaped.append(code)
                        }
                    }
                    valueCodes = unescaped
                }

                let key = RFC_2045.Parameter.Name(
                    rawValue: String(decoding: keyCodes, as: UTF8.self).lowercased()
                )
                let value = String(decoding: valueCodes, as: UTF8.self)

                params[key] = value
            }

            var inQuotedString = false
            var inQuotedPair = false
            for idx in 0..<pCodes.count {
                let code = pCodes[idx]
                if inQuotedPair {
                    inQuotedPair = false
                } else if inQuotedString {
                    if code == Code.reverseSolidus {
                        inQuotedPair = true
                    } else if code == Code.quotationMark {
                        inQuotedString = false
                    }
                } else if code == Code.quotationMark {
                    inQuotedString = true
                } else if code == Code.semicolon {
                    processParam(segStart, idx)
                    segStart = idx &+ 1
                }
            }
            processParam(segStart, pCodes.count)
        }

        self.init(__unchecked: (), type: type, subtype: subtype, parameters: params)
    }

    private static func trimmingWhitespace(
        _ codes: ArraySlice<ASCII.Code>
    ) -> ArraySlice<ASCII.Code> {
        var start = codes.startIndex
        var end = codes.endIndex
        while start < end && Self.isWhitespace(codes[start]) {
            start += 1
        }
        while end > start && Self.isWhitespace(codes[end - 1]) {
            end -= 1
        }
        return codes[start..<end]
    }

    private static func isWhitespace(_ code: ASCII.Code) -> Bool {
        code == Code.space
            || code == Code.htab
            || code == Code.lf
            || code == Code.cr
    }
}

extension [Byte] {

    public init(_ contentType: RFC_2045.ContentType) {

        self = RFC_2045.ContentType.canonicalSerialization(contentType)
    }
}

extension RFC_2045.ContentType: Swift.RawRepresentable {

    public var rawValue: String {
        String(decoding: serialized, as: UTF8.self)
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
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_2045.ContentType {

    public var headerValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    public var charset: RFC_2045.Charset? {
        parameters[.charset].map { RFC_2045.Charset($0) }
    }

    public var boundary: String? {
        parameters[.boundary]
    }

    public var isMultipart: Bool {
        type == "multipart"
    }

    public var isText: Bool {
        type == "text"
    }
}

extension RFC_2045.ContentType {

    public static let textPlain = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "plain"
    )

    public static let textPlainUTF8 = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "plain",
        parameters: [.charset: RFC_2045.Charset.utf8.rawValue]
    )

    public static let textHTML = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "html"
    )

    public static let textHTMLUTF8 = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "html",
        parameters: [.charset: RFC_2045.Charset.utf8.rawValue]
    )

    public static func multipartAlternative(boundary: String) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "multipart",
            subtype: "alternative",
            parameters: [.boundary: boundary]
        )
    }

    public static func multipartMixed(boundary: String) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "multipart",
            subtype: "mixed",
            parameters: [.boundary: boundary]
        )
    }

    public static let applicationOctetStream = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "octet-stream"
    )

    public static func applicationOctetStream(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "application",
            subtype: "octet-stream",
            parameters: params
        )
    }

    public static let applicationPDF = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "pdf"
    )

    public static func applicationPDF(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "application",
            subtype: "pdf",
            parameters: params
        )
    }

    public static let imageJPEG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "jpeg"
    )

    public static func imageJPEG(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "jpeg",
            parameters: params
        )
    }

    public static let imagePNG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "png"
    )

    public static func imagePNG(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "png",
            parameters: params
        )
    }

    public static let imageGIF = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "gif"
    )

    public static func imageGIF(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "gif",
            parameters: params
        )
    }
}

extension RFC_2045.ContentType {

    public static let videoMP4 = RFC_2045.ContentType(
        __unchecked: (),
        type: "video",
        subtype: "mp4"
    )

    public static let videoWebM = RFC_2045.ContentType(
        __unchecked: (),
        type: "video",
        subtype: "webm"
    )

    public static let videoOgg = RFC_2045.ContentType(
        __unchecked: (),
        type: "video",
        subtype: "ogg"
    )

    public static let audioMPEG = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "mpeg"
    )

    public static let audioOgg = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "ogg"
    )

    public static let audioWav = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "wav"
    )

    public static let audioWebM = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "webm"
    )

    public static let imageWEBP = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "webp"
    )

    public static let imageAVIF = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "avif"
    )

    public static let imageSVG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "svg+xml"
    )

    public static let imageXIcon = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "x-icon"
    )

    public static let textCSS = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "css"
    )

    public static let textJavaScript = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "javascript"
    )

    public static let applicationJSON = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "json"
    )

    public static let applicationManifestJSON = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "manifest+json"
    )

    public static let applicationRSSXML = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "rss+xml"
    )

    public static let applicationAtomXML = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "atom+xml"
    )

    public static let applicationXWWWFormURLEncoded = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "x-www-form-urlencoded"
    )
}
