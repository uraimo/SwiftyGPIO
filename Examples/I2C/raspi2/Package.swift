// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "I2CDetect",
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "I2CDetect",
            dependencies: ["SwiftyGPIO"])
    ]
)
