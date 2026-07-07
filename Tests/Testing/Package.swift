// swift-tools-version: 6.2

// BLOCKED ON UPSTREAM (dev-only perf harness — not built by CI, never reached by the
// package-root `swift test`): swift-binary-base-primitives (reached transitively via
// swift-testing) still does `import Property_Primitives_Core`, which property-primitives'
// current main removed in the [MOD-017] Core→`Property Primitive` merge. binary-base is
// pushed + read-only, so the fix is tracked separately. The `.timed` Performance suites
// here compile/run once that upstream import is updated to `Property_Primitive`.

import PackageDescription

let package = Package(
    name: "testing",
    platforms: [
        .macOS(.v26)
    ],
    dependencies: [
        .package(path: "../.."),
        .package(url: "https://github.com/swift-foundations/swift-testing.git", branch: "main"),
    ],
    targets: [
        .testTarget(
            name: "RFC 2045 Performance Tests",
            dependencies: [
                .product(name: "RFC 2045", package: "swift-rfc-2045"),
                .product(name: "Testing", package: "swift-testing"),
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

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

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
