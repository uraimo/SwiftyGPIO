import PackageDescription

let package = Package(
    name: "I2C",
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
    ]
)
