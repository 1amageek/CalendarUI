//
//  TimeCalendar.swift
//  
//
//  Created by Norikazu Muramoto on 2022/09/15.
//

import SwiftUI

public protocol PeriodRepresentable {
    
    var startDate: Date { get }
    var endDate: Date { get }
}

public struct TimeCalendar<Data, ID, Content, Placeholder> where Data : RandomAccessCollection, ID : Hashable, Data.Element: PeriodRepresentable {
    
    class Model: ObservableObject {
        
        var strides: [Date]
        
        init(range: ClosedRange<Date>, minuteInterval: Int) {
            self.strides = stride(from: range.lowerBound, to: range.upperBound, by: Date.Stride(minuteInterval * 60)).map({ $0 })
        }
    }
    
    @StateObject var model: Model
    
    @Environment(\.calendar) var calendar: Calendar
    
    private var scale: CGFloat = 1
    
    @GestureState var magnifyBy: CGFloat = 1.0
    
    private var insets: EdgeInsets = .init(top: 12, leading: 56, bottom: 12, trailing: 0)
    
    private var formatter: DateFormatter
    
    public var date: Date
    
    public var data: Data
    
    public var range: ClosedRange<Int>
    
    public var minuteInterval: Int
    
    public var content: (Date, Data.Element) -> Content
    
    public var placeholder: (Date) -> Placeholder
    
    var id: KeyPath<Data.Element, ID>
    
    var tagID: Date
}

extension TimeCalendar: View where Content: View, Placeholder: View {
    
    public init(
        _ date: Date,
        data: Data,
        id: KeyPath<Data.Element, ID>,
        in range: ClosedRange<Int> = 0...24,
        minuteInterval: Int = 15,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping (Date) -> Placeholder
    ) {
        let calendar = Calendar(identifier: .iso8601)
        let startOfDay = calendar.startOfDay(for: date)
        self.date = startOfDay
        self.data = data
        self.id = id
        self.range = range
        self.minuteInterval = minuteInterval
        self.content = content
        self.placeholder = placeholder
        let formatter = DateFormatter()
        formatter.calendar = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        self.formatter = formatter
        self.tagID = calendar.nextDate(after: date, matching: DateComponents(minute: 0), matchingPolicy: .strict)!
        let startDate = calendar.date(bySetting: .hour, value: range.lowerBound, of: startOfDay)!
        let endDate = calendar.date(byAdding: .hour, value: range.count - 1, to: startDate)!
        self._model = StateObject(wrappedValue: Model(range: startDate...endDate, minuteInterval: minuteInterval))
    }
        
    func getHeight(size: CGSize, start: Date, end: Date) -> CGFloat {
        let timeRatio = (end.timeIntervalSince1970 - start.timeIntervalSince1970) / CGFloat(3600 * (range.upperBound - range.lowerBound))
        let height = (size.height - (insets.top + insets.bottom)) * timeRatio
        return height
    }
    
    func getNow(size: CGSize) -> CGRect {
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let startRatio = (now.timeIntervalSince1970 - startOfDay.timeIntervalSince1970) / CGFloat(3600 * (range.upperBound - range.lowerBound))
        let itemSize = CGSize(width: size.width, height: 20)
        let x = insets.leading + itemSize.width / 2
        let y = insets.top + (size.height - (insets.top + insets.bottom)) * startRatio
        return CGRect(origin: CGPoint(x: x, y: y), size: itemSize)
    }
    
    @ViewBuilder
    func strideStack(proxy: GeometryProxy) -> some View {
        let width = proxy.size.width
        let height = proxy.size.height + CGFloat(minuteInterval * 60) * scale * magnifyBy
        let size = CGSize(width: width, height: height)
        let cellHeight = height / (CGFloat(range.upperBound - range.lowerBound) / CGFloat(minuteInterval) * 60)
        LazyVStack(spacing: 0) {
            ForEach(model.strides, id: \.self) { date in
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: 0.5) {
                        let items = data.filter({ $0.startDate == date })
                        if items.isEmpty {
                            placeholder(date)
                        } else {
                            ForEach(items, id: id) { item in
                                let height = getHeight(size: size, start: item.startDate, end: item.endDate)
                                content(date, item)
                                    .frame(height: height)
                            }
                        }
                    }
                    .frame(height: cellHeight, alignment: .top)
                    .padding(.leading, insets.leading)
                }
                .frame(height: cellHeight, alignment: .top)
                .id(date)
            }
        }
        .frame(width: width, height: height, alignment: .top)
    }
    
    @ViewBuilder
    func collectionView(proxy: GeometryProxy) -> some View {
        let width = proxy.size.width
        let height = proxy.size.height + CGFloat(minuteInterval * 60) * scale * magnifyBy
        TimelineLayout(date: date, insets: insets, in: range) {
            ForEach(data, id: id) { item in
                content(Date(), item)
                    .calendarItem(item)
            }
        }
        .frame(width: width, height: height, alignment: .top)
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scroll in
                ScrollView {
//                    strideStack(proxy: proxy)
                    collectionView(proxy: proxy)
                        .padding(.top, insets.top)
                        .padding(.bottom, insets.bottom)
                        .background {
                            TimelineBackground(
                                range,
                                hideTime: calendar.isDateInToday(date) ? calendar.component(.hour, from: Date()) : nil, insets: insets)
                        }
                        .overlay {
                            if calendar.isDateInToday(date) {
                                GeometryReader { proxy in
                                    let frame = getNow(size: proxy.size)
                                    CurrentTimeHand(Date().formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()))
                                        .frame(width: frame.size.width, height: frame.self.height)
                                        .position(x: proxy.size.width / 2, y: frame.origin.y)
                                }
                            }
                        }
                        .onAppear { scroll.scrollTo(tagID, anchor: .center) }
                }
            }
        }
    }
}

struct TimelineLayout: Layout {
    
    var date: Date
    var insets: EdgeInsets
    var range: ClosedRange<Int>
    
    init(
        date: Date,
        insets: EdgeInsets,
        in range: ClosedRange<Int> = 0...24
    ) {
        self.date = date
        self.insets = insets
        self.range = range
    }
    
    func convertTimeInterval(_ period: Range<Date>) -> (TimeInterval, TimeInterval) {
        let calendar = Calendar.autoupdatingCurrent
        let starthour = calendar.component(.hour, from: period.lowerBound)
        let startminutes = calendar.component(.minute, from: period.lowerBound)
        let endhour = calendar.component(.hour, from: period.lowerBound)
        let endminutes = calendar.component(.minute, from: period.lowerBound)
        return (TimeInterval(starthour * 3600 + startminutes * 60), TimeInterval(endhour * 3600 + endminutes * 60))
    }
    
    func timeInterval(_ date: Date) -> TimeInterval {
        let calendar = Calendar.autoupdatingCurrent
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        return TimeInterval(hour * 3600 + minutes * 60)
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        let timeRange = CGFloat((range.upperBound - range.lowerBound) * 3600)
        let height = bounds.height
        for (_, subview) in subviews.enumerated() {
            let period: Range<Date> = subview[Period.self]
            let start = timeInterval(period.lowerBound) - (TimeInterval(range.lowerBound) * 3600)
            let end = timeInterval(period.upperBound) - (TimeInterval(range.lowerBound) * 3600)
            let point = CGPoint(x: insets.leading, y: insets.top + height * start / timeRange)
            let height = height * (end - start) / timeRange
            let placementProposal = ProposedViewSize(width: bounds.width - insets.leading - insets.trailing, height: height)
            subview.place(at: point, anchor: .topLeading, proposal: placementProposal)
        }
    }
}

private struct Period: LayoutValueKey {
    static let defaultValue: Range<Date> = Date()..<Date()
}

extension View {
    
    func calendarItem<T: PeriodRepresentable>(_ item: T) -> some View {
        return layoutValue(key: Period.self, value: item.startDate..<item.endDate)
    }
}

struct TimeCalendar_Previews: PreviewProvider {

    static var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
    
    struct Item: PeriodRepresentable, Hashable {
        var startDate: Date
        var endDate: Date
    }

    static var previews: some View {
        let data: [Item] = [
            Item(
                startDate: DateComponents(calendar: .autoupdatingCurrent, year: 2023, month: 1, day: 10).date!,
                endDate: DateComponents(calendar: .autoupdatingCurrent, year: 2023, month: 1, day: 10, hour: 1).date!),
            Item(
                startDate: DateComponents(calendar: .autoupdatingCurrent, year: 2023, month: 1, day: 10, hour: 3).date!,
                endDate: DateComponents(calendar: .autoupdatingCurrent, year: 2023, month: 1, day: 10, hour: 6).date!),
        ]
        TimeCalendar(Date(), data: data, id: \.self, in: 1...7, minuteInterval: 15) { date, _ in
            Color.green
                .padding(2)
        } placeholder: { date in
            Color.blue
                .padding(2)
        }
        .padding(.vertical, 16)
    }
}
