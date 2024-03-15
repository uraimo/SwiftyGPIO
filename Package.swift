// swift-tools-version:5.1

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
        .target(
            name: "SwiftyGPIO",
            path: "Sources"
        )
    ]
)
