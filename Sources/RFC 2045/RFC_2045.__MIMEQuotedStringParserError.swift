//
//  RFC_2045.__MIMEQuotedStringParserError.swift
//  swift-rfc-2045
//
//  Module-scope, non-generic error for the MIME quoted-string parser.
//
//  Hoisted out of the generic `RFC_2045.Parse.QuotedString<Input>` namespace so
//  the `@error` SIL result carries no phantom `Input` type parameter — the
//  structural fix for the `FunctionSignatureOpts` release-build ICE
//  (`SILArgument.cpp:40 !type.hasTypeParameter()`; swiftlang/swift#89617,
//  [API-ERR-009]). Surfaced through `RFC_2045.Parse.QuotedString.Error`.
//

/// Errors that can occur when parsing a MIME quoted-string.
public enum __MIMEQuotedStringParserError: Swift.Error, Sendable, Equatable {
    /// Input does not begin with an opening double-quote.
    case expectedQuote
    /// Input ended before the closing double-quote was found.
    case unterminatedString
}
