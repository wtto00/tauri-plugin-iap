// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "TauriIAP",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "TauriIAP",
      type: .static,
      targets: ["TauriIAP"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/Brendonovich/swift-rs", from: "1.0.6")
  ],
  targets: [
    .target(
      name: "TauriIAP",
      dependencies: [.product(name: "SwiftRs", package: "swift-rs")],
      path: "",
      linkerSettings: [
        .linkedFramework("StoreKit")
      ]
    )
  ]
)
