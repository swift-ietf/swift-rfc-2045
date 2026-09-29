import ASCII
public import Byte
import Byte

extension RFC_2045 {

    public struct ContentType: Sendable {

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

extension RFC_2045.ContentType {

    public init(
        type: String,
        subtype: String,
        parameters: [RFC_2045.Parameter.Name: String] = [:]
    ) throws(Error) {

        guard !type.isEmpty else {
            throw Error.emptyType(type)
        }

        guard !subtype.isEmpty else {
            throw Error.emptySubtype(subtype)
        }

        try Self.validate(token: type)
        try Self.validate(token: subtype)

        self.init(
            __unchecked: (),
            type: type.lowercased(),
            subtype: subtype.lowercased(),
            parameters: parameters
        )
    }

    private static func validate(token: String) throws(Error) {

        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            codes = try RFC_2045.Grammar.codes(token.utf8.lazy.map(Byte.init(bitPattern:)))
        } catch {
            throw Error.nonASCII(token)
        }

        for code in codes {

            guard code.isVisible else {
                throw Error.invalidCharacter(
                    token,
                    byte: code,
                    reason: "Type and subtype must not contain control characters or space"
                )
            }

            guard !RFC_2045.Grammar.tspecials.contains(code) else {
                throw Error.invalidCharacter(
                    token,
                    byte: code,
                    reason: "Type and subtype must not contain tspecials: ()<>@,;:\\\"/[]?="
                )
            }
        }
    }
}

extension RFC_2045.ContentType {

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
            codes = try RFC_2045.Grammar.codes(bytes)
        } catch {
            throw Error.nonASCII(String(decoding: bytes, as: UTF8.self))
        }

        let text = RFC_2045.Grammar.string(codes)

        let mediaTypeCodes: ArraySlice<ASCII.Code>
        let parameterCodes: ArraySlice<ASCII.Code>?

        if let firstSemicolon = codes.firstIndex(of: ASCII.Code.semicolon) {
            mediaTypeCodes = codes[..<firstSemicolon]
            parameterCodes = codes[(firstSemicolon + 1)...]
        } else {
            mediaTypeCodes = codes[...]
            parameterCodes = nil
        }

        guard let solidus = mediaTypeCodes.firstIndex(of: ASCII.Code.solidus) else {
            throw Error.missingSeparator(text)
        }

        let typeCodes = RFC_2045.Grammar.trimmingWhitespace(mediaTypeCodes[..<solidus])
        let subtypeCodes = RFC_2045.Grammar.trimmingWhitespace(
            mediaTypeCodes[(solidus + 1)...]
        )

        guard !typeCodes.isEmpty else {
            throw Error.emptyType(text)
        }

        guard !subtypeCodes.isEmpty else {
            throw Error.emptySubtype(text)
        }

        var parameters: [RFC_2045.Parameter.Name: String] = [:]

        if let parameterCodes {
            for segment in Self.parameterSegments(parameterCodes) {
                guard let parameter = try Self.parameter(segment, in: text) else {
                    continue
                }
                parameters[parameter.name] = parameter.value
            }
        }

        try self.init(
            type: RFC_2045.Grammar.string(typeCodes),
            subtype: RFC_2045.Grammar.string(subtypeCodes),
            parameters: parameters
        )
    }

    private static func parameterSegments(
        _ codes: ArraySlice<ASCII.Code>
    ) -> [ArraySlice<ASCII.Code>] {

        var segments: [ArraySlice<ASCII.Code>] = []
        var segmentStart = codes.startIndex
        var inQuotedString = false
        var inQuotedPair = false

        for index in codes.indices {

            let code = codes[index]

            if inQuotedPair {
                inQuotedPair = false
            } else if inQuotedString {
                if code == ASCII.Code.reverseSolidus {
                    inQuotedPair = true
                } else if code == ASCII.Code.quotationMark {
                    inQuotedString = false
                }
            } else if code == ASCII.Code.quotationMark {
                inQuotedString = true
            } else if code == ASCII.Code.semicolon {
                segments.append(codes[segmentStart..<index])
                segmentStart = index + 1
            }
        }

        segments.append(codes[segmentStart...])
        return segments
    }

    private static func parameter(
        _ segment: ArraySlice<ASCII.Code>,
        in text: String
    ) throws(Error) -> (name: RFC_2045.Parameter.Name, value: String)? {

        let trimmed = RFC_2045.Grammar.trimmingWhitespace(segment)

        guard !trimmed.isEmpty else {
            return nil
        }

        guard let equals = trimmed.firstIndex(of: ASCII.Code.equalsSign) else {
            throw Error.invalidParameter(text, reason: "Parameter is missing its '=' sign")
        }

        let nameCodes = RFC_2045.Grammar.trimmingWhitespace(trimmed[..<equals])
        let valueCodes = RFC_2045.Grammar.trimmingWhitespace(trimmed[(equals + 1)...])

        let name: RFC_2045.Parameter.Name
        do throws(RFC_2045.Parameter.Name.Error) {
            name = try RFC_2045.Parameter.Name(
                ascii: nameCodes.lazy.map(\.byte)
            )
        } catch {
            throw Error.invalidParameter(text, reason: error.description)
        }

        let isQuoted =
            valueCodes.count >= 2
            && valueCodes.first == ASCII.Code.quotationMark
            && valueCodes.last == ASCII.Code.quotationMark

        guard isQuoted else {
            guard !valueCodes.isEmpty else {
                throw Error.invalidParameter(text, reason: "Parameter value is empty")
            }
            guard valueCodes.allSatisfy(RFC_2045.Grammar.isTokenCharacter) else {
                throw Error.invalidParameter(
                    text,
                    reason: "Parameter value must be a token or a quoted-string"
                )
            }
            return (name, RFC_2045.Grammar.string(valueCodes))
        }

        var unescaped: [ASCII.Code] = []
        unescaped.reserveCapacity(valueCodes.count)
        var escaped = false
        for code in valueCodes.dropFirst().dropLast() {
            if escaped {
                unescaped.append(code)
                escaped = false
            } else if code == ASCII.Code.reverseSolidus {
                escaped = true
            } else {
                unescaped.append(code)
            }
        }

        return (name, RFC_2045.Grammar.string(unescaped))
    }
}

extension RFC_2045.ContentType {

    public var charset: RFC_2045.Charset? {
        parameters[.charset].flatMap { value in
            try? RFC_2045.Charset(value)
        }
    }

    public var boundary: String? {
        parameters[.boundary]
    }

    public var isMultipart: Bool {
        type.lowercased() == "multipart"
    }

    public var isText: Bool {
        type.lowercased() == "text"
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
        RFC_2045.ContentType(
            __unchecked: (),
            type: "application",
            subtype: "octet-stream",
            parameters: name.map { [.name: $0] } ?? [:]
        )
    }

    public static let applicationPDF = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "pdf"
    )

    public static func applicationPDF(name: String? = nil) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "application",
            subtype: "pdf",
            parameters: name.map { [.name: $0] } ?? [:]
        )
    }

    public static let imageJPEG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "jpeg"
    )

    public static func imageJPEG(name: String? = nil) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "jpeg",
            parameters: name.map { [.name: $0] } ?? [:]
        )
    }

    public static let imagePNG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "png"
    )

    public static func imagePNG(name: String? = nil) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "png",
            parameters: name.map { [.name: $0] } ?? [:]
        )
    }

    public static let imageGIF = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "gif"
    )

    public static func imageGIF(name: String? = nil) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "gif",
            parameters: name.map { [.name: $0] } ?? [:]
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
