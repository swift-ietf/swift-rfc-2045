//
//  RFC_2045.ContentType.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
import Format_Primitives
public import INCITS_4_1986
public import Parseable_ASCII_Primitives

// `Code` aliases ASCII.Code at file scope, where bare `ASCII` resolves to the
// module namespace. Inside the `extension [Byte]` blocks below, INCITS's
// `[ASCII.Code].ASCII` would otherwise shadow `ASCII` via Array member lookup.
private typealias Code = ASCII.Code

extension RFC_2045 {
    /// MIME Content-Type header
    ///
    /// Defines the media type of the content, consisting of a type, subtype,
    /// and optional parameters.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Simple text type
    /// let plain = try RFC_2045.ContentType("text/plain")
    ///
    /// // With charset parameter (type-safe)
    /// let html = try RFC_2045.ContentType("text/html; charset=UTF-8")
    ///
    /// // Using static constants
    /// let utf8Text = RFC_2045.ContentType.textPlainUTF8
    /// ```
    ///
    /// ## RFC Reference
    ///
    /// From RFC 2045 Section 5:
    ///
    /// > In general, the top-level media type is used to declare the general
    /// > type of data, while the subtype specifies a specific format for that
    /// > type of data.
    public struct ContentType: Sendable, Codable {
        /// The primary media type (e.g., "text", "image", "multipart")
        public let type: String

        /// The media subtype (e.g., "plain", "html", "jpeg")
        public let subtype: String

        /// Optional parameters (e.g., [.charset: "UTF-8"])
        ///
        /// Uses type-safe `RFC_2045.Parameter.Name` for parameter names.
        public let parameters: [RFC_2045.Parameter.Name: String]

        /// Creates a ContentType WITHOUT validation
        ///
        /// **Warning**: Bypasses all RFC validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to indicate unchecked initialization
        ///   - type: Primary media type (should be lowercased)
        ///   - subtype: Media subtype (should be lowercased)
        ///   - parameters: Optional parameters
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

// MARK: - Hashable

extension RFC_2045.ContentType: Hashable {
    /// Hash value (case-insensitive for type/subtype)
    ///
    /// Content-Type type and subtype are case-insensitive per RFC 2045.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.lowercased())
        hasher.combine(subtype.lowercased())
        hasher.combine(parameters)
    }

    /// Equality comparison (case-insensitive for type/subtype)
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type.lowercased() == rhs.type.lowercased()
            && lhs.subtype.lowercased() == rhs.subtype.lowercased()
            && lhs.parameters == rhs.parameters
    }
}

// MARK: - Serializable

extension RFC_2045.ContentType: ASCII.Serializable, Binary.Serializable {
    /// Own `ASCII.Serializable` verb ([FAM-012]) — the RFC 2045 Content-Type
    /// header value, composing the already-re-cut `Parameter.Name` **ASCII** verb
    /// directly into the `ASCII.Code` buffer (no `.rawValue` property-detour). The
    /// conformer's own `type` / `subtype` / parameter-value fields are leaf-emitted
    /// on the ASCII-code substrate. Output is identical to the Binary witness body
    /// (`serializeBytes`).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        // Delegate to the single canonical body; the output is strict ASCII by
        // construction (RFC 2045 grammar), so the unchecked lift is sound.
        buffer.append(
            contentsOf: canonicalSerialization(value).map { Code(unchecked: $0) }
        )
    }

    /// Single canonical serialization body — RFC 2045 Content-Type header
    /// value with a **defined, deterministic parameter order** (sorted by
    /// `Parameter.Name`). Every public serialization surface (`headerValue`,
    /// `.serialized`, the ASCII and Binary witnesses, and `[Byte](_:)`)
    /// delegates here, so all emit identical bytes.
    internal static func canonicalSerialization(_ value: Self) -> [Byte] {
        var buffer: [Byte] = []
        let estimatedCapacity =
            value.type.count + 1 + value.subtype.count
            + (value.parameters.count * 30)  // ~30 bytes per parameter
        buffer.reserveCapacity(estimatedCapacity)

        // type/subtype — ContentType's own fields, leaf-emitted.
        buffer.append(contentsOf: value.type.utf8)
        buffer.append(Code.solidus)
        buffer.append(contentsOf: value.subtype.utf8)

        // parameters: ; name=value in canonical (sorted-by-name) order — a
        // non-token value MUST be emitted as a quoted-string (RFC 2045 §5.1);
        // token-safe values emit bare, byte-identical to the historical form.
        for (name, parameterValue) in value.parameters.sorted(by: { $0.key < $1.key }) {
            buffer.append(Code.semicolon)
            buffer.append(Code.space)
            // Compose the re-cut Parameter.Name Binary verb (no rawValue detour).
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

    /// RFC 2045 §5.1: `parameter := attribute "=" value` where
    /// `value := token / quoted-string`. A value that is not a valid token
    /// (empty, or containing tspecials / SPACE / CTLs) must go out as a
    /// quoted-string. The parse side already strips the quotes back off.
    private static func parameterValueRequiresQuoting(_ value: String) -> Bool {
        value.isEmpty || !value.utf8.allSatisfy(RFC_2045.Parse._isTokenChar)
    }

    /// The RFC 2045 quoted-string encoding of `value` as raw UTF-8 bytes,
    /// backslash-escaping '"' and '\'.
    private static func quotedStringBytes(_ value: String) -> [UInt8] {
        var out: [UInt8] = [0x22]  // '"'
        for byte in value.utf8 {
            if byte == 0x22 || byte == 0x5C {  // '"' or '\'
                out.append(0x5C)
            }
            out.append(byte)
        }
        out.append(0x22)  // '"'
        return out
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable defaults.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    /// Byte-domain serialization body (RFC 2045 Content-Type header value) —
    /// delegates to the single canonical body.
    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ contentType: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: canonicalSerialization(contentType))
    }
}

extension RFC_2045.ContentType: ASCII.Parseable {
    /// Creates a Content-Type by validating `string`'s UTF-8 bytes as ASCII.
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses a Content-Type header from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 2045 MIME headers are pure ASCII, so this parser operates on ASCII bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_2045.ContentType (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [Byte] (UTF-8 bytes) → ContentType
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = [Byte]("text/html; charset=UTF-8".utf8)
    /// let contentType = try RFC_2045.ContentType(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the header value
    /// - Throws: `RFC_2045.ContentType.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (Content-Type grammar is strict ASCII;
        // non-ASCII bytes are fail-state via downstream validation).
        let codes: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            codes = try [ASCII.Code](bytes)
        } catch {
            throw Error.nonASCII(String(decoding: bytes, as: UTF8.self))
        }

        // Split on first semicolon to separate type/subtype from parameters
        let typeSubtypeCodes: ArraySlice<ASCII.Code>
        let parametersCodes: ArraySlice<ASCII.Code>?

        if let firstSemicolon = codes.firstIndex(of: Code.semicolon) {
            typeSubtypeCodes = codes[..<firstSemicolon]
            parametersCodes = codes[(firstSemicolon + 1)...]
        } else {
            typeSubtypeCodes = codes[...]
            parametersCodes = nil
        }

        // Parse type/subtype
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

        // Parse parameters if present
        var params: [RFC_2045.Parameter.Name: String] = [:]

        if let parametersCodes = parametersCodes {
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

                // Handle quoted values (RFC 2045 §5.1 quoted-string): remove
                // the surrounding quotes and unescape quoted-pairs
                // (`\X` -> `X`) when materializing the parameter value.
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

            // Quote-aware split on ';' — a semicolon inside a quoted-string
            // (or preceded by a quoted-pair backslash) does not terminate the
            // parameter (RFC 2045 §5.1).
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

    /// Trim leading and trailing ASCII whitespace (SP, HTAB, LF, CR).
    ///
    /// Manual trim in the `ASCII.Code` domain — replaces the previous
    /// `INCITS_4_1986.ASCII<Source>` pipeline (which is `UInt8`-keyed) so
    /// the parser body can stay in `ASCII.Code` end-to-end after the
    /// `Binary.ASCII.Serializable` retyping to `Buffer.Element == Byte`.
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

    /// ASCII whitespace per INCITS 4-1986: SPACE, HTAB, LF, CR.
    private static func isWhitespace(_ code: ASCII.Code) -> Bool {
        code == Code.space
            || code == Code.htab
            || code == Code.lf
            || code == Code.cr
    }
}

// MARK: - Byte Serialization

extension [Byte] {
    /// Creates ASCII byte representation of an RFC 2045 ContentType
    ///
    /// This is the canonical serialization of MIME Content-Type headers to bytes.
    /// RFC 2045 MIME headers are ASCII-only by definition.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_2045.ContentType (structured data)
    /// - **Codomain**: [Byte] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// ContentType → [Byte] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Performance
    ///
    /// Efficient byte composition:
    /// - Single allocation with capacity estimation
    /// - Direct ASCII byte operations
    /// - No intermediate String allocations
    ///
    /// ## Example
    ///
    /// ```swift
    /// let contentType = RFC_2045.ContentType.textPlainUTF8
    /// let bytes = [Byte](contentType)
    /// // bytes represents "text/plain; charset=UTF-8" as ASCII bytes
    /// ```
    ///
    /// - Parameter contentType: The content type to serialize
    public init(_ contentType: RFC_2045.ContentType) {
        // Delegate to the single canonical serialization body (sorted
        // parameter order, quoted-string for non-token values) so this
        // surface is byte-identical to the Serializable witnesses.
        self = RFC_2045.ContentType.canonicalSerialization(contentType)
    }
}

// MARK: - Protocol Conformances

extension RFC_2045.ContentType: Swift.RawRepresentable {
    /// The Content-Type's ASCII serialization as a `String`.
    public var rawValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    public init?(rawValue: String) { try? self.init(rawValue) }
}

extension RFC_2045.ContentType: CustomStringConvertible {
    /// The Content-Type's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

// MARK: - Computed Properties

extension RFC_2045.ContentType {
    /// The complete header value
    ///
    /// Example: `"text/html; charset=UTF-8"`
    public var headerValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    /// Convenience accessor for charset parameter (type-safe)
    public var charset: RFC_2045.Charset? {
        parameters[.charset].map { RFC_2045.Charset($0) }
    }

    /// Convenience accessor for boundary parameter (for multipart types)
    public var boundary: String? {
        parameters[.boundary]
    }

    /// Returns true if this is a multipart type
    public var isMultipart: Bool {
        type == "multipart"
    }

    /// Returns true if this is a text type
    public var isText: Bool {
        type == "text"
    }
}

// MARK: - Common Content Types

extension RFC_2045.ContentType {
    /// text/plain
    public static let textPlain = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "plain"
    )

    /// text/plain; charset=UTF-8
    public static let textPlainUTF8 = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "plain",
        parameters: [.charset: RFC_2045.Charset.utf8.rawValue]
    )

    /// text/html
    public static let textHTML = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "html"
    )

    /// text/html; charset=UTF-8
    public static let textHTMLUTF8 = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "html",
        parameters: [.charset: RFC_2045.Charset.utf8.rawValue]
    )

    /// Creates multipart/alternative with the given boundary
    public static func multipartAlternative(boundary: String) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "multipart",
            subtype: "alternative",
            parameters: [.boundary: boundary]
        )
    }

    /// Creates multipart/mixed with the given boundary
    public static func multipartMixed(boundary: String) -> RFC_2045.ContentType {
        RFC_2045.ContentType(
            __unchecked: (),
            type: "multipart",
            subtype: "mixed",
            parameters: [.boundary: boundary]
        )
    }

    // MARK: Application Types

    /// application/octet-stream
    public static let applicationOctetStream = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "octet-stream"
    )

    /// Creates application/octet-stream with optional name parameter
    public static func applicationOctetStream(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name = name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "application",
            subtype: "octet-stream",
            parameters: params
        )
    }

    /// application/pdf
    public static let applicationPDF = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "pdf"
    )

    /// Creates application/pdf with optional name parameter
    public static func applicationPDF(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name = name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "application",
            subtype: "pdf",
            parameters: params
        )
    }

    // MARK: Image Types

    /// image/jpeg
    public static let imageJPEG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "jpeg"
    )

    /// Creates image/jpeg with optional name parameter
    public static func imageJPEG(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name = name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "jpeg",
            parameters: params
        )
    }

    /// image/png
    public static let imagePNG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "png"
    )

    /// Creates image/png with optional name parameter
    public static func imagePNG(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name = name {
            params[.init(rawValue: "name")] = name
        }
        return RFC_2045.ContentType(
            __unchecked: (),
            type: "image",
            subtype: "png",
            parameters: params
        )
    }

    /// image/gif
    public static let imageGIF = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "gif"
    )

    /// Creates image/gif with optional name parameter
    public static func imageGIF(name: String? = nil) -> RFC_2045.ContentType {
        var params: [RFC_2045.Parameter.Name: String] = [:]
        if let name = name {
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

// MARK: - Additional Content Types

extension RFC_2045.ContentType {
    // MARK: - Video Types

    /// video/mp4
    public static let videoMP4 = RFC_2045.ContentType(
        __unchecked: (),
        type: "video",
        subtype: "mp4"
    )

    /// video/webm
    public static let videoWebM = RFC_2045.ContentType(
        __unchecked: (),
        type: "video",
        subtype: "webm"
    )

    /// video/ogg
    public static let videoOgg = RFC_2045.ContentType(
        __unchecked: (),
        type: "video",
        subtype: "ogg"
    )

    // MARK: - Audio Types

    /// audio/mpeg (MP3)
    public static let audioMPEG = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "mpeg"
    )

    /// audio/ogg
    public static let audioOgg = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "ogg"
    )

    /// audio/wav
    public static let audioWav = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "wav"
    )

    /// audio/webm
    public static let audioWebM = RFC_2045.ContentType(
        __unchecked: (),
        type: "audio",
        subtype: "webm"
    )

    // MARK: - Image Types

    /// image/webp
    public static let imageWEBP = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "webp"
    )

    /// image/avif
    public static let imageAVIF = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "avif"
    )

    /// image/svg+xml
    public static let imageSVG = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "svg+xml"
    )

    /// image/x-icon (Favicon)
    public static let imageXIcon = RFC_2045.ContentType(
        __unchecked: (),
        type: "image",
        subtype: "x-icon"
    )

    // MARK: - Text Types

    /// text/css
    public static let textCSS = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "css"
    )

    /// text/javascript
    public static let textJavaScript = RFC_2045.ContentType(
        __unchecked: (),
        type: "text",
        subtype: "javascript"
    )

    // MARK: - Application Types

    /// application/json (JSON)
    public static let applicationJSON = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "json"
    )

    /// application/manifest+json (Web App Manifest)
    public static let applicationManifestJSON = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "manifest+json"
    )

    /// application/rss+xml (RSS Feed)
    public static let applicationRSSXML = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "rss+xml"
    )

    /// application/atom+xml (Atom Feed)
    public static let applicationAtomXML = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "atom+xml"
    )

    /// application/x-www-form-urlencoded
    public static let applicationXWWWFormURLEncoded = RFC_2045.ContentType(
        __unchecked: (),
        type: "application",
        subtype: "x-www-form-urlencoded"
    )
}
