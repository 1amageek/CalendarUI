//
//  SwiftUIView.swift
//  
//
//  Created by Norikazu Muramoto on 2022/09/15.
//

import SwiftUI

public struct DayCalendar<Data, ID, Content, Header> where Data : RandomAccessCollection, ID : Hashable {
    
    private var calendar: Calendar = Calendar.autoupdatingCurrent
    
    private var startOfToday: Date
    
    private var startOfThisWeek: Date
    
    public var data: Data
    
    public var content: (Data.Element) -> Content
    
    private var id: KeyPath<Data.Element, ID>
    
    public var header: (Date) -> Header
    
    @Binding var selection: Date
    
    @State var weekOfYear: Date
}

extension DayCalendar: View where Content: View, Header: View, Data.Element: PeriodRepresentable {
    
    public init(
        _ selection: Binding<Date>,
        timeZone: TimeZone = .autoupdatingCurrent,
        data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content,
        @ViewBuilder header: @escaping (Date) -> Header
    ) {
        self._selection = selection
        self.startOfToday = calendar.dateComponents([.calendar, .timeZone, .year, .month, .day], from: Date()).date!
        self.startOfThisWeek = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: Date()).date!
        let dateComponents = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: Date())
        self._weekOfYear = State(initialValue: dateComponents.date!)
        self.data = data
        self.id = id
        self.content = content
        self.header = header
    }
    
    public var body: some View {
        TabView(selection: $selection) {
            ForEach(-99..<99) { index in
                let date = calendar.date(byAdding: .day, value: index, to: startOfToday)!
//                let filteredData = data.filter { item in
//                    let startDateIsSameDay = calendar.isDate(item.startDate, inSameDayAs: date)
//                    let endDateIsSameDay = calendar.isDate(item.endDate, inSameDayAs: date)
//                    let isInThePeiod = item.startDate <= date && date < item.endDate
//                    return startDateIsSameDay || endDateIsSameDay || isInThePeiod
//                }
                TimeCalendar(date, data: data, id: id, content: content)
                    .tag(date)
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
                Text(selection, format: .dateTime.year().month().day().hour().minute())
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
            withAnimation {
                weekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: newValue).date!
            }
        }
        .onChange(of: weekOfYear) { [value = weekOfYear] newValue in
            if value < newValue {
                selection = calendar.date(byAdding: .weekOfYear, value: 1, to: selection)!
            } else {
                selection = calendar.date(byAdding: .weekOfYear, value: -1, to: selection)!
            }
        }
    }
}


struct DayCalendar_Previews: PreviewProvider {
    
    struct Item: PeriodRepresentable, Hashable {
        var startDate: Date
        var endDate: Date
    }
    
    struct ContentView: View {
        
        @Environment(\.colorScheme) private var colorScheme: ColorScheme
        
        @Environment(\.calendar) var calendar
        
        @State var selection: Date = Date()
        
        func items() -> [Item] {
            (0..<1000).map { index in
                let minutes = 15 * index
                return Item(
                    startDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: minutes).date!,
                    endDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: 15 * (index + 1)).date!
                )
            }
        }
        
        var body: some View {
            let items = items()
            DayCalendar($selection, data: items, id: \.self) { element in
                Color.blue
                    .cornerRadius(4)
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
