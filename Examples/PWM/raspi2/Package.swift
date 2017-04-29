import PackageDescription

let package = Package(
    name: "PWM",
    dependencies: [
        .Package(url: "https://github.com/uraimo/SwiftyGPIO.git", majorVersion: 0),
    ]
)
