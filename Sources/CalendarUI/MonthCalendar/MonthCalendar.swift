import SwiftUI

public struct MonthCalendar<Content: View, Header: View>: View {
    let calendar: Calendar
    let dates: [Date]
    public var content: (Date) -> Content
    public var header: (Int) -> Header

    public init(
        year: Int,
        month: Int,
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Int) -> Header
    ) {
        let calendar = CalendarDates.configured(timeZone: timeZone)
        self.calendar = calendar
        self.dates = CalendarDates.monthDates(year: year, month: month, calendar: calendar)
        self.content = content
        self.header = header
    }

    public init(
        year: Int,
        month: Int,
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content
    ) where Header == EmptyView {
        self.init(year: year, month: month, timeZone: timeZone, content: content, header: { _ in EmptyView() })
    }

    public var body: some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: 0), spacing: 0), count: 7)
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(0..<7) { header($0) }
            }
            GeometryReader { proxy in
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(dates, id: \.self) { date in
                        content(date).frame(height: proxy.size.height / CGFloat(dates.count / 7))
                    }
                }
            }
        }
        .environment(\.calendar, calendar)
        .environment(\.timeZone, calendar.timeZone)
    }
}

#Preview {
    MonthCalendar(year: 2026, month: 11) { date in
        Text(date, format: .dateTime.day())
    } header: { index in
        Text("\(index + 1)")
    }
    .frame(width: 420, height: 320)
}
