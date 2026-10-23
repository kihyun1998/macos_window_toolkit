// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "file_selector_ios", path: "../.packages/file_selector_ios-0.5.3+2"),
        .package(name: "integration_test", path: "../.packages/integration_test"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "file-selector-ios", package: "file_selector_ios"),
                .product(name: "integration-test", package: "integration_test"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
