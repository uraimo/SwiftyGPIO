import PackageDescription

let package = Package(
    name: "BasicGPIO",
    dependencies: [
        .Package(url: "https://github.com/eugeniobaglieri/SwiftyGPIO.git", majorVersion: 0),
    ]
)
