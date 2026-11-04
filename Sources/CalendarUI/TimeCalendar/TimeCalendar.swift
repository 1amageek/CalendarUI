import SwiftUI

public struct TimeCalendar<Data, ID, Content>: View
where Data: RandomAccessCollection, ID: Hashable, Data.Element: PeriodRepresentable, Content: View {
    public var date: Date
    public var data: Data
    public var range: ClosedRange<Int>
    public var minuteInterval: Int
    public var content: (Date, Data.Element) -> Content
    private let id: KeyPath<Data.Element, ID>
    private let calendar: Calendar

    public init(
        _ date: Date, data: Data, id: KeyPath<Data.Element, ID>,
        in range: ClosedRange<Int> = 0...24, minuteInterval: Int = 15,
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content
    ) {
        let calendar = CalendarDates.configured(timeZone: timeZone)
        _ = TimeAxis(date: date, range: range, minuteInterval: minuteInterval, calendar: calendar)
        self.date = calendar.startOfDay(for: date)
        self.data = data
        self.id = id
        self.range = range
        self.minuteInterval = minuteInterval
        self.calendar = calendar
        self.content = content
    }

    public var body: some View { emptySlots { _ in EmptyView() } }

    func emptySlots<Placeholder: View>(@ViewBuilder _ placeholder: @escaping (Date) -> Placeholder) -> some View {
        TimelineContent(date: date, data: data, id: id, range: range,
                        minuteInterval: minuteInterval, calendar: calendar,
                        content: content, placeholder: placeholder)
    }
}
