// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CalendarUI",
    platforms: [.iOS("27.0"), .macOS("27.0"), .watchOS("27.0"), .tvOS("27.0")],
    products: [
        .library(name: "CalendarUI", targets: ["CalendarUI"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CalendarUI",
            dependencies: [],
            exclude: ["DESIGN.md", "DateCalculation/DESIGN.md", "MonthCalendar/DESIGN.md", "WeekCalendar/DESIGN.md", "DayCalendar/DESIGN.md", "TimeCalendar/DESIGN.md"]),
        .testTarget(
            name: "CalendarUITests",
            dependencies: ["CalendarUI"]),
    ]
)
