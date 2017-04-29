import PackageDescription

let package = Package(
    name: "PWMPattern",
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
    ]
)
