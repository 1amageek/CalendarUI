//
//  MonthCalendar.swift
//  
//
//  Created by nori on 2022/03/12.
//

import SwiftUI

public struct MonthCalendar<Content, Header> {

    private var startWeekOfYear: Date

    private var calendar: Calendar = Calendar.autoupdatingCurrent

    private var days: Range<Int>

    private var columns: [GridItem] {
        (0..<7).map({ _ in GridItem(.flexible(minimum: 24, maximum: .infinity), spacing: 0, alignment: .center) })
    }

    public var content: (Date) -> Content

    public var header: (Int) -> Header
}

struct _MonthCalendar<Content>: View where Content: View {

    var startWeekOfYear: Date
    var calendar: Calendar
    var days: Range<Int>
    var columns: [GridItem]
    var content: (Date) -> Content

    var body: some View {
        GeometryReader { proxy in
            let height: CGFloat = proxy.size.height / CGFloat(days.count / 7)
            LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                    content(date)
                        .frame(height: height)
                }
            }
        }
    }
}

extension MonthCalendar: View where Content: View, Header: View {

    public init(
        year: Int,
        month: Int,
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Int) -> Header
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month).date!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startDayOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        let range = calendar.range(of: .weekOfMonth, in: .month, for: startDayOfMonth)!
        let countOfDays = (range.upperBound - 1) * 7
        self.days = 0..<countOfDays
        self.content = content
        self.header = header
    }

    public var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                ForEach(0..<7) { index in
                    header(index)
                }
            }
            _MonthCalendar(startWeekOfYear: startWeekOfYear,
                           calendar: calendar,
                           days: days, columns: columns,
                           content: content)
        }
    }
}

extension MonthCalendar where Content: View, Header == EmptyView {

    public init(
        year: Int,
        month: Int,
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month).date!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startDayOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        let range = calendar.range(of: .weekOfMonth, in: .month, for: startDayOfMonth)!
        let countOfDays = (range.upperBound - 1) * 7
        self.days = 0..<countOfDays
        self.content = content
        self.header = { _ in EmptyView() }
    }

    public var body: some View {
        _MonthCalendar(startWeekOfYear: startWeekOfYear,
                       calendar: calendar,
                       days: days, columns: columns,
                       content: content)
    }
}

struct MonthCalendar_Previews: PreviewProvider {

    static var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    static var previews: some View {
        let calendar = Calendar(identifier: .gregorian)
        MonthCalendar(year: 2022, month: 3) { date in
            VStack {
                Text(dateFormatter.string(from: date))
                    .font(.body)
                    .bold()
                Spacer()
            }
        } header: { index in
            Text(calendar.veryShortWeekdaySymbols[index])
                .font(.body)
        }
        .padding()
    }
}
