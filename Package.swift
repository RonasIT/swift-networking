// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Networking",
    products: [
        .library(name: "Networking", targets: ["Networking"])
    ],
    targets: [
        .target(name: "Networking", path: "Sources")
    ]
)
