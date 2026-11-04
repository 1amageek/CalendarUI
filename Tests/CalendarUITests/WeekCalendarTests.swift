import SwiftUI
import Testing
@testable import CalendarUI

struct WeekCalendarTests {
    @Test func partialFinalSectionsAreIncluded() {
        let interval = Interval.hour(5)
        #expect((0..<interval.countOfSection).map { interval.time(at: $0).hour } == [0, 5, 10, 15, 20])
        let minutes = Interval.minute(120)
        #expect(minutes.countOfSection == 12)
        #expect(minutes.time(at: 11).hour == 22)
        let seconds = Interval.second(59)
        #expect(seconds.countOfSection == 1465)
        #expect(seconds.time(at: seconds.countOfSection - 1).hour == 23)
    }

    @Test func largeIntervalsDoNotOverflow() {
        for interval in [Interval.hour(Int.max), .minute(Int.max), .second(Int.max)] {
            #expect(interval.countOfSection == 1)
            let time = interval.time(at: 0)
            #expect(time.hour == 0 && time.minute == 0 && time.second == 0)
        }
    }

    @Test @MainActor func initializerVariantsUseIdenticalWeeks() {
        let zone = TestDates.calendar().timeZone
        let full = WeekCalendar(year: 2026, month: 11, weekOfMonth: 2, timeZone: zone,
                                content: { _ in Color.clear }, header: { _ in Color.clear }, ruler: { _, _, _ in Color.clear })
        let header = WeekCalendar(year: 2026, month: 11, weekOfMonth: 2, timeZone: zone,
                                  content: { _ in Color.clear }, header: { _ in Color.clear })
        let plain = WeekCalendar(year: 2026, month: 11, weekOfMonth: 2, timeZone: zone) { _ in Color.clear }
        #expect(full.startWeekOfYear == header.startWeekOfYear)
        #expect(full.startWeekOfYear == plain.startWeekOfYear)
        #expect(full.calendar.component(.hour, from: full.startWeekOfYear) == 0)
    }
}
