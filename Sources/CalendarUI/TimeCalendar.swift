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

public struct TimeCalendar<Data, ID, Content> where Data : RandomAccessCollection, ID : Hashable, Data.Element: PeriodRepresentable {
    
    class Model: ObservableObject {
        
        struct TimeStride {
            var date: Date
            var itemsToStart: [ID]
            var itemsPassThrough: [ID]
        }
        
        var timeStrides: [TimeStride]
        
        init(startDate: Date, endDate: Date, data: Data, id: KeyPath<Data.Element, ID>) {
            let items: [Date] = stride(from: startDate, through: endDate, by: 15 * 60).map({ $0 })
            let length: Int = items.count - 1
            self.timeStrides = (0..<length).map { index in
                let start: Date = items[index]
                let end: Date = items[index + 1]
                let range: Range<Date> = start..<end
                let itemsToStart: [ID] = data.filter({ $0.startDate == start }).map({ $0[keyPath: id] })
                let itemsPassThrough: [ID] = data.filter({ ($0.startDate..<$0.endDate).intersects(range) }).map({ $0[keyPath: id] })
                return TimeStride(date: start, itemsToStart: itemsToStart, itemsPassThrough: itemsPassThrough)
            }
        }
    }
    
    @StateObject var model: Model
    
    @Environment(\.calendar) var calendar: Calendar
    
    private var scale: CGFloat = 4000
    
    @GestureState var magnifyBy: CGFloat = 1.0
    
    private var insets: EdgeInsets = .init(top: 12, leading: 56, bottom: 12, trailing: 0)
    
    private var formatter: DateFormatter
    
    public var date: Date
    
    public var data: Data
    
    public var content: (Data.Element) -> Content
    
    var id: KeyPath<Data.Element, ID>
    
    var tagID: String
}

extension TimeCalendar: View where Content: View {
    
    public init(_ date: Date, data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        let calendar = Calendar(identifier: .iso8601)
        let startOfDay = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        self.date = startOfDay
        self.data = data
        self.id = id
        self.content = content
        let formatter = DateFormatter()
        formatter.calendar = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        self.formatter = formatter
        self.tagID = formatter.string(from: calendar.nextDate(after: date, matching: DateComponents(minute: 0), matchingPolicy: .strict)!)
        self._model = StateObject(wrappedValue: Model(startDate: startOfDay, endDate: nextDay, data: data, id: id))
    }
    
    func getHeight(size: CGSize, start: Date, end: Date) -> CGFloat {
        let timeRatio = (end.timeIntervalSince1970 - start.timeIntervalSince1970) / 86440
        let height = (size.height - (insets.top + insets.bottom)) * timeRatio
        return height
    }
    
    func getNow(size: CGSize) -> CGRect {
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let startRatio = (now.timeIntervalSince1970 - startOfDay.timeIntervalSince1970) / 86440
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
        let cellHeight = height / (60 * 60 * 24) * 15 * 60
        LazyVStack(spacing: 0) {
            ForEach(model.timeStrides, id: \.date) { timeStride in
                let tagID = formatter.string(from: timeStride.date)
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: 0.5) {
                        ForEach(timeStride.itemsToStart, id: \.self) { key in
                            let item: Data.Element = data.first(where: { $0[keyPath: id] == key })!
                            let height = getHeight(size: size, start: item.startDate, end: item.endDate)
                            content(item)
                                .frame(height: height)
                        }
                    }
                    .frame(height: cellHeight, alignment: .top)
                    .padding(.leading, insets.leading)
                }
                .frame(height: cellHeight, alignment: .top)
                .id(tagID)
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
                            TimelineBackground(hideTime: calendar.isDateInToday(date) ? calendar.component(.hour, from: Date()) : nil, insets: insets)
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

extension TimeCalendar {
    

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
                    id: \.self) { element in
                        Color.blue
                            .cornerRadius(4)
                            .padding(.vertical, 1.5)
                            .padding(.horizontal, 1)
                            .overlay {
                                let id = formatter.string(from: element.startDate)
                                Text("\(element.startDate) \(id)")
                                    .font(.caption)
                            }
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
