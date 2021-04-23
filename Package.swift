// swift-tools-version:5.2
import PackageDescription

let package = Package(
  name: "URLProtocolHelpers",
  products: [
    .library(name: "URLProtocolHelpers", targets: ["URLProtocolHelpers"]),
  ],
  targets: [
    .target(name: "URLProtocolHelpers"),
    .testTarget(name: "URLProtocolHelpersTests", dependencies: ["URLProtocolHelpers"]),
  ]
)
