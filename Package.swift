// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SwiftyGPIO",
    products: [
        .library(
            name: "SwiftyGPIO",
            targets: ["SwiftyGPIO"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "SwiftyGPIO"),
        .testTarget(
            name: "SwiftyGPIOTests",
            dependencies: ["SwiftyGPIO"]),
    ]
)
