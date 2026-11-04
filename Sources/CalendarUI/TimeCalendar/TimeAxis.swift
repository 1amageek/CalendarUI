import Foundation
import CoreGraphics

struct TimeAxis: Hashable {
    let calendar: Calendar
    let range: ClosedRange<Int>
    let minuteInterval: Int
    let period: DateInterval
    let slots: [DateInterval]

    init(date: Date, range: ClosedRange<Int>, minuteInterval: Int, calendar: Calendar) {
        precondition(0 <= range.lowerBound && range.lowerBound < range.upperBound && range.upperBound <= 24,
                     "The hour range must satisfy 0 <= lower < upper <= 24.")
        precondition((1...1440).contains(minuteInterval), "minuteInterval must be in 1...1440.")
        let day = CalendarDates.start(of: .day, for: date, calendar: calendar)
        let nextDay = CalendarDates.adding(.day, value: 1, to: day, calendar: calendar)
        func boundary(_ hour: Int) -> Date {
            if hour == 24 { return nextDay }
            guard let instant = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) else {
                preconditionFailure("The requested hour cannot be represented.")
            }
            return instant
        }
        let start = boundary(range.lowerBound)
        let end = boundary(range.upperBound)
        precondition(start < end, "The requested hours must define a nonempty time interval.")
        self.calendar = calendar
        self.range = range
        self.minuteInterval = minuteInterval
        self.period = DateInterval(start: start, end: end)
        var slots: [DateInterval] = []
        var cursor = start
        while cursor < end {
            let slotEnd = min(cursor.addingTimeInterval(Double(minuteInterval) * 60), end)
            slots.append(DateInterval(start: cursor, end: slotEnd))
            cursor = slotEnd
        }
        self.slots = slots
    }

    func offset(for instant: Date, height: CGFloat) -> CGFloat {
        CGFloat(instant.timeIntervalSince(period.start) / period.duration) * height
    }

    func visiblePeriod(start: Date, end: Date) -> DateInterval? {
        guard CalendarDates.overlaps(start: start, end: end, interval: period) else { return nil }
        return DateInterval(start: max(start, period.start), end: min(end, period.end))
    }

    func scrollTarget(now: Date) -> Date {
        guard calendar.isDate(now, inSameDayAs: period.start) else { return period.start }
        // This always identifies a rendered slot, independently of event identifiers.
        let elapsed = now.timeIntervalSince(period.start)
        let index = max(0, min(slots.count - 1, Int(floor(elapsed / Double(minuteInterval * 60)))))
        return slots[index].start
    }

    var hourMarks: [Date] {
        var result: [Date] = []
        var cursor = period.start
        while cursor < period.end {
            result.append(cursor)
            cursor = CalendarDates.adding(.hour, value: 1, to: cursor, calendar: calendar)
        }
        result.append(period.end)
        return result
    }
}
