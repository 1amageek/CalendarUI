//
//  DayCalendar.swift
//  
//
//  Created by Norikazu Muramoto on 2022/09/15.
//

import SwiftUI
import PageView

public struct DayCalendar<Data, ID, Content, Placeholder, Header> where Data : RandomAccessCollection, ID : Hashable {
    
    private var calendar: Calendar = Calendar.autoupdatingCurrent
    
    private var startOfThisWeek: Date
    
    private var id: KeyPath<Data.Element, ID>
    
    public var data: Data
    
    public var range: (Date) -> ClosedRange<Int>
    
    public var minuteInterval: (Date) -> Int
    
    public var content: (Date, Data.Element) -> Content
    
    public var placeholder: (Date, Data.Element) -> Placeholder
    
    public var header: (Date) -> Header
    
    private var onChangeGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)?
    
    private var onEndGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)?
    
    @Binding var selection: Date
    
    @State var weekOfYear: Date
    
    @State var currentDay: Date
    
    @State var timeCalendarAlpha: CGFloat = 1
    
}

extension DayCalendar {
    
    private var gesture: some Gesture {
        SimultaneousGesture(LongPressGesture(minimumDuration: 0.2, maximumDistance: 5), DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                if let onChangeGesture = onChangeGesture {
                    onChangeGesture(value)
                }
            }
            .onEnded { value in
                if let onEndGesture = onEndGesture {
                    onEndGesture(value)
                }
            }
    }
}

extension DayCalendar: View where Content: View, Header: View, Placeholder: View, Data.Element: PeriodRepresentable {
    
    public init(
        _ selection: Binding<Date>,
        timeZone: TimeZone = .autoupdatingCurrent,
        data: Data,
        id: KeyPath<Data.Element, ID>,
        in range: ((Date) -> ClosedRange<Int>)? = nil,
        minuteInterval: ((Date) -> Int)? = nil,
        @ViewBuilder content: @escaping (Date, Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping (Date, Data.Element) -> Placeholder,
        @ViewBuilder header: @escaping (Date) -> Header,
        onChangeGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)? = nil,
        onEndGesture: ((SimultaneousGesture<LongPressGesture, DragGesture>.Value) -> Void)? = nil
    ) {
        let today = Date()
        self._selection = selection
        self._currentDay = State(initialValue: selection.wrappedValue)
        let dateComponents = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: today)
        self.startOfThisWeek = dateComponents.date!
        self._weekOfYear = State(initialValue: dateComponents.date!)
        self.data = data
        self.id = id
        self.content = content
        self.placeholder = placeholder
        self.header = header
        self.range = range ?? { _ in 0...24 }
        self.minuteInterval = minuteInterval ?? { _ in 15 }
        self.onChangeGesture = onChangeGesture
        self.onEndGesture = onEndGesture
    }
    
    func fileted(date: Date) -> [Data.Element] {
        let startDate = date
        let endDate = calendar.date(byAdding: .day, value: 1, to: date)!
        return data.filter { item in
            startDate <= item.startDate && item.startDate < endDate ||
            startDate < item.endDate && item.endDate <= endDate ||
            item.startDate <= startDate && endDate < item.endDate
        }
    }
    
    var selectionDate: Binding<Int> {
        Binding {
            return calendar.dateComponents([.day], from: startOfThisWeek, to: selection).day!
        } set: { newValue in
            self.selection = calendar.date(byAdding: .day, value: newValue, to: startOfThisWeek)!
        }
    }
    
    var bindingWeekOfYear: Binding<Int> {
        Binding {
            return calendar.dateComponents([.weekOfYear], from: startOfThisWeek, to: weekOfYear).weekOfYear!
        } set: { newValue in
            self.weekOfYear = calendar.date(byAdding: .weekOfYear, value: newValue, to: startOfThisWeek)!
        }
    }
    
    public var body: some View {
        PageView(selectionDate) {
            ForEach(-9999..<9999, id: \.self) { index in
                let date = calendar.date(byAdding: .day, value: index, to: startOfThisWeek)!
                let filteredData = fileted(date: date)
                TimeCalendar(date,
                             data: filteredData,
                             id: id,
                             in: range(date),
                             minuteInterval: minuteInterval(date),
                             content: content)
                    .onTapGesture { }
                    .gesture(gesture)
                    .opacity(timeCalendarAlpha)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.timeCalendarAlpha = 1
                        }
                    }
            }
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 0) {
                ScrollViewReader { scrollView in
                    PageView(bindingWeekOfYear) {
                        ForEach(-9999..<9999, id: \.self) { weekOffset in
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
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .onAppear {
            selection = calendar.dateComponents([.calendar, .timeZone, .year, .month, .day], from: selection).date!
            weekOfYear = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: selection).date!
        }
        .onChange(of: selection) { newValue in
            let date = calendar.dateComponents([.calendar, .timeZone, .yearForWeekOfYear, .weekOfYear], from: newValue).date!
            if weekOfYear != date {
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
        
        let dateComponent = Calendar.current.dateComponents(in: .current, from: Date())
        
        func items() -> [Item] {
            let startDate = DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2023, month: 1, day: 10, hour: 0).date!
            let endDate = DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2023, month: 1, day: 10, hour: 23, minute: 60).date!
            return stride(from: startDate, to: endDate, by: 15 * 60)
                .map { date in
                    return Item(
                        id: UUID().uuidString,
                        startDate: date,
                        endDate: date.addingTimeInterval(15 * 60)
                    )
                }
        }
        
        var body: some View {
            let items = items()
            DayCalendar(
                $selection,
                data: items,
                id: \.id,
                in: { _ in  6...24 },
                minuteInterval: { _ in 5 }
            ) { date, element in
                Color.blue
                    .cornerRadius(4)
                    .padding(1.5)
                    .overlay {
                        Text(date, format: .dateTime.hour().minute())
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
            } placeholder: { _, _ in
                EmptyView()
            } header: { date in
                let isToday = calendar.isDateInToday(date)
                let isSelected = calendar.isDate(selection, inSameDayAs: date)
                let selectedTextColor: Color = colorScheme == .dark ? .black : .white
                Text(date, format: .dateTime.day())
                    .font(isSelected ? .body : nil )
                    .fontWeight(isSelected ? .bold : nil)
                    .foregroundColor(isSelected ? selectedTextColor : (isToday ? .red : nil))
                    .frame(height: 36)
                    .background {
                        if calendar.isDate(selection, inSameDayAs: date) {
                            let selectecCircleColor: Color = colorScheme == .dark ? .white : .black
                            Circle()
                                .fill(isToday ? .red : selectecCircleColor)
                                .frame(width: 36, height: 36)
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
        .preferredColorScheme(.dark)
    }
}
