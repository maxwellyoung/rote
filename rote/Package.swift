// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "rote",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "rote",
            targets: ["rote"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0")
    ],
    targets: [
        .target(
            name: "rote",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ]),
        .testTarget(
            name: "roteTests",
            dependencies: ["rote"]),
    ]
) 