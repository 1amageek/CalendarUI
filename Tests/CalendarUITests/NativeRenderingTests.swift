#if os(macOS)
import AppKit
import SwiftUI
import Testing
@testable import CalendarUI

@Suite(.serialized) @MainActor struct NativeRenderingTests {
    enum Failure: Error { case timedOut }

    private func waitUntil(_ predicate: () -> Bool) async throws {
        let deadline = ContinuousClock.now.advanced(by: .seconds(8))
        while !predicate() {
            guard ContinuousClock.now < deadline else { throw Failure.timedOut }
            try await Task.sleep(for: .milliseconds(50))
        }
    }

    private func host<Content: View>(_ content: Content) -> NSWindow {
        _ = NSApplication.shared
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 480, height: 480),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: content)
        window.orderFront(nil)
        window.contentView?.layoutSubtreeIfNeeded()
        return window
    }

    @Test(.timeLimit(.minutes(1)))
    func emptySlotsRenderWithNoEvents() async throws {
        let observation = RenderObservations()
        let calendar = TestDates.calendar()
        let date = TestDates.date()
        let view = DayCalendar(.constant(date), timeZone: calendar.timeZone, data: [TestEvent](), id: \.id,
                               in: { _ in 8...10 }, minuteInterval: { _ in 60 },
                               content: { _, _ in Color.blue },
                               placeholder: { date in Color.clear.onAppear { observation.placeholders.insert(date) } },
                               day: { date in Text(date, format: .dateTime.day()) })
        let window = host(view)
        defer { window.close() }
        let eight = TestDates.date(2026, 11, 4, 8)
        let nine = TestDates.date(2026, 11, 4, 9)
        try await waitUntil { observation.placeholders.contains(eight) && observation.placeholders.contains(nine) }
        #expect(observation.placeholders.contains(eight))
        #expect(observation.placeholders.contains(nine))
    }

    @Test(.timeLimit(.minutes(1)))
    func occupiedSlotsRenderEventsInsteadOfPlaceholders() async throws {
        let observation = RenderObservations()
        let calendar = TestDates.calendar()
        let date = TestDates.date()
        let eight = TestDates.date(2026, 11, 4, 8)
        let nine = TestDates.date(2026, 11, 4, 9)
        let event = TestEvent(id: "event", startDate: eight, endDate: nine)
        let view = DayCalendar(.constant(date), timeZone: calendar.timeZone, data: [event], id: \.id,
                               in: { _ in 8...10 }, minuteInterval: { _ in 60 },
                               content: { _, item in Color.blue.onAppear { observation.events.insert(item.id) } },
                               placeholder: { date in Color.clear.onAppear { observation.placeholders.insert(date) } },
                               day: { date in Text(date, format: .dateTime.day()) })
        let window = host(view)
        defer { window.close() }
        try await waitUntil { observation.events.contains("event") && observation.placeholders.contains(nine) }
        #expect(!observation.placeholders.contains(eight))
    }

    @MainActor final class Selection: ObservableObject {
        @Published var date = TestDates.date()
    }

    struct PagingFixture: View {
        @ObservedObject var selection: Selection
        let observation: RenderObservations

        var body: some View {
            DayCalendar($selection.date, timeZone: TestDates.calendar().timeZone, data: [TestEvent](), id: \.id,
                        in: { _ in 8...10 }, minuteInterval: { _ in 60 },
                        content: { _, _ in Color.blue },
                        placeholder: { date in Color.clear.onAppear { observation.placeholders.insert(date) } },
                        day: { date in Text(date, format: .dateTime.day()) },
                        header: { date in
                            Text(date.description).onChange(of: date, initial: true) { _, date in
                                observation.headers.insert(date)
                            }
                        })
        }
    }

    @Test(.timeLimit(.minutes(1)))
    func programmaticPagingAndRecenteringKeepSelection() async throws {
        let selection = Selection()
        let observation = RenderObservations()
        let window = host(PagingFixture(selection: selection, observation: observation))
        defer { window.close() }
        try await waitUntil { observation.placeholders.contains(TestDates.date(2026, 11, 4, 8)) }
        selection.date = TestDates.date(2026, 11, 5)
        try await waitUntil { observation.placeholders.contains(TestDates.date(2026, 11, 5, 8)) }
        let distant = TestDates.date(2060, 11, 5)
        selection.date = distant
        try await waitUntil {
            observation.placeholders.contains(TestDates.date(2060, 11, 5, 8)) && observation.headers.contains(distant)
        }
        #expect(observation.headers.contains(distant))
        #expect(selection.date == distant)
    }

    @Test(.timeLimit(.minutes(1)))
    func actualInitialScrollFindsSlotWithStringEventIDs() async throws {
        let observation = RenderObservations()
        let now = Date()
        let calendar = TestDates.noonCalendar(at: now)
        let axis = TimeAxis(date: now, range: 0...24, minuteInterval: 15, calendar: calendar)
        let target = axis.scrollTarget(now: now)
        let event = TestEvent(id: "current-event", startDate: target, endDate: target.addingTimeInterval(900))
        let view = TimeCalendar(now, data: [event], id: \.id, timeZone: calendar.timeZone) { _, event in
            Color.blue.onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("viewport"))
            } action: { frame in observation.frames[event.id] = frame }
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("viewport")) }
        action: { observation.viewport = $0 }
        .coordinateSpace(name: "viewport")
        let window = host(view)
        defer { window.close() }
        try await waitUntil {
            guard let frame = observation.frames[event.id] else { return false }
            return observation.viewport.height > 0 && frame.intersects(observation.viewport)
        }
        let frame = try #require(observation.frames[event.id])
        #expect(frame.intersects(observation.viewport))
    }

    @Test(.timeLimit(.minutes(1)))
    func actualInitialScrollWorksWithoutEvents() async throws {
        let observation = RenderObservations()
        let now = Date()
        let calendar = TestDates.noonCalendar(at: now)
        let axis = TimeAxis(date: now, range: 0...24, minuteInterval: 15, calendar: calendar)
        let target = axis.scrollTarget(now: now)
        let view = TimeCalendar(now, data: [TestEvent](), id: \.id, timeZone: calendar.timeZone) { _, _ in Color.blue }
            .emptySlots { date in
                Color.clear.onGeometryChange(for: CGRect.self) { $0.frame(in: .named("viewport")) }
                action: { if date == target { observation.frames["target"] = $0 } }
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("viewport")) }
            action: { observation.viewport = $0 }
            .coordinateSpace(name: "viewport")
        let window = host(view)
        defer { window.close() }
        try await waitUntil {
            guard let frame = observation.frames["target"] else { return false }
            return observation.viewport.height > 0 && frame.intersects(observation.viewport)
        }
        #expect(observation.frames["target"]?.intersects(observation.viewport) == true)
    }
}
#endif
