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

public struct TimeCalendar<Data, ID, Content> where Data : RandomAccessCollection, ID : Hashable {
    
    @Environment(\.calendar) var calendar: Calendar
    
    private var scale: CGFloat = 1000
    
    @GestureState var magnifyBy: CGFloat = 1.0
    
    private var insets: EdgeInsets = .init(top: 12, leading: 56, bottom: 12, trailing: 0)
    
    public var date: Date
    
    public var data: Data
    
    public var content: (Data.Element) -> Content
    
    var id: KeyPath<Data.Element, ID>
    
}

extension TimeCalendar: View where Content: View, Data.Element: PeriodRepresentable {
    
    public init(_ date: Date, data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        let calendar = Calendar(identifier: .iso8601)
        self.date = calendar.startOfDay(for: date)
        self.data = data
        self.id = id
        self.content = content
    }
    
    func getFrame(size: CGSize, start: Date, end: Date) -> CGRect {
        let startOfDay = calendar.startOfDay(for: start)
        let startRatio = (start.timeIntervalSince1970 - startOfDay.timeIntervalSince1970) / 86440
        let itemSize = getSize(size: size, start: start, end: end)
        let x = insets.leading + itemSize.width / 2
        let y = insets.top + (size.height - (insets.top + insets.bottom)) * startRatio + itemSize.height / 2
        return CGRect(origin: CGPoint(x: x, y: y), size: itemSize)
    }
    
    func getSize(size: CGSize, start: Date, end: Date) -> CGSize {
        let timeRatio = (end.timeIntervalSince1970 - start.timeIntervalSince1970) / 86440
        let height = (size.height - (insets.top + insets.bottom)) * timeRatio
        let width: CGFloat = size.width - insets.leading
        return CGSize(width: width, height: height)
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
    }
    
    public var body: some View {
        let beginningOfDay = date
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: date)!
        GeometryReader { proxy in
            ScrollViewReader { scroll in
                ScrollView {
                    let width = proxy.size.width
                    let height = proxy.size.height + scale * magnifyBy
                    let size = CGSize(width: width, height: height)
                    GeometryReader { _ in
                        ForEach(data, id: id) { element in
                            let startDate = max(element.startDate, beginningOfDay)
                            let endDate = min(element.endDate, endOfDay)
                            let frame = getFrame(size: size, start: startDate, end: endDate)
                            content(element)
                                .position(x: frame.origin.x, y: frame.origin.y)
                                .frame(width: frame.size.width, height: frame.size.height)
                        }
                    }
                    .frame(width: width, height: height)
                    .background {
                        TimelineBackground(hideTime: calendar.isDateInToday(date) ? calendar.component(.hour, from: Date()) : nil, insets: insets)
                            .gesture(magnification)
                    }
                    .overlay {
                        GeometryReader { _ in
                            let frame = getNow(size: size)
                            CurrentTimeHand(Date().formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()))
                                .position(x: size.width / 2, y: frame.origin.y)
                                .frame(width: frame.size.width, height: frame.self.height)
                                .id("current")
                        }
                    }
                   
                }
                .onAppear { scroll.scrollTo("current") }
            }
        }
    }
}

struct TimeCalendar_Previews: PreviewProvider {
    
    struct Item: PeriodRepresentable, Hashable {
        var startDate: Date
        var endDate: Date
    }
    
    struct ContentView: View {
        var body: some View {
            TabView {
                TimeCalendar(
                    DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 13).date!,
                    data: [
                        Item(
                            startDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 13, hour: 0).date!,
                            endDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 13, hour: 5).date!
                        ),
                        Item(
                            startDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 13, hour: 6).date!,
                            endDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 13, hour: 7).date!
                        )
                    ], id: \.self) { element in
                        Color.blue
                            .cornerRadius(4)
                            .padding(.vertical, 1.5)
                            .padding(.horizontal, 1)
                            .overlay {
                                Text("\(element.startDate)")
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
