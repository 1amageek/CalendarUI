import Testing
@testable import CalendarUI

struct TimeCalendarTests {
    @Test func singleSlotIncludesFirstAndLastBoundaries() {
        let calendar = TestDates.calendar()
        let axis = TimeAxis(date: TestDates.date(), range: 8...9, minuteInterval: 1440, calendar: calendar)
        #expect(axis.slots == [axis.period])
        #expect(axis.hourMarks == [axis.period.start, axis.period.end])
        #expect(axis.scrollTarget(now: TestDates.date(2026, 11, 4, 8, 30)) == axis.period.start)
    }

    @Test func repeatedHourRetainsSeparateInstantsAndCoordinates() {
        let calendar = TestDates.calendar("America/Los_Angeles")
        let date = TestDates.date(2026, 11, 1, calendar: calendar)
        let axis = TimeAxis(date: date, range: 0...24, minuteInterval: 60, calendar: calendar)
        let repeated = axis.hourMarks.filter { calendar.component(.hour, from: $0) == 1 }
        #expect(repeated.count == 2)
        guard repeated.count == 2 else { return }
        #expect(repeated[1].timeIntervalSince(repeated[0]) == 3600)
        #expect(axis.offset(for: repeated[1], height: 2500) - axis.offset(for: repeated[0], height: 2500) == 100)
        #expect(axis.slots.map(\.start).contains(repeated[0]))
        #expect(axis.slots.map(\.start).contains(repeated[1]))
    }

    @Test func currentTimeAndEventsShareTheVisibleAxis() {
        let calendar = TestDates.calendar()
        let axis = TimeAxis(date: TestDates.date(), range: 8...20, minuteInterval: 15, calendar: calendar)
        let noon = TestDates.date(2026, 11, 4, 12)
        #expect(axis.offset(for: noon, height: 1200) == 400)
        #expect(axis.offset(for: axis.period.start, height: 1200) == 0)
        #expect(axis.offset(for: axis.period.end, height: 1200) == 1200)
        #expect(axis.slots.count == 48)
        #expect(axis.hourMarks.count == 13)
    }

    @Test func clippedAndInvalidEventPeriods() {
        let axis = TimeAxis(date: TestDates.date(), range: 8...20, minuteInterval: 15, calendar: TestDates.calendar())
        let clipped = axis.visiblePeriod(start: TestDates.date(2026, 11, 3, 23), end: TestDates.date(2026, 11, 4, 9))
        #expect(clipped?.start == axis.period.start)
        #expect(clipped?.duration == 3600)
        #expect(axis.visiblePeriod(start: axis.period.end, end: axis.period.end.addingTimeInterval(60)) == nil)
        #expect(axis.visiblePeriod(start: axis.period.start, end: axis.period.start) == nil)
        #expect(axis.visiblePeriod(start: axis.period.end, end: axis.period.start) == nil)
    }

    @Test func scrollTargetsAlwaysExistWithoutEvents() {
        let axis = TimeAxis(date: TestDates.date(), range: 8...20, minuteInterval: 17, calendar: TestDates.calendar())
        for hour in 0...23 {
            let target = axis.scrollTarget(now: TestDates.date(2026, 11, 4, hour, 43))
            #expect(axis.slots.contains { $0.start == target })
        }
        #expect(axis.slots.last?.end == axis.period.end)
        #expect(axis.scrollTarget(now: TestDates.date(2026, 11, 5, 12)) == axis.period.start)
    }

    @Test(arguments: [(3, 8, 23), (11, 1, 25)])
    func daylightSavingDaysRetainEveryInstant(month: Int, day: Int, hours: Int) {
        let calendar = TestDates.calendar("America/Los_Angeles")
        let axis = TimeAxis(date: TestDates.date(2026, month, day, calendar: calendar), range: 0...24, minuteInterval: 15, calendar: calendar)
        #expect(axis.period.duration == Double(hours * 3600))
        #expect(axis.slots.count == hours * 4)
        #expect(axis.hourMarks.count == hours + 1)
        #expect(axis.slots.reduce(0) { $0 + $1.duration } == axis.period.duration)
    }
}
