import PackageDescription

let package = Package(
    name: "BasicGPIO",
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
    ]
)
