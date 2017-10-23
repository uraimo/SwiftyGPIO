import PackageDescription

let package = Package(
    name: "OneWire",
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
    ]
)
