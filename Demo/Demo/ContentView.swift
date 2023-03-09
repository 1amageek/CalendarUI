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
    
    @State var items: [Item] = []
    
    @State var isPreseneted: Bool = false
    
    init(items: [Item] = []) {
        self._items = State(initialValue: items)
    }
    
    var body: some View {
        DayCalendar($selection, data: items, id: \.id) { date, element in
            Color.blue
                .cornerRadius(4)
                .padding(1.5)
//                .overlay {
//                    Text(element.startDate, format: .dateTime.month().day())
//                }
        } placeholder: { date, _ in
            Spacer()
        } day: { date in
            let isToday = calendar.isDateInToday(selection)
            let isSelected = calendar.isDate(selection, inSameDayAs: date)
            Text(date, format: .dateTime.day())
                .font(isSelected ? .body : nil )
                .fontWeight(isSelected ? .bold : nil)
                .frame(width: 36, height: 36)
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
                        .padding(0)
                }
            }
            .padding(.horizontal, 16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.isPreseneted = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isPreseneted) {
            NavigationStack {
                Editor(items: $items)
            }
        }
    }
}

struct Editor: View {
    
    @Environment(\.dismiss) var dismiss: DismissAction
    
    @Binding var items: [Item]
    
    @State var item: Item
    
    init(items: Binding<[Item]>) {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
        let item = Item(id: UUID().uuidString, startDate: startDate, endDate: endDate)
        self._item = State(initialValue: item)
        self._items = items
    }
    
    var body: some View {
        List {
            DatePicker("Start", selection: $item.startDate)
            DatePicker("End", selection: $item.endDate)
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    items.append(item)
                    dismiss()
                } label: {
                    Text("Save")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
