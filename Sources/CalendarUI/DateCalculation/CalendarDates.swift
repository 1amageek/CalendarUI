import Foundation

struct CalendarDates {
    static func configured(timeZone: TimeZone, calendar: Calendar = .autoupdatingCurrent) -> Calendar {
        var result = calendar
        result.timeZone = timeZone
        return result
    }

    static func adding(_ component: Calendar.Component, value: Int, to date: Date, calendar: Calendar) -> Date {
        guard let result = calendar.date(byAdding: component, value: value, to: date) else {
            preconditionFailure("The requested date is outside the calendar's supported range.")
        }
        return result
    }

    static func start(of component: Calendar.Component, for date: Date, calendar: Calendar) -> Date {
        guard let interval = calendar.dateInterval(of: component, for: date) else {
            preconditionFailure("The requested calendar boundary cannot be represented.")
        }
        return interval.start
    }

    static func monthStart(year: Int, month: Int, calendar: Calendar) -> Date {
        precondition((1...12).contains(month), "month must be in 1...12.")
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            preconditionFailure("The requested month cannot be represented.")
        }
        return date
    }

    static func monthDates(year: Int, month: Int, calendar: Calendar) -> [Date] {
        let first = monthStart(year: year, month: month, calendar: calendar)
        let end = adding(.month, value: 1, to: first, calendar: calendar)
        let gridStart = start(of: .weekOfYear, for: first, calendar: calendar)
        guard let finalWeek = calendar.dateInterval(of: .weekOfYear, for: end) else {
            preconditionFailure("The final calendar week cannot be represented.")
        }
        let gridEnd = end == finalWeek.start ? end : finalWeek.end
        // Foundation's sequence excludes its anchor and keeps additions relative to it.
        var dates = [gridStart]
        dates.append(contentsOf: calendar.dates(byAdding: .day, startingAt: gridStart, in: gridStart..<gridEnd))
        return dates
    }

    static func overlaps(start: Date, end: Date, interval: DateInterval) -> Bool {
        start < end && start < interval.end && interval.start < end
    }
}
