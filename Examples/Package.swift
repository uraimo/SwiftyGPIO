import PackageDescription

let package = Package(
    name: "GPIOTest",
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
    ]
)
