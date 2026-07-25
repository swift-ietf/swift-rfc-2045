//
//  RFC_2045.__MIMETokenParserError.swift
//  swift-rfc-2045
//
//  Module-scope, non-generic error for the MIME token parser.
//
//  Hoisted out of the generic `RFC_2045.Parse.Token<Input>` namespace so the
//  `@error` SIL result carries no phantom `Input` type parameter — the structural
//  fix for the `FunctionSignatureOpts` release-build ICE
//  (`SILArgument.cpp:40 !type.hasTypeParameter()`; swiftlang/swift#89617,
//  [API-ERR-009]). Surfaced through `RFC_2045.Parse.Token.Error` (a typealias).
//

/// Errors that can occur when parsing a MIME token.
public enum __MIMETokenParserError: Swift.Error, Sendable, Equatable {
    /// Input does not begin with a valid token character.
    case expectedToken
}
