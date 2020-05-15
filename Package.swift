// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Chatto",
    platforms: [.iOS("9.0")],
    products: [
        .library(name: "Chatto", targets: ["Chatto"]),
        .library(name: "ChattoAdditions", targets: ["ChattoAdditions"]),
    ],
    targets: [
        // Chatto
        .target(
            name: "Chatto",
            path: "Chatto/Source"
        ),
        /*
        .testTarget(
            name: "ChattoTests",
            dependencies: ["Chatto"]
        ),
        */

        // ChattoAdditions
        .target(
            name: "ChattoAdditions",
            dependencies: ["Chatto"],
            path: "ChattoAdditions/Source"
        ),
        /*
        .testTarget(
            name: "ChattoAdditionsTests",
            dependencies: ["ChattoAdditions"]
        ),
        */
    ]
)
