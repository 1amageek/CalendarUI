import SwiftUI

struct TimelineContent<Data, ID, Content, Placeholder>: View
where Data: RandomAccessCollection, ID: Hashable, Data.Element: PeriodRepresentable, Content: View, Placeholder: View {
    let date: Date
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let range: ClosedRange<Int>
    let minuteInterval: Int
    let calendar: Calendar
    let content: (Date, Data.Element) -> Content
    let placeholder: (Date) -> Placeholder
    private let insets = EdgeInsets(top: 12, leading: 56, bottom: 12, trailing: 0)

    var body: some View {
        let axis = TimeAxis(date: date, range: range, minuteInterval: minuteInterval, calendar: calendar)
        GeometryReader { viewport in
            let height = max(viewport.size.height - insets.top - insets.bottom,
                             axis.period.duration / Double(minuteInterval * 60) * 44)
            let width = max(0, viewport.size.width - insets.leading - insets.trailing)
            ScrollViewReader { scroll in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            ForEach(axis.slots, id: \.start) { slot in
                                ZStack {
                                    Color.clear
                                    if !data.contains(where: { CalendarDates.overlaps(start: $0.startDate, end: $0.endDate, interval: slot) }) {
                                        placeholder(slot.start)
                                    }
                                }
                                .frame(width: width, height: axis.offset(for: slot.end, height: height) - axis.offset(for: slot.start, height: height))
                                .id(slot.start)
                            }
                        }
                        .padding(.leading, insets.leading)
                        .padding(.top, insets.top)
                        ForEach(data, id: id) { item in
                            if let period = axis.visiblePeriod(start: item.startDate, end: item.endDate) {
                                let top = axis.offset(for: period.start, height: height)
                                let itemHeight = CGFloat(period.duration / axis.period.duration) * height
                                content(period.start, item)
                                    .frame(width: width, height: itemHeight)
                                    .clipped()
                                    .position(x: insets.leading + width / 2, y: insets.top + top + itemHeight / 2)
                            }
                        }
                    }
                    .frame(width: viewport.size.width, height: height + insets.top + insets.bottom, alignment: .topLeading)
                    .background { TimelineBackground(axis: axis, insets: insets) }
                    .overlay(alignment: .topLeading) {
                        TimelineView(.periodic(from: .now, by: 60)) { context in
                            if axis.period.start <= context.date && context.date < axis.period.end {
                                let y = insets.top + axis.offset(for: context.date, height: height)
                                CurrentTimeHand(context.date.formatted(Date.FormatStyle(date: .omitted, time: .shortened,
                                                                                       calendar: calendar, timeZone: calendar.timeZone)), insets: insets)
                                    .frame(width: viewport.size.width, height: 20)
                                    .position(x: viewport.size.width / 2, y: y)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .onAppear { scroll.scrollTo(axis.scrollTarget(now: Date()), anchor: .center) }
                    .onChange(of: axis) { _, updated in
                        scroll.scrollTo(updated.scrollTarget(now: Date()), anchor: .center)
                    }
                }
            }
        }
        .environment(\.calendar, calendar)
        .environment(\.timeZone, calendar.timeZone)
    }
}
