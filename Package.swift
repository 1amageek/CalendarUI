// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CalendarUI",
    platforms: [.iOS(.v16), .macOS(.v12), .watchOS(.v8), .tvOS(.v15)],
    products: [
        .library(name: "CalendarUI", targets: ["CalendarUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1amageek/PageView.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "CalendarUI",
            dependencies: ["PageView"]),
        .testTarget(
            name: "CalendarUITests",
            dependencies: ["CalendarUI"]),
    ]
)
