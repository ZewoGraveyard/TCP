import PackageDescription

let package = Package(
    name: "TCP",
    dependencies: [
        .Package(url: "https://github.com/tomohisa/IP.git", majorVersion: 0, minor: 7),
    ]
)
