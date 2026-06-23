// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-2045",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "RFC 2045",
            targets: ["RFC 2045"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-ascii-serializer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-incits/swift-incits-4-1986.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5322.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-standard-library-extensions.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-format-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-serializer-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-parser-primitives.git", branch: "main")
    ],
    targets: [
        .target(
            name: "RFC 2045",
            dependencies: [
                .product(name: "ASCII Serializer Primitives", package: "swift-ascii-serializer-primitives"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "Standard Library Extensions", package: "swift-standard-library-extensions"),
                .product(name: "Format Primitives", package: "swift-format-primitives"),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Binary Serializable Primitives", package: "swift-binary-serializer-primitives"),
                .product(name: "Parser Primitives", package: "swift-parser-primitives")
            ]
        ),
        .testTarget(
            name: "RFC 2045 Tests",
            dependencies: [
                "RFC 2045",
                .product(name: "Format Primitives", package: "swift-format-primitives"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
