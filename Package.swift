// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Networking",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v11),
        .watchOS(.v4)
    ],
    products: [
        .library(name: "Networking", targets: ["Networking"])
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(name: "Networking", dependencies: ["Alamofire"], path: "Sources")
    ]
)
