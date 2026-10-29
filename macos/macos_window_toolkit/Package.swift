// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "macos_window_toolkit",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "macos-window-toolkit", targets: ["macos_window_toolkit"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "macos_window_toolkit",
      dependencies: []
    )
  ]
)
