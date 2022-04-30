//
//  TimeLineCalendar.swift
//  
//
//  Created by nori on 2022/04/30.
//

import SwiftUI

public struct TimeLineCalendar<Content, Header, Ruler> {

    @Environment(\.calendar) var calendar: Calendar

    @State var cellHeight: CGFloat = 44

    var dateComponents: DateComponents
    var period: Range<Int>
    var interval: Interval
    var timeZone: TimeZone
    var content: (Range<Int>) -> Content
    var header: () -> Header
    var ruler: (Date) -> Ruler
}

extension TimeLineCalendar: View where Content: View, Header: View, Ruler: View {

    public init(
        year: Int,
        month: Int,
        day: Int,
        period: Range<Int> = 0..<24,
        interval: Interval = .minute(15),
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Range<Int>) -> Content,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder ruler: @escaping (Date) -> Ruler
    ) {
        self.dateComponents = DateComponents(calendar: .autoupdatingCurrent, timeZone: timeZone, year: year, month: month, day: day, hour: period.lowerBound)
        self.period = period
        self.interval = interval
        self.timeZone = timeZone
        self.content = content
        self.header = header
        self.ruler = ruler
    }

    var range: Range<Int> {
        switch interval {
            case .hour(let hour):
                let div = period.count / hour
                return 0..<div
            case .minute(let minute):
                let div = period.count * 60 / minute
                return 0..<div
            case .second(let second):
                let div = period.count * 60 * 60 / second
                return 0..<div
        }
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyHStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    Section {
                        content(range)
                    } header: {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            Section {
                                ForEach(range, id: \.self) { index in
                                    let value = interval.value * index
                                    let date = calendar.date(byAdding: interval.component, value: value, to: dateComponents.date!)!
                                    ruler(date)
                                        .frame(height: cellHeight)
                                }
                            } header: {
                                header()
                            }
                        }
                    }
                }
                .environment(\.timeLineCellHeight, cellHeight)
            }
        }
    }
}

public struct TimeLine<Content, Header> {
    @Environment(\.timeLineCellHeight) var cellHeight
    var content: () -> Content
    var header: () -> Header
}

extension TimeLine: View where Content: View, Header: View {

    public init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self.content = content
        self.header = header
    }

    public var body: some View {
        LazyVStack(alignment: .center, spacing: 0, pinnedViews: .sectionHeaders) {
            Section {
                content()
                    .frame(height: cellHeight)
            } header: {
                header()
            }
        }
    }
}

private struct TimeLineCellHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 20
}

extension EnvironmentValues {

    var timeLineCellHeight: CGFloat {
        get { self[TimeLineCellHeightKey.self] }
        set { self[TimeLineCellHeightKey.self] = newValue }
    }
}


public struct EqualParts<Content> {
    @Environment(\.timeLineCellHeight) var cellHeight
    var number: Int
    var content: (Int) -> Content
}

extension EqualParts: View where Content: View {

    public init(_ number: Int, @ViewBuilder content: @escaping (Int) -> Content) {
        self.number = number
        self.content = content
    }

    public var body: some View {
        ForEach(0..<number, id: \.self) { index in
            content(index)
                .frame(height: cellHeight)
        }
    }
}

struct TimeLineCalendar_Previews: PreviewProvider {

    static var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }

    static var previews: some View {
        TimeLineCalendar(year: 2022, month: 5, day: 1, period: 8..<17) { range in
            ForEach(0..<7) { index in
                TimeLine {
                    EqualParts(range.count) { index in
                        VStack(spacing: 0) {
                            Color.clear
                            Divider()
                        }
                    }
                } header: {
                    Text("\(index)にち")
                        .frame(width: 120, height: 60)
                        .background(.bar)
                }
            }
        } header: {
            Rectangle()
                .background(.bar)
                .frame(width: 120, height: 60)
        } ruler: { date in
            VStack {
                Text(dateFormatter.string(from: date))
            }
        }
    }
}
