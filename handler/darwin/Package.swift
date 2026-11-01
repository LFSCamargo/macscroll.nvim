// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "macscroll",
  platforms: [.macOS(.v13)],
  products: [
    .library(name: "MacscrollCore", targets: ["MacscrollCore"]),
    .executable(name: "macscroll-worker", targets: ["MacscrollWorker"]),
    .executable(name: "MacscrollCoreTests", targets: ["MacscrollCoreTests"]),
  ],
  targets: [
    .target(name: "MacscrollCore"),
    .executableTarget(
      name: "MacscrollWorker",
      dependencies: ["MacscrollCore"]
    ),
    .executableTarget(
      name: "MacscrollCoreTests",
      dependencies: ["MacscrollCore"],
      path: "Tests/MacscrollCoreTests"
    ),
  ]
)
