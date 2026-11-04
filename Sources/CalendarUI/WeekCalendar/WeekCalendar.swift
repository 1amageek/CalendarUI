import SwiftUI

public struct WeekCalendar<Content: View, Header: View, Ruler: View>: View {
    let calendar: Calendar
    let startWeekOfYear: Date
    private let showsHeader: Bool
    private let showsRuler: Bool
    public var interval: Interval
    public var content: (Date) -> Content
    public var header: (Date) -> Header
    public var ruler: (Int, Int, Int) -> Ruler

    public init(
        year: Int, month: Int, weekOfMonth: Int,
        interval: Interval = .hour(1), timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Date) -> Header,
        @ViewBuilder ruler: @escaping (Int, Int, Int) -> Ruler
    ) {
        let calendar = CalendarDates.configured(timeZone: timeZone)
        let first = CalendarDates.monthStart(year: year, month: month, calendar: calendar)
        let firstWeek = CalendarDates.start(of: .weekOfYear, for: first, calendar: calendar)
        self.calendar = calendar
        self.startWeekOfYear = CalendarDates.adding(.weekOfYear, value: weekOfMonth, to: firstWeek, calendar: calendar)
        self.interval = interval
        precondition(interval.value > 0, "Interval values must be positive.")
        self.content = content
        self.header = header
        self.ruler = ruler
        self.showsHeader = Header.self != EmptyView.self
        self.showsRuler = Ruler.self != EmptyView.self
    }

    public init(
        year: Int, month: Int, weekOfMonth: Int,
        interval: Interval = .hour(1), timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Date) -> Header
    ) where Ruler == EmptyView {
        self.init(year: year, month: month, weekOfMonth: weekOfMonth, interval: interval,
                  timeZone: timeZone, content: content, header: header, ruler: { _, _, _ in EmptyView() })
    }

    public init(
        year: Int, month: Int, weekOfMonth: Int,
        interval: Interval = .hour(1), timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content
    ) where Header == EmptyView, Ruler == EmptyView {
        self.init(year: year, month: month, weekOfMonth: weekOfMonth, interval: interval,
                  timeZone: timeZone, content: content, header: { _ in EmptyView() })
    }

    public var body: some View {
        let columns = (showsRuler ? [GridItem(.flexible(minimum: 24, maximum: 80), spacing: 0)] : [])
            + Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: 7)
        VStack(spacing: 0) {
            if showsHeader {
                LazyVGrid(columns: columns, spacing: 0) {
                    if showsRuler { Color.clear }
                    ForEach(0..<7) { day in
                        header(CalendarDates.adding(.day, value: day, to: startWeekOfYear, calendar: calendar))
                    }
                }
            }
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(0..<interval.countOfSection, id: \.self) { section in
                        let time = interval.time(at: section)
                        if showsRuler { ruler(time.hour, time.minute, time.second) }
                        ForEach(0..<7) { day in
                            let date = CalendarDates.adding(.day, value: day, to: startWeekOfYear, calendar: calendar)
                            if let instant = calendar.date(bySettingHour: time.hour, minute: time.minute, second: time.second, of: date) {
                                content(instant)
                            }
                        }
                    }
                }
            }
        }
        .environment(\.calendar, calendar)
        .environment(\.timeZone, calendar.timeZone)
    }
}
