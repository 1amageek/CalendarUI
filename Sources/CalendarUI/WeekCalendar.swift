//
//  WeekCalendar.swift
//
//
//  Created by nori on 2022/03/12.
//

import SwiftUI

public struct WeekCalendar<Content, Header, Ruler> {

    private var startWeekOfYear: Date

    private var calendar: Calendar = Calendar.autoupdatingCurrent

    private var columns: [GridItem]

    public var content: (Date) -> Content

    public var header: (Date) -> Header

    public var ruler: (Int) -> Ruler
}

extension WeekCalendar: View where Content: View, Header: View, Ruler: View {

    public init(
        year: Int,
        month: Int,
        weekOfMonth: Int,
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Date) -> Header,
        @ViewBuilder ruler: @escaping (Int) -> Ruler
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month).date!
        let startWeekOfMonth = calendar.date(byAdding: .weekOfMonth, value: weekOfMonth, to: startDayOfMonth)!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startWeekOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        self.columns = [GridItem(.flexible(minimum: 24, maximum: 120), spacing: 0, alignment: .center)] + (0..<7).map({ _ in GridItem(.flexible(minimum: 44, maximum: .infinity), spacing: 0, alignment: .center) })
        self.content = content
        self.header = header
        self.ruler = ruler
    }

    public var body: some View {
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
                    ForEach(0..<24) { hour in
                        ForEach(0..<8) { index in
                            if index == 0 {
                                ruler(hour)
                            } else {
                                let day = index - 1
                                let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                                let time = calendar.date(byAdding: .hour, value: hour, to: date)!
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

extension WeekCalendar where Content: View, Header: View, Ruler == EmptyView {

    public init(
        year: Int,
        month: Int,
        weekOfMonth: Int,
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content,
        @ViewBuilder header: @escaping (Date) -> Header
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month, weekOfMonth: 2).date!
        let startWeekOfMonth = calendar.date(byAdding: .weekOfMonth, value: weekOfMonth, to: startDayOfMonth)!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startWeekOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        self.columns = (0..<7).map({ _ in GridItem(.flexible(minimum: 44, maximum: .infinity), spacing: 0, alignment: .center) })
        self.content = content
        self.header = header
        self.ruler = { _ in EmptyView() }
    }

    public var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                ForEach(0..<7) { day in
                    let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                    header(date)
                }
            }
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                    ForEach(0..<24) { hour in
                        ForEach(0..<7) { day in
                            let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                            let time = calendar.date(byAdding: .hour, value: hour, to: date)!
                            content(time)
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
        timeZone: TimeZone = .autoupdatingCurrent,
        @ViewBuilder content: @escaping (Date) -> Content
    ) {
        let startDayOfMonth = DateComponents(calendar: calendar, timeZone: timeZone, year: year, month: month).date!
        let startWeekOfMonth = calendar.date(byAdding: .weekOfMonth, value: weekOfMonth, to: startDayOfMonth)!
        let startWeekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: startWeekOfMonth).date!
        self.startWeekOfYear = startWeekOfYear
        self.columns = (0..<7).map({ _ in GridItem(.flexible(minimum: 44, maximum: .infinity), spacing: 0, alignment: .center) })
        self.content = content
        self.header = { _ in EmptyView() }
        self.ruler = { _ in EmptyView() }
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .center, spacing: 0) {
                ForEach(0..<24) { hour in
                    ForEach(0..<7) { day in
                        let date = calendar.date(byAdding: .day, value: day, to: startWeekOfYear)!
                        let time = calendar.date(byAdding: .hour, value: hour, to: date)!
                        content(time)
                    }
                }
            }
        }
    }
}

struct WeekCalendar_Previews: PreviewProvider {

    static var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d h"
        return f
    }()

    static var previews: some View {
        let calendar = Calendar(identifier: .gregorian)
        WeekCalendar(year: 2022, month: 3, weekOfMonth: 2) { date in
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
            Text(calendar.component(.day, from: date), format: .number)
                .font(.body)
        } ruler: { hour in
            VStack {
                HStack {
                    Text("\(hour):00")
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
