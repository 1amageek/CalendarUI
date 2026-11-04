import SwiftUI

struct CalendarPager<Content: View>: View {
    @Binding var selection: Date
    let calendar: Calendar
    let component: Calendar.Component
    let content: (Date) -> Content
    @State private var anchor: Date
    @State private var visibleDate: Date?
    private let offsets = -9999..<9999

    init(selection: Binding<Date>, calendar: Calendar, component: Calendar.Component,
         @ViewBuilder content: @escaping (Date) -> Content) {
        self._selection = selection
        self.calendar = calendar
        self.component = component
        self.content = content
        let date = CalendarDates.start(of: component, for: selection.wrappedValue, calendar: calendar)
        self._anchor = State(initialValue: date)
        self._visibleDate = State(initialValue: date)
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(offsets, id: \.self) { offset in
                    let date = CalendarDates.adding(component, value: offset, to: anchor, calendar: calendar)
                    content(date)
                        .containerRelativeFrame(.horizontal)
                        .id(date)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleDate)
        .onChange(of: visibleDate) { _, date in
            guard let date else { return }
            let selected = CalendarDates.start(of: component, for: selection, calendar: calendar)
            if date != selected { selection = date }
        }
        .onChange(of: selection) { _, date in
            let target = CalendarDates.start(of: component, for: date, calendar: calendar)
            guard let offset = calendar.dateComponents([component], from: anchor, to: target).value(for: component) else {
                preconditionFailure("The selected page cannot be represented.")
            }
            if !offsets.contains(offset) { anchor = target }
            if visibleDate != target { visibleDate = target }
        }
    }
}
