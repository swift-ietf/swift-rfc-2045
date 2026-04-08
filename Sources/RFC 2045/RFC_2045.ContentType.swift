//
//  RFC_2045.ContentType.swift
//  swift-rfc-2045
//
//  Created by Coen ten Thije Boonkkamp on 19/11/2025.
//

public import ASCII_Serializer_Primitives
public import INCITS_4_1986

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

extension [UInt8] {
    public init(
        _ contentType: RFC_2045.ContentType.Type
    ) {
        self = Array("Content-Type".utf8)
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

extension RFC_2045.ContentType: Binary.ASCII.Serializable {
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii contentType: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        // type/subtype
        buffer.append(contentsOf: contentType.type.utf8)
        buffer.append(.ascii.solidus)
        buffer.append(contentsOf: contentType.subtype.utf8)

        // parameters: ; name=value
        for (name, value) in contentType.parameters {
            buffer.append(.ascii.semicolon)
            buffer.append(.ascii.space)
            buffer.append(contentsOf: name.rawValue.utf8)
            buffer.append(.ascii.equalsSign)
            buffer.append(contentsOf: value.utf8)
        }
    }

    /// Parses a Content-Type header from canonical byte representation (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 2045 MIME headers are pure ASCII, so this parser operates on ASCII bytes.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_2045.ContentType (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [UInt8] (UTF-8 bytes) → ContentType
    /// ```
    ///
    /// ## Example
    ///
    /// ```swift
    /// let bytes = Array("text/html; charset=UTF-8".utf8)
    /// let contentType = try RFC_2045.ContentType(ascii: bytes)
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the header value
    /// - Throws: `RFC_2045.ContentType.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes, in context: Void) throws(Error)
    where Bytes.Element == UInt8 {
        let byteArray = Array(bytes)

        guard !byteArray.isEmpty else {
            throw Error.empty
        }

        // Split on first semicolon to separate type/subtype from parameters
        let typeSubtypeBytes: ArraySlice<UInt8>
        let parametersBytes: ArraySlice<UInt8>?

        if let firstSemicolon = byteArray.firstIndex(of: .ascii.semicolon) {
            typeSubtypeBytes = byteArray[..<firstSemicolon]
            parametersBytes = byteArray[(firstSemicolon + 1)...]
        } else {
            typeSubtypeBytes = byteArray[...]
            parametersBytes = nil
        }

        // Parse type/subtype
        guard let solidus = typeSubtypeBytes.firstIndex(of: .ascii.solidus) else {
            throw Error.missingSeparator(String(decoding: byteArray, as: UTF8.self))
        }

        let typeBytes = typeSubtypeBytes[..<solidus].trimming(.ascii.whitespaces)
        let subtypeBytes = typeSubtypeBytes[(solidus + 1)...].trimming(.ascii.whitespaces)

        guard !typeBytes.isEmpty else {
            throw Error.emptyType(String(decoding: byteArray, as: UTF8.self))
        }

        guard !subtypeBytes.isEmpty else {
            throw Error.emptySubtype(String(decoding: byteArray, as: UTF8.self))
        }

        let type = String(decoding: typeBytes, as: UTF8.self).lowercased()
        let subtype = String(decoding: subtypeBytes, as: UTF8.self).lowercased()

        // Parse parameters if present
        var params: [RFC_2045.Parameter.Name: String] = [:]

        if let parametersBytes = parametersBytes {
            let pBytes = Array(parametersBytes)
            var segStart = 0

            func processParam(_ lo: Int, _ hi: Int) {
                let segment = pBytes[lo..<hi]
                guard let equalsIndex = segment.firstIndex(of: .ascii.equalsSign) else {
                    return
                }

                let keyBytes = segment[..<equalsIndex].ascii.trimming(.ascii.whitespaces)
                var valueBytes = Array(
                    segment[(equalsIndex &+ 1)...].ascii.trimming(.ascii.whitespaces)
                )

                guard !keyBytes.isEmpty else {
                    return
                }

                // Handle quoted values - remove surrounding quotes if present
                let isQuoted =
                    valueBytes.first == .ascii.quotationMark
                    && valueBytes.last == .ascii.quotationMark
                if isQuoted {
                    valueBytes = Array(valueBytes.dropFirst().dropLast())
                }

                let key = RFC_2045.Parameter.Name(
                    rawValue: String(decoding: keyBytes, as: UTF8.self).lowercased()
                )
                let value = String(decoding: valueBytes, as: UTF8.self)

                params[key] = value
            }

            for idx in 0..<pBytes.count {
                if pBytes[idx] == UInt8.ascii.semicolon {
                    processParam(segStart, idx)
                    segStart = idx &+ 1
                }
            }
            processParam(segStart, pBytes.count)
        }

        self.init(__unchecked: (), type: type, subtype: subtype, parameters: params)
    }
}

// MARK: - Byte Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 2045 ContentType
    ///
    /// This is the canonical serialization of MIME Content-Type headers to bytes.
    /// RFC 2045 MIME headers are ASCII-only by definition.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_2045.ContentType (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// ContentType → [UInt8] (ASCII) → String (UTF-8 interpretation)
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
    /// let bytes = [UInt8](contentType)
    /// // bytes represents "text/plain; charset=UTF-8" as ASCII bytes
    /// ```
    ///
    /// - Parameter contentType: The content type to serialize
    public init(_ contentType: RFC_2045.ContentType) {
        self = []

        // Estimate capacity: type + "/" + subtype + parameters
        let estimatedCapacity =
            contentType.type.count + 1 + contentType.subtype.count
            + (contentType.parameters.count * 30)  // ~30 bytes per parameter
        self.reserveCapacity(estimatedCapacity)

        // Append type/subtype
        self.append(contentsOf: contentType.type.utf8)
        self.append(.ascii.solidus)  // "/"
        self.append(contentsOf: contentType.subtype.utf8)

        // Append parameters in sorted order for consistency
        for (key, value) in contentType.parameters.sorted(by: { $0.key < $1.key }) {
            self.append(.ascii.semicolon)  // ";"
            self.append(.ascii.space)
            self.append(contentsOf: key.storage.value.lowercased().utf8)
            self.append(.ascii.equalsSign)  // "="

            // Quote value if it contains special characters per RFC 2045 Section 5.1
            let needsQuoting = value.contains(where: {
                $0.ascii.isWhitespace || "()<>@,;:\\\"/[]?=".contains($0)
            })

            if needsQuoting {
                self.append(.ascii.quotationMark)  // "\""
                self.append(contentsOf: value.utf8)
                self.append(.ascii.quotationMark)  // "\""
            } else {
                self.append(contentsOf: value.utf8)
            }
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_2045.ContentType: Binary.ASCII.RawRepresentable {
    public typealias RawValue = String
}
extension RFC_2045.ContentType: CustomStringConvertible {}

// MARK: - Computed Properties

extension RFC_2045.ContentType {
    /// The complete header value
    ///
    /// Example: `"text/html; charset=UTF-8"`
    public var headerValue: String {
        String(self)
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
