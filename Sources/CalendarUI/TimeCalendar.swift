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
        
        init(range: Range<Date>, minuteInterval: Int) {
            self.strides = stride(from: range.lowerBound, to: range.upperBound, by: Date.Stride(minuteInterval * 60)).map({ $0 })
        }
    }
    
    @StateObject var model: Model
    
    @Environment(\.calendar) var calendar: Calendar
    
    private var scale: CGFloat = 3800
    
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
        self._model = StateObject(wrappedValue: Model(range: startDate..<endDate, minuteInterval: minuteInterval))
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
    
    var magnification: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { currentState, gestureState, transaction in
                gestureState = currentState
            }
            .onEnded { value in
                
            }
    }
    
    @ViewBuilder
    func strideStack(proxy: GeometryProxy) -> some View {
        let width = proxy.size.width
        let height = proxy.size.height + scale * magnifyBy
        let size = CGSize(width: width, height: height)
        let cellHeight = height / CGFloat((range.upperBound - range.lowerBound) * 60 / minuteInterval)
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
    
    public var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scroll in
                ScrollView {
                    strideStack(proxy: proxy)
                        .padding(.top, insets.top)
                        .padding(.bottom, insets.bottom)
                        .background {
                            TimelineBackground(
                                range,
                                hideTime: calendar.isDateInToday(date) ? calendar.component(.hour, from: Date()) : nil, insets: insets)
                                .gesture(magnification)
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

extension Range where Bound: Equatable {
    
    func intersects(_ range: Range<Bound>) -> Bool {
        self ~= range.lowerBound || range ~= self.lowerBound
    }
}

struct TimeCalendar_Previews: PreviewProvider {
    
    struct Item: PeriodRepresentable, Hashable {
        var startDate: Date
        var endDate: Date
    }
    
    struct ContentView: View {
        
        func items() -> [Item] {
            (0..<(1)).map { index in
                let minutes = 15 * index
                return Item(
                    startDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: minutes).date!,
                    endDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: 15 * (index + 1)).date!
                )
            }
        }
        
        var formatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.calendar = .autoupdatingCurrent
            formatter.timeZone = .autoupdatingCurrent
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "HH:mm"
            return formatter
        }
        
        var body: some View {
            TabView {
                TimeCalendar(
                    DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11).date!,
                    data: items(),
                    id: \.self) { date, element in
                        Color.blue
                            .cornerRadius(4)
                            .padding(.vertical, 1.5)
                            .padding(.horizontal, 1)
                            .overlay {
                                let id = formatter.string(from: element.startDate)
                                Text("\(element.startDate) \(id)")
                                    .font(.caption)
                            }
                    } placeholder: { date in
                        Spacer()
                    }
                    .safeAreaInset(edge: .top) {
                        ScrollView(.horizontal) {
                            Text("HEADER")
                        }
                        .frame(maxWidth: .infinity)
                        .background(.bar)
                    }
            }
            .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }
    
    static var previews: some View {
        ContentView()
    }
}
