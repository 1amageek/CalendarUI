import SwiftUI
import Testing
@testable import CalendarUI

@MainActor struct MonthCalendarTests {
    @Test func bothInitializersRetainRequestedTimeZone() {
        let zone = TestDates.calendar().timeZone
        let withHeader = MonthCalendar(year: 2026, month: 11, timeZone: zone, content: { _ in Color.clear }, header: { _ in Color.clear })
        let withoutHeader = MonthCalendar(year: 2026, month: 11, timeZone: zone) { _ in Color.clear }
        let expected = CalendarDates.monthDates(year: 2026, month: 11, calendar: withHeader.calendar)
        #expect(withHeader.calendar.timeZone == zone)
        #expect(withHeader.dates == expected)
        #expect(withoutHeader.dates == expected)
        #expect(withHeader.dates.allSatisfy { withHeader.calendar.component(.hour, from: $0) == 0 })
    }
}
