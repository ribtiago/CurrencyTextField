// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CurrencyTextField",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CurrencyTextField",
            targets: ["CurrencyTextField"]),
    ],
    targets: [
        .target(
            name: "CurrencyTextField",
            dependencies: [])
    ]
)
