//
//  WeekCalendar.swift
//
//
//  Created by nori on 2022/03/12.
//

import SwiftUI

public enum Interval {
    case hour(Int)
    case minute(Int)
    case second(Int)
}

extension Interval {

    var countOfSection: Int {
        switch self {
            case .hour(let int):
                let interval = max(1, min(23, int))
                return Int(24 / interval)
            case .minute(let int):
                let interval = max(1, min(59, int))
                return Int(24 * 60 / interval)
            case .second(let int):
                let interval = max(1, min(59, int))
                return Int(24 * 60 * 60 / interval)
        }
    }

    func time(at section: Int) -> (hour: Int, minute: Int, second: Int) {
        switch self {
            case .hour(let int):
                let hour = section * int
                return (hour, 0, 0)
            case .minute(let int):
                let (hour, minute) = (section * int).quotientAndRemainder(dividingBy: 60)
                return (hour, minute, 0)
            case .second(let int):
                let (hour, remainder) = (section * int).quotientAndRemainder(dividingBy: 60 * 60)
                let (minute, second) = remainder.quotientAndRemainder(dividingBy: 60)
                return (hour, minute, second)
        }
    }
}

public struct WeekCalendar<Content, Header, Ruler> {

    private var startWeekOfYear: Date

    private var calendar: Calendar = Calendar.autoupdatingCurrent

    private var columns: [GridItem]

    private var rangeOfSection: Range<Int>

    public var interval: Interval

    public var content: (Date) -> Content

    public var header: (Date) -> Header

    public var ruler: (Int, Int, Int) -> Ruler

}

extension WeekCalendar: View where Content: View, Header: View, Ruler: View {

    public init(
        year: Int,
        month: Int,
        weekOfMonth: Int,
        interval: Interval = .hour(1),
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Date) -> Header,
        @ViewBuilder ruler: @escaping (Int, Int, Int) -> Ruler
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month).date!
        let startWeekOfMonth = calendar.date(byAdding: .weekOfMonth, value: weekOfMonth, to: startDayOfMonth)!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startWeekOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        self.columns = [GridItem(.flexible(minimum: 24, maximum: 120), spacing: 0, alignment: .center)] + (0..<7).map({ _ in GridItem(.flexible(minimum: 44, maximum: .infinity), spacing: 0, alignment: .center) })
        self.interval = interval
        self.rangeOfSection = 0..<interval.countOfSection
        self.content = content
        self.header = header
        self.ruler = ruler
    }

    public var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                    ForEach(0..<8) { index in
                        if index == 0 {
                            Spacer()
                        } else {
                            let day = index - 1
                            let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                            header(date)
                        }
                    }
                }
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                        ForEach(rangeOfSection, id: \.self) { section in
                            let (hour, minute, second) = interval.time(at: section)
                            ForEach(0..<8) { index in
                                if index == 0 {
                                    ruler(hour, minute, second)
                                } else {
                                    let day = index - 1
                                    let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                                    let time = calendar.date(bySettingHour: hour, minute: minute, second: second, of: date)!
                                    content(time)
                                }
                            }
                        }
                    }
                    .offset(y: 22)
                }
            }
        }
    }
}

extension WeekCalendar where Content: View, Header: View, Ruler == EmptyView {

    public init(
        year: Int,
        month: Int,
        weekOfMonth: Int,
        interval: Interval = .hour(1),
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Date) -> Header
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month, weekOfMonth: 2).date!
        let startWeekOfMonth = calendar.date(byAdding: .weekOfMonth, value: weekOfMonth, to: startDayOfMonth)!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startWeekOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        self.columns = (0..<7).map({ _ in GridItem(.flexible(minimum: 44, maximum: .infinity), spacing: 0, alignment: .center) })
        self.interval = interval
        self.rangeOfSection = 0..<interval.countOfSection
        self.content = content
        self.header = header
        self.ruler = { _, _, _ in EmptyView() }
    }

    public var body: some View {
        GeometryReader { _ in
            VStack(spacing: 0) {
                LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                    ForEach(0..<7) { day in
                        let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                        header(date)
                    }
                }
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                        ForEach(rangeOfSection, id: \.self) { section in
                            let (hour, minute, second) = interval.time(at: section)
                            ForEach(0..<7) { day in
                                let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                                let time = calendar.date(bySettingHour: hour, minute: minute, second: second, of: date)!
                                content(time)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension WeekCalendar where Content: View, Header == EmptyView, Ruler == EmptyView {

    public init(
        year: Int,
        month: Int,
        weekOfMonth: Int,
        interval: Interval = .hour(1),
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month).date!
        let startWeekOfMonth = calendar.date(byAdding: .weekOfMonth, value: weekOfMonth, to: startDayOfMonth)!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startWeekOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        self.columns = (0..<7).map({ _ in GridItem(.flexible(minimum: 44, maximum: .infinity), spacing: 0, alignment: .center) })
        self.interval = interval
        self.rangeOfSection = 0..<interval.countOfSection
        self.content = content
        self.header = { _ in EmptyView() }
        self.ruler = { _, _, _ in EmptyView() }
    }

    public var body: some View {
        GeometryReader { _ in
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                    ForEach(rangeOfSection, id: \.self) { section in
                        let (hour, minute, second) = interval.time(at: section)
                        ForEach(0..<7) { day in
                            let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                            let time = calendar.date(bySettingHour: hour, minute: minute, second: second, of: date)!
                            content(time)
                        }
                    }
                }
            }
        }
    }
}

struct WeekCalendar_Previews: PreviewProvider {

    static var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d hh:mm:ss"
        return f
    }()

    static var previews: some View {
        let calendar = Calendar(identifier: .gregorian)
        WeekCalendar(year: 2022, month: 3,weekOfMonth: 2, interval: .hour(4)) { date in
            VStack {
                Divider()
                Text(dateFormatter.string(from: date))
                    .font(.body)
                    .bold()
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            .frame(height: 89)
        } header: { date in
            Text(calendar.component(.day, from: date), format: .number).font(.body)
        } ruler: { hour, minute, second in
            VStack {
                HStack {
                    Text("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(alignment: .trailing)
                .padding(.horizontal, 6)
                Spacer()
            }
            .frame(height: 100)
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
