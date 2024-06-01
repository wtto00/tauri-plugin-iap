// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "tauri-iap",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "tauri-iap",
      type: .static,
      targets: ["tauri-iap"]
    )
  ],
  dependencies: [],
  targets: [
    .target(
      name: "tauri-iap",
      dependencies: [],
      linkerSettings: [
        .linkedFramework("StoreKit")
      ]
    )
  ]
)
