import SwiftUI

public struct DayCalendar<Data, ID, Content, Placeholder, Day, Header>: View
where Data: RandomAccessCollection, ID: Hashable, Data.Element: PeriodRepresentable,
      Content: View, Placeholder: View, Day: View, Header: View {
    private let calendar: Calendar
    private let id: KeyPath<Data.Element, ID>
#if !os(tvOS)
    private let onChangeGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)?
    private let onEndGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)?
#endif
    @Binding private var selection: Date
    public var data: Data
    public var range: (Date) -> ClosedRange<Int>
    public var minuteInterval: (Date) -> Int
    public var content: (Date, Data.Element) -> Content
    public var placeholder: (Date) -> Placeholder
    public var day: (Date) -> Day
    public var header: ((Date) -> Header)?

#if !os(tvOS)
    public init(
        _ selection: Binding<Date>, timeZone: TimeZone = .autoupdatingCurrent,
        data: Data, id: KeyPath<Data.Element, ID>,
        in range: ((Date) -> ClosedRange<Int>)? = nil, minuteInterval: ((Date) -> Int)? = nil,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping (Date) -> Placeholder,
        @ViewBuilder day: @escaping (Date) -> Day,
        @ViewBuilder header: @escaping (Date) -> Header,
        onChangeGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)? = nil,
        onEndGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)? = nil
    ) {
        self._selection = selection
        self.calendar = CalendarDates.configured(timeZone: timeZone)
        self.data = data
        self.id = id
        self.range = range ?? { _ in 0...24 }
        self.minuteInterval = minuteInterval ?? { _ in 15 }
        self.content = content
        self.placeholder = placeholder
        self.day = day
        self.header = header
        self.onChangeGesture = onChangeGesture
        self.onEndGesture = onEndGesture
    }

    public init(
        _ selection: Binding<Date>, timeZone: TimeZone = .autoupdatingCurrent,
        data: Data, id: KeyPath<Data.Element, ID>,
        in range: ((Date) -> ClosedRange<Int>)? = nil, minuteInterval: ((Date) -> Int)? = nil,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping (Date) -> Placeholder,
        @ViewBuilder day: @escaping (Date) -> Day,
        onChangeGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)? = nil,
        onEndGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)? = nil
    ) where Header == EmptyView {
        self.init(selection, timeZone: timeZone, data: data, id: id, in: range,
                  minuteInterval: minuteInterval, content: content, placeholder: placeholder,
                  day: day, header: { _ in EmptyView() }, onChangeGesture: onChangeGesture,
                  onEndGesture: onEndGesture)
    }

#else
    public init(
        _ selection: Binding<Date>, timeZone: TimeZone = .autoupdatingCurrent,
        data: Data, id: KeyPath<Data.Element, ID>,
        in range: ((Date) -> ClosedRange<Int>)? = nil, minuteInterval: ((Date) -> Int)? = nil,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping (Date) -> Placeholder,
        @ViewBuilder day: @escaping (Date) -> Day,
        @ViewBuilder header: @escaping (Date) -> Header
    ) {
        self._selection = selection
        self.calendar = CalendarDates.configured(timeZone: timeZone)
        self.data = data
        self.id = id
        self.range = range ?? { _ in 0...24 }
        self.minuteInterval = minuteInterval ?? { _ in 15 }
        self.content = content
        self.placeholder = placeholder
        self.day = day
        self.header = header
    }

    public init(
        _ selection: Binding<Date>, timeZone: TimeZone = .autoupdatingCurrent,
        data: Data, id: KeyPath<Data.Element, ID>,
        in range: ((Date) -> ClosedRange<Int>)? = nil, minuteInterval: ((Date) -> Int)? = nil,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping (Date) -> Placeholder,
        @ViewBuilder day: @escaping (Date) -> Day
    ) where Header == EmptyView {
        self.init(selection, timeZone: timeZone, data: data, id: id, in: range,
                  minuteInterval: minuteInterval, content: content, placeholder: placeholder,
                  day: day, header: { _ in EmptyView() })
    }
#endif

    var selectedDay: Binding<Date> {
        Binding(get: { calendar.startOfDay(for: selection) }, set: { selection = $0 })
    }

    var selectedWeek: Binding<Date> {
        Binding {
            CalendarDates.start(of: .weekOfYear, for: selection, calendar: calendar)
        } set: { week in
            let previousWeek = CalendarDates.start(of: .weekOfYear, for: selection, calendar: calendar)
            guard let weekday = calendar.dateComponents([.day], from: previousWeek, to: calendar.startOfDay(for: selection)).day else {
                preconditionFailure("The selected weekday cannot be represented.")
            }
            selection = CalendarDates.adding(.day, value: weekday, to: week, calendar: calendar)
        }
    }

#if !os(tvOS)
    private var gesture: some Gesture {
        SimultaneousGesture(LongPressGesture(minimumDuration: 0.2, maximumDistance: 5),
                            DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { onChangeGesture?($0) }
            .onEnded { onEndGesture?($0) }
    }
#endif

    public var body: some View {
        CalendarPager(selection: selectedDay, calendar: calendar, component: .day) { date in
            // TimeCalendar owns period intersection and empty-slot detection.
            let timeline = TimeCalendar(date, data: data, id: id, in: range(date),
                         minuteInterval: minuteInterval(date), timeZone: calendar.timeZone, content: content)
                .emptySlots(placeholder)
#if os(tvOS)
            timeline
#else
            timeline.simultaneousGesture(gesture)
#endif
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                CalendarPager(selection: selectedWeek, calendar: calendar, component: .weekOfYear) { week in
                    HStack(spacing: 0) {
                        ForEach(0..<7) { index in
                            let date = CalendarDates.adding(.day, value: index, to: week, calendar: calendar)
                            Button { withAnimation { selection = date } } label: {
                                day(date).frame(maxWidth: .infinity).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .frame(height: 66)
                Text(selection, format: .dateTime.year().month().day())
                    .font(.callout).padding(.vertical, 8)
                Divider()
                if let header {
                    header(selection)
                    Divider()
                }
            }
        }
        .environment(\.calendar, calendar)
        .environment(\.timeZone, calendar.timeZone)
    }
}
