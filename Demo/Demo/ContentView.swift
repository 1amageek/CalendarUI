//
//  ContentView.swift
//  Demo
//
//  Created by Norikazu Muramoto on 2022/09/19.
//

import SwiftUI
import CalendarUI

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
        return (0..<(2000)).map { index in
            let minutes = 15 * index
            return Item(
                id: "\(index)",
                startDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: minutes).date!,
                endDate: DateComponents(calendar: .autoupdatingCurrent, timeZone: .autoupdatingCurrent, year: 2022, month: 9, day: 11, hour: 0, minute: 15 * (index + 1)).date!
            )
        }
    }
    
    var body: some View {
        let items = items()
        DayCalendar($selection, data: items, id: \.id) { date, element in
            Color.blue
                .cornerRadius(4)
                .padding(1.5)
//                .overlay {
//                    Text(element.startDate, format: .dateTime.month().day())
//                }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
