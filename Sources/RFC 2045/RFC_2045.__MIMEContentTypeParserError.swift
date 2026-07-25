//
//  RFC_2045.__MIMEContentTypeParserError.swift
//  swift-rfc-2045
//
//  Module-scope, non-generic error for the MIME content-type parser.
//
//  Hoisted out of the generic `RFC_2045.ContentType.Parse<Input>` namespace so
//  the `@error` SIL result carries no phantom `Input` type parameter — the
//  structural fix for the `FunctionSignatureOpts` release-build ICE
//  (`SILArgument.cpp:40 !type.hasTypeParameter()`; swiftlang/swift#89617,
//  [API-ERR-009]). Surfaced through `RFC_2045.ContentType.Parse.Error`.
//

/// Errors that can occur when parsing a MIME content-type.
public enum __MIMEContentTypeParserError: Swift.Error, Sendable, Equatable {
    /// The type or subtype portion is not a valid token.
    case expectedToken
    /// Expected a solidus between type and subtype.
    case expectedSolidus
}
