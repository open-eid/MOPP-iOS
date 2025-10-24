// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "SetupConfiguration",
    platforms: [.macOS(.v11)],
    products: [.executable(name: "SetupConfiguration", targets: ["SetupConfiguration"])],
    dependencies: [],
    targets: [.target(name: "SetupConfiguration", dependencies: [], path: "Sources")],
)
