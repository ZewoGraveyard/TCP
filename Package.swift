import PackageDescription

let package = Package(
    name: "TCP",
    dependencies: [
        .Package(url: "https://github.com/Zewo/IP.git", majorVersion: 0, minor: 4),
        .Package(url: "https://github.com/Zewo/Stream.git", majorVersion: 0, minor: 4),
    ]
)
