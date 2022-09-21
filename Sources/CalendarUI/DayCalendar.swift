//
//  DayCalendar.swift
//  
//
//  Created by Norikazu Muramoto on 2022/09/15.
//

import SwiftUI

public struct DayCalendar<Data, ID, Content, Placeholder, Header> where Data : RandomAccessCollection, ID : Hashable {
    
    private var calendar: Calendar = Calendar.autoupdatingCurrent
    
    private var startOfThisWeek: Date
    
    private var id: KeyPath<Data.Element, ID>
    
    public var data: Data
    
    public var range: ClosedRange<Int>
    
    public var minuteInterval: Int
    
    public var content: (Date, Data.Element) -> Content
    
    public var placeholder: (Date) -> Placeholder
    
    public var header: (Date) -> Header
    
    @Binding var selection: Date
    
    @State var weekOfYear: Date
    
    @State var currentDay: Date
    
    @State var timeCalendarAlpha: CGFloat = 1
}

extension DayCalendar: View where Content: View, Placeholder: View, Header: View, Data.Element: PeriodRepresentable {
    
    public init(
        _ selection: Binding<Date>,
        timeZone: TimeZone = .autoupdatingCurrent,
        data: Data,
        id: KeyPath<Data.Element, ID>,
        in range: ClosedRange<Int> = 0...24,
        minuteInterval: Int = 15,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping (Date) -> Placeholder,
        @ViewBuilder header: @escaping (Date) -> Header
    ) {
        self._selection = selection
        self._currentDay = State(initialValue: selection.wrappedValue)
        self.startOfThisWeek = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: Date()).date!
        let dateComponents = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: Date())
        self._weekOfYear = State(initialValue: dateComponents.date!)
        self.data = data
        self.id = id
        self.content = content
        self.placeholder = placeholder
        self.header = header
        self.range = range
        self.minuteInterval = minuteInterval
    }
    
    func fileted(date: Date) -> [Data.Element] {
        data.filter { item in
            let startDateIsSameDay = calendar.isDate(item.startDate, inSameDayAs: date)
            let endDateIsSameDay = calendar.isDate(item.endDate, inSameDayAs: date)
            let isInThePeiod = item.startDate <= date && date < item.endDate
            return startDateIsSameDay || endDateIsSameDay || isInThePeiod
        }
    }
    
    var startOfMonth: Date {
        calendar.date(byAdding: .day, value: -1, to: calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: weekOfYear).date!)!
    }
    
    var endOfMonth: Date {
        let date = calendar
            .date(byAdding: .weekOfYear, value: 1, to: weekOfYear)!
        return calendar.date(byAdding: .day, value: 2, to: date)!
    }
    
    var rangeOfMonth: Array<Date> {
        Array(stride(from: startOfMonth, through: endOfMonth, by: 60 * 60 * 24))
    }
    
    public var body: some View {
        TabView(selection: $selection) {
            ForEach(rangeOfMonth, id: \.self) { date in
                TimeCalendar(date,
                             data: data,
                             id: id,
                             in: range,
                             minuteInterval: minuteInterval,
                             content: content,
                             placeholder: placeholder)
                    .tag(date)
            }
            .opacity(timeCalendarAlpha)
            .onAppear {
                withAnimation(.easeOut(duration: 0.2)) {
                    self.timeCalendarAlpha = 1
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                ScrollViewReader { scrollView in
                    TabView(selection: $weekOfYear) {
                        ForEach(-99..<99) { weekOffset in
                            let weekOfYear = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startOfThisWeek)!
                            LazyVGrid(columns: Array(repeating: .init(), count: 7)) {
                                ForEach(0..<7) { index in
                                    let date = calendar.date(byAdding: .day, value: index, to: weekOfYear)!
                                    header(date)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation {
                                                selection = date
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .tag(weekOfYear)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                Text(selection, format: .dateTime.year().month().day())
                    .font(.callout)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                Divider()
            }
            .background(.bar)
            .frame(height: 64)
        }
        .onAppear {
            selection = calendar.dateComponents([.calendar, .timeZone, .year, .month, .day], from: selection).date!
            weekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: selection).date!
        }
        .onChange(of: selection) { newValue in
            let date = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: newValue).date!
            if weekOfYear != date {
                self.timeCalendarAlpha = 0
                withAnimation {
                    weekOfYear = date
                }
            }
        }
        .onChange(of: weekOfYear) { [oldValue = weekOfYear] newValue in
            let weekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: selection).date!
            if weekOfYear != newValue {
                if oldValue < newValue {
                    selection = calendar.date(byAdding: .weekOfYear, value: 1, to: selection)!
                } else {
                    selection = calendar.date(byAdding: .weekOfYear, value: -1, to: selection)!
                }
            }
        }
    }
}


struct DayCalendar_Previews: PreviewProvider {
    
    struct Item: PeriodRepresentable, Identifiable {
        var id: String
        var startDate: Date
        var endDate: Date
    }

    struct ContentView: View {
        
        @Environment(\.colorScheme) private var colorScheme: ColorScheme
        
        @Environment(\.calendar) var calendar
        
        @State var selection: Date = Date()
        
        func items() -> [Item] {
            var items = (0..<(20)).map { index in
                let minutes = 15 * index
                return Item(
                    id: UUID().uuidString,
                    startDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: minutes).date!,
                    endDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: 15 * (index + 1)).date!
                )
            }
            let minutes = 15 * 0
            items.append(Item(
                id: UUID().uuidString,
                startDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: minutes).date!,
                endDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: 15 * (0 + 1)).date!
            ))
            return items
        }
        
        var body: some View {
            let items = items()
            DayCalendar($selection, data: items, id: \.id) { date, element in
                Color.blue
                    .cornerRadius(4)
                    .padding(1.5)
            } placeholder: { date in
                Spacer()
            } header: { date in
                let isToday = calendar.isDateInToday(selection)
                let isSelected = calendar.isDate(selection, inSameDayAs: date)
                Text(date, format: .dateTime.day())
                    .font(isSelected ? .body : nil )
                    .fontWeight(isSelected ? .bold : nil)
                    .frame(width: 34, height: 34)
                    .foregroundColor(isSelected ? .white : nil)
                    .background {
                        if calendar.isDate(selection, inSameDayAs: date) {
                            let selectecColor: Color = colorScheme == .dark ? .white : .black
                            Circle()
                                .fill(isToday ? .red : selectecColor)
                        }
                    }
            }
            .safeAreaInset(edge: .top) {
                LazyVGrid(columns: Array(repeating: .init(), count: 7)) {
                    ForEach(0..<7) { index in
                        let weekdaySymbol = calendar.shortWeekdaySymbols[index]
                        Text(weekdaySymbol)
                            .font(.caption2)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}
