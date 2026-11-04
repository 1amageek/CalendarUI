import SwiftUI
import Testing
@testable import CalendarUI

@MainActor struct DayCalendarTests {
    @Test func dateBindingsUseRequestedTimeZoneAndPreserveWeekday() {
        let calendar = TestDates.calendar("Pacific/Kiritimati")
        var selected = TestDates.date(2026, 11, 4, 15, calendar: calendar)
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let view = DayCalendar(binding, timeZone: calendar.timeZone, data: [TestEvent](), id: \.id,
                               content: { _, _ in Color.clear }, placeholder: { _ in Color.clear }, day: { _ in Color.clear })
        #expect(view.selectedDay.wrappedValue == calendar.startOfDay(for: selected))
        let previousWeekday = calendar.component(.weekday, from: selected)
        let target = CalendarDates.adding(.weekOfYear, value: 3, to: view.selectedWeek.wrappedValue, calendar: calendar)
        view.selectedWeek.wrappedValue = target
        #expect(calendar.component(.weekday, from: selected) == previousWeekday)
        #expect(view.selectedWeek.wrappedValue == target)
    }
}
