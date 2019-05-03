// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "I2C",
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "I2C",
            dependencies: ["SwiftyGPIO"],
            sources: ["Sources"])
    ]
)