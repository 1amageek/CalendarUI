import Foundation
import Testing
@testable import CalendarUI

struct FoundationIntegrationTests {
    @Test(arguments: [(2024, 2, 29), (2026, 2, 28), (2026, 12, 31), (2027, 1, 31)])
    func monthGridsMatchFoundationDateSequences(year: Int, month: Int, days: Int) throws {
        for firstWeekday in [1, 2] {
            var calendar = TestDates.calendar("America/Los_Angeles")
            calendar.firstWeekday = firstWeekday
            let date = TestDates.date(year, month, 1, calendar: calendar)
            let monthPeriod = try #require(calendar.dateInterval(of: .month, for: date))
            let gridStart = try #require(calendar.dateInterval(of: .weekOfYear, for: monthPeriod.start)?.start)
            let gridEnd = try #require(calendar.dateInterval(of: .weekOfYear, for: monthPeriod.end.addingTimeInterval(-1))?.end)
            let expected = [gridStart] + calendar.dates(byAdding: .day, startingAt: gridStart, in: gridStart..<gridEnd)
            let actual = CalendarDates.monthDates(year: year, month: month, calendar: calendar)
            #expect(actual == expected)
            #expect(actual.filter { monthPeriod.start <= $0 && $0 < monthPeriod.end }.count == days)
        }
    }

    @Test(arguments: [("America/Los_Angeles", 3, 8), ("America/Los_Angeles", 11, 1),
                      ("Australia/Lord_Howe", 10, 4), ("Australia/Lord_Howe", 4, 5)])
    func timelineEnumerationMatchesFoundationAcrossClockChanges(zone: String, month: Int, day: Int) {
        let calendar = TestDates.calendar(zone)
        let date = TestDates.date(2026, month, day, calendar: calendar)
        let axis = TimeAxis(date: date, range: 0...24, minuteInterval: 17, calendar: calendar)
        let bounds = axis.period.start..<axis.period.end
        let expectedStarts = [bounds.lowerBound] + calendar.dates(byAdding: .minute, value: 17, startingAt: bounds.lowerBound, in: bounds)
        #expect(axis.slots.map(\.start) == expectedStarts)
        #expect(axis.slots.last?.end == bounds.upperBound)
        #expect(axis.slots.allSatisfy { $0.duration > 0 && $0.duration <= 17 * 60 })
        for pair in zip(axis.slots, axis.slots.dropFirst()) {
            #expect(pair.0.end == pair.1.start)
        }
        let expectedHours = [bounds.lowerBound] + calendar.dates(byAdding: .hour, startingAt: bounds.lowerBound, in: bounds) + [bounds.upperBound]
        #expect(axis.hourMarks == expectedHours)
    }

    @Test(arguments: [(3, 7, 23), (10, 31, 25)])
    func standardDailyRecurrencesKeepTheirTimelinePosition(month: Int, day: Int, elapsedHours: Int) throws {
        let calendar = TestDates.calendar("America/Los_Angeles")
        let seed = TestDates.date(2026, month, day, 9, calendar: calendar)
        let rule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, end: .afterOccurrences(3))
        let occurrences = Array(rule.recurrences(of: seed))
        #expect(occurrences.count == 3)
        #expect(occurrences[1].timeIntervalSince(occurrences[0]) == Double(elapsedHours * 3600))
        for occurrence in occurrences {
            let axis = TimeAxis(date: occurrence, range: 8...10, minuteInterval: 15, calendar: calendar)
            let visible = try #require(axis.visiblePeriod(start: occurrence, end: occurrence.addingTimeInterval(1800)))
            #expect(axis.offset(for: visible.start, height: 1200) == 600)
            #expect(visible.duration == 1800)
        }
    }

    @Test func standardRecurrenceRangeSelectsOnlyVisibleOccurrences() throws {
        let calendar = TestDates.calendar()
        let seed = TestDates.date(2026, 11, 3, 9)
        let visibleDay = try #require(calendar.dateInterval(of: .day, for: TestDates.date()))
        let rule = Calendar.RecurrenceRule(calendar: calendar, frequency: .daily, end: .afterOccurrences(3))
        let occurrences = Array(rule.recurrences(of: seed, in: visibleDay.start..<visibleDay.end))
        #expect(occurrences == [TestDates.date(2026, 11, 4, 9)])
        let axis = TimeAxis(date: visibleDay.start, range: 8...10, minuteInterval: 15, calendar: calendar)
        let occurrence = try #require(occurrences.first)
        #expect(axis.visiblePeriod(start: occurrence, end: occurrence.addingTimeInterval(3600))?.duration == 3600)
    }

    @Test func newerClosedRangeRecurrencesDoNotAddAnEndBoundaryEvent() {
        let calendar = TestDates.calendar()
        let seed = TestDates.date(2026, 11, 4, 8)
        let axis = TimeAxis(date: seed, range: 8...10, minuteInterval: 15, calendar: calendar)
        let rule = Calendar.RecurrenceRule(calendar: calendar, frequency: .hourly, end: .afterOccurrences(3))
        // This overload requires OS 26.4; CalendarUI's deployment floor is 27.
        let occurrences = Array(rule.recurrences(of: seed, in: axis.period.start...axis.period.end))
        #expect(occurrences.count == 3)
        let visible = occurrences.compactMap { axis.visiblePeriod(start: $0, end: $0.addingTimeInterval(3600)) }
        #expect(visible.count == 2)
        #expect(visible.last?.end == axis.period.end)
    }

    @Test func halfOpenEventOverlapDiffersFromFoundationClosedIntervals() {
        let start = TestDates.date(2026, 11, 4, 8)
        let period = DateInterval(start: start, duration: 3600)
        let adjacent = DateInterval(start: period.end, duration: 3600)
        #expect(period.contains(period.end))
        #expect(period.intersects(adjacent))
        #expect(!CalendarDates.overlaps(start: adjacent.start, end: adjacent.end, interval: period))
        #expect(!CalendarDates.overlaps(start: start.addingTimeInterval(-3600), end: start, interval: period))
        #expect(CalendarDates.overlaps(start: start, end: period.end, interval: period))
    }
}
