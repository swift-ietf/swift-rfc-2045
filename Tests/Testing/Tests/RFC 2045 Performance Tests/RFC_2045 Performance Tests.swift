// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-rfc-2045 open source project
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// RFC 2045 Performance Tests
//
// Isolated in a nested SPM package per [TEST-024]/[INST-TEST]: the `.timed`
// trait lives in swift-testing's `Testing` product, which cannot be added to
// the main test target without risking a circular dependency.

import Testing

@testable import RFC_2045

@Suite
struct `ContentType - Performance` {
    @Test(.timed(threshold: .milliseconds(1000)))
    func `parse 10K content types`() throws {
        for _ in 0..<10_000 {
            _ = try RFC_2045.ContentType("text/html; charset=UTF-8")
        }
    }

    @Test(.timed(threshold: .milliseconds(1000)))
    func `serialize 10K content types`() {
        let ct = RFC_2045.ContentType.textHTMLUTF8
        for _ in 0..<10_000 {
            _ = [Byte](ct)
        }
    }
}

@Suite
struct `Charset - Performance` {
    @Test(.timed(threshold: .milliseconds(500)))
    func `parse 100K charsets`() throws {
        for _ in 0..<100_000 {
            _ = try RFC_2045.Charset(ascii: Array<Byte>("UTF-8".utf8))
        }
    }

    @Test(.timed(threshold: .milliseconds(500)))
    func `serialize 100K charsets`() {
        let charset = RFC_2045.Charset.utf8
        for _ in 0..<100_000 {
            _ = [Byte](charset)
        }
    }
}

@Suite
struct `ContentTransferEncoding - Performance` {
    @Test(.timed(threshold: .milliseconds(1000)))
    func `parse 100K encodings`() throws {
        for _ in 0..<100_000 {
            _ = try RFC_2045.ContentTransferEncoding("base64")
        }
    }

    @Test(.timed(threshold: .milliseconds(500)))
    func `serialize 100K encodings`() {
        let encoding = RFC_2045.ContentTransferEncoding.base64
        for _ in 0..<100_000 {
            _ = [Byte](encoding)
        }
    }
}

@Suite
struct `Parameter.Name - Performance` {
    @Test(.timed(threshold: .milliseconds(500)))
    func `parse 100K names`() throws {
        for _ in 0..<100_000 {
            _ = try RFC_2045.Parameter.Name(ascii: Array<Byte>("charset".utf8))
        }
    }

    @Test(.timed(threshold: .milliseconds(500)))
    func `serialize 100K names`() {
        let name = RFC_2045.Parameter.Name.charset
        for _ in 0..<100_000 {
            _ = [Byte](name)
        }
    }
}
