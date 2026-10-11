// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Macousel",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "StripCore", targets: ["StripCore"]),
    .library(name: "WindowSystem", targets: ["WindowSystem"]),
  ],
  targets: [
    .target(
      name: "StripCore",
      path: "sources/strip-core"
    ),
    .target(
      name: "WindowSystem",
      path: "sources/window-system",
      swiftSettings: [.defaultIsolation(MainActor.self)]
    ),
    .executableTarget(
      name: "Macousel",
      dependencies: ["StripCore", "WindowSystem"],
      path: "sources/macousel",
      swiftSettings: [.defaultIsolation(MainActor.self)]
    ),
    .testTarget(name: "StripCoreTests", dependencies: ["StripCore"], path: "tests/strip-core-tests"),
    .testTarget(name: "MacouselTests", dependencies: ["Macousel"], path: "tests/macousel-tests"),
  ]
)
