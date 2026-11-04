import Foundation

enum TestDates {
    static func noonCalendar(at date: Date) -> Calendar {
        var result = calendar("UTC")
        let hour = result.component(.hour, from: date)
        result.timeZone = TimeZone(secondsFromGMT: (12 - hour) * 3600)!
        return result
    }

    static func calendar(_ identifier: String = "Asia/Tokyo") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: identifier)!
        return calendar
    }

    static func date(_ year: Int = 2026, _ month: Int = 11, _ day: Int = 4,
                     _ hour: Int = 0, _ minute: Int = 0, calendar: Calendar = calendar()) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
