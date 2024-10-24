// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Chatto",
    platforms: [.iOS("11.1")],
    products: [
        .library(name: "Chatto", targets: ["Chatto"]),
        .library(name: "ChattoAdditions", targets: ["ChattoAdditions"]),
    ],
    targets: [
        .target(
            name: "Chatto",
            dependencies: [],
            path: "Chatto/sources"),
        .target(
            name: "ChattoAdditions",
            dependencies: ["Chatto"],
            path: "ChattoAdditions/sources"),
    ])
