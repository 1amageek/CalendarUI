// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CalendarUI",
    platforms: [.iOS(.v15), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "CalendarUI", targets: ["CalendarUI"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CalendarUI",
            dependencies: []),
        .testTarget(
            name: "CalendarUITests",
            dependencies: ["CalendarUI"]),
    ]
)
