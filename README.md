# CalendarUI

A headless SwiftUI calendar. CalendarUI calculates dates, pages, and event positions; your application supplies its data and the views displayed in each cell.

Requires **iOS 27+, macOS 27+, watchOS 27+, or tvOS 27+**. There are no third-party dependencies or UIKit requirements.

```text
Application models + View builders
                ↓
MonthCalendar / WeekCalendar / DayCalendar / TimeCalendar
                ↓
Calendar-aware dates, paging, and timeline placement
```

CalendarUI does not persist events, expand recurrence rules, or execute scheduled tasks.

## Foundation integration

Month dates, timeline slots, and hour marks are enumerated with Foundation's `Calendar.dates(byAdding:startingAt:in:)`. CalendarUI supplies the visible range, explicitly includes the initial boundary, and clips the final slot. Anchoring additions to the original date also avoids cumulative time shifts after a nonexistent midnight.

Expand recurring events in your application with Foundation's [`Calendar.RecurrenceRule`](https://developer.apple.com/documentation/foundation/calendar/recurrencerule). Pass `recurrences(of:in:)` a finite visible date range, map its dates to your event model, and supply those events to CalendarUI. There is no CalendarUI recurrence-rule type or custom recurrence engine to configure.

The `ClosedRange` recurrence overloads available since OS 26.4 also work with the OS 27 deployment floor. A closed range includes its upper boundary; CalendarUI's event display uses half-open periods and excludes an occurrence that starts exactly at the visible end. Foundation's `DateInterval.contains` and `intersects` use closed intervals, so they are not direct substitutes for this event-overlap policy.

The [Foundation integration tests](Tests/CalendarUITests/FoundationIntegrationTests.swift) compare calendar enumeration with `Calendar.dates(byAdding:...)`, cover leap/year boundaries and 30/60-minute daylight-saving transitions, and verify placement of standard recurring events. Native hosting tests also render events expanded by Foundation.

## Installation

Add `https://github.com/1amageek/CalendarUI.git` in Xcode's package dependencies and link the `CalendarUI` product. Select a reviewed revision or release appropriate to your application.

```swift
import CalendarUI
import SwiftUI
```

## Choose a view

| View | Purpose | Builders |
|---|---|---|
| `MonthCalendar` | Complete weeks covering a month | Date cell, optional weekday header |
| `WeekCalendar` | Seven days divided into time sections | Time cell, optional day header and time ruler |
| `DayCalendar` | Paged days with a paged week selector | Event, empty time slot, day selector, optional header |
| `TimeCalendar` | Events on one day's time axis | Event |
| `TimelineBackground` | Standalone hour lines and labels | Built-in Canvas rendering |

## Month grid

```swift
MonthCalendar(year: 2026, month: 11) { date in
    Text(date, format: .dateTime.day())
} header: { column in
    let calendar = Calendar.autoupdatingCurrent
    let weekday = (calendar.firstWeekday - 1 + column) % 7
    Text(calendar.shortWeekdaySymbols[weekday])
}
.frame(height: 320)
```

The header receives a zero-based **column index**, not a weekday number. The grid uses the user's calendar and first weekday. Supply a height so its complete weeks can divide the available space.

## Weekly time cells

```swift
WeekCalendar(year: 2026, month: 11, weekOfMonth: 0, interval: .hour(5)) { date in
    Text(date, format: .dateTime.hour().minute())
        .frame(height: 60)
} header: { date in
    Text(date, format: .dateTime.weekday().day())
} ruler: { hour, minute, second in
    Text("\(hour):\(minute)")
}
```

`weekOfMonth` is a zero-based offset from the week containing the month's first day. Header/ruler convenience initializers calculate the same week. `Interval.hour`, `.minute`, and `.second` accept positive integers. Partial final sections are included: `.hour(5)` produces 00:00, 05:00, 10:00, 15:00, and 20:00. Larger-than-day intervals produce a single section. Zero or negative intervals violate a precondition.

## Event model and timeline

Use your own event type. `PeriodRepresentable` requires only `startDate` and `endDate`; identity is supplied separately by a key path.

```swift
struct Event: Identifiable, PeriodRepresentable {
    let id: UUID
    let title: String
    let startDate: Date
    let endDate: Date
}

struct EventTimeline: View {
    let date: Date
    let events: [Event]

    var body: some View {
        TimeCalendar(date, data: events, id: \.id, in: 8...20, minuteInterval: 15) { _, event in
            Text(event.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.blue.opacity(0.2))
        }
    }
}
```

The hour range must satisfy `0 <= lowerBound < upperBound <= 24`. `24` means the following day's midnight. `minuteInterval` must be `1...1440`; these nonthrowing view initializers reject invalid configuration with a precondition failure.

Event periods are half-open. Empty, reversed, and entirely out-of-range events are excluded. Events crossing midnight or the displayed range are clipped to the visible interval. The content builder receives the clipped visible start and the original event.

The timeline uses actual elapsed time between calendar boundaries, including 23- and 25-hour daylight-saving days. Repeated local hours retain separate positions. Events preserve collection order and may overlap; automatic collision lanes are not provided.

Current time, hour labels, event positions, and initial scroll targets share the same time axis. Current time updates while the view is mounted. Today's timeline scrolls to a rendered slot near now; other days open at the beginning of the displayed range. This works with empty data and with any event ID type.

## Paged day calendar

```swift
struct CalendarScreen: View {
    @State private var selection = Date()
    let events: [Event]

    var body: some View {
        DayCalendar($selection, data: events, id: \.id) { _, event in
            Text(event.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.blue.opacity(0.2))
        } placeholder: { date in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { selection = date }
        } day: { date in
            Text(date, format: .dateTime.day())
                .padding(8)
        } header: { date in
            Text(date, format: .dateTime.month().day())
        }
    }
}
```

The date-only placeholder is rendered for every unoccupied time slot; an empty event collection still displays all slots. Slot overlap uses half-open event intervals, so an event ending at a slot's start does not occupy it.

Paging uses native SwiftUI horizontal scrolling on every platform. Week paging preserves the selected weekday, and the binding also supports programmatic date changes. Each pager holds offsets `-9999..<9999` around its anchor; external selections outside that window recenter it. On iOS, macOS, and watchOS, event gestures remain available through `onChangeGesture` and `onEndGesture`. tvOS uses native focus, date buttons, and scrolling; its initializers omit these callbacks because SwiftUI does not provide `DragGesture` there.

## Time zones

Pass `timeZone:` to each calendar initializer when displaying a zone other than the user's current zone. `TimeCalendar` accepts it after `minuteInterval:`. The requested zone controls date boundaries, paging, event positions, labels, and the calendar/time-zone environment supplied to child views.

## Migrating from the earlier API

- Deployment targets are now 27.0 on all supported platforms.
- `DayCalendar`'s previously unused `placeholder: (Date, Data.Element) -> View` is now **`placeholder: (Date) -> View`**. Change `placeholder: { date, _ in ... }` to `placeholder: { date in ... }`. Empty slots do not have an event to supply as a second argument.
- `PageView` is no longer a dependency. Remove obsolete PageView pins when updating an application lockfile.
- Week time intervals now include the final partial section instead of omitting the day's remainder.

## Development

On a Mac running macOS 27 or later:

```sh
swift test
```

Apply an outer timeout in CI. Tests cover time zones, month boundaries, initializer consistency, interval arithmetic, daylight-saving transitions, event clipping, scroll target membership, and native macOS view hosting. Rendering tests are serialized because they share AppKit's application runtime. Other platform builds verify compilation separately from native runtime evidence.

See [DESIGN.md](DESIGN.md) for responsibility boundaries and verification ownership.
