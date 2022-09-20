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
                id: \.id) { element in
                    Color.blue.opacity(0.3)
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
