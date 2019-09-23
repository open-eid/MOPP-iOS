// swift-tools-version:4.2
import PackageDescription

let package = Package(name: "SetupConfiguration")

package.products = [
    .executable(name: "SetupConfiguration", targets: ["SetupConfiguration"])
]
package.dependencies = [

]
package.targets = [
    .target(name: "SetupConfiguration", dependencies: [], path: "Sources")
]
