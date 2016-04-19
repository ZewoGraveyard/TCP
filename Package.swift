import PackageDescription

let package = Package(
    name: "TCP",
    dependencies: [
        .Package(url: "https://github.com/VeniceX/IP.git", majorVersion: 0, minor: 5),
    ]
)
