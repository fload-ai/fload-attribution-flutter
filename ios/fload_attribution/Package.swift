// swift-tools-version: 5.9

import PackageDescription

// The Fload iOS SDK's sources are vendored byte for byte under
// Sources/fload_attribution/Vendor (scripts/vendor-ios-sdk.sh), so this
// package and the CocoaPods podspec build exactly the same code.
let package = Package(
    name: "fload_attribution",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "fload-attribution", targets: ["fload_attribution"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "fload_attribution",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            exclude: [
                "Vendor/FloadAttribution/VENDORED.txt"
            ],
            resources: [
                .copy("Vendor/FloadAttribution/Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
