import PackageDescription

let package = Package(
    name: "CustomGPIO",
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
    ]
)
