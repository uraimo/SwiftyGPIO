import PackageDescription

let package = Package(
    name: "echoServer",
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "echoServer",
            dependencies: ["SwiftyGPIO"])
    ]
)
