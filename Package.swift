// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Still", platforms: [.macOS(.v13), .iOS(.v17)], products: [.library(name: "StillCore", targets: ["StillCore"])], targets: [.target(name: "StillCore"), .testTarget(name: "StillCoreTests", dependencies: ["StillCore"])])
