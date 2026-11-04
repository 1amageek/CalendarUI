import Testing
@testable import CalendarUI

struct CalendarDatesTests {
    @Test(arguments: ["Asia/Tokyo", "America/Los_Angeles", "Pacific/Kiritimati", "UTC"])
    func monthGridCoversCompleteWeeks(timeZone: String) {
        let calendar = TestDates.calendar(timeZone)
        for month in 1...12 {
            let dates = CalendarDates.monthDates(year: 2026, month: month, calendar: calendar)
            #expect((28...42).contains(dates.count))
            #expect(dates.count % 7 == 0)
            #expect(dates.first == calendar.dateInterval(of: .weekOfYear, for: TestDates.date(2026, month, 1, calendar: calendar))?.start)
            for pair in zip(dates, dates.dropFirst()) {
                #expect(calendar.date(byAdding: .day, value: 1, to: pair.0) == pair.1)
            }
            let days = dates.filter { calendar.component(.month, from: $0) == month }
            #expect(days.count == calendar.range(of: .day, in: .month, for: TestDates.date(2026, month, 1, calendar: calendar))?.count)
        }
    }
}
