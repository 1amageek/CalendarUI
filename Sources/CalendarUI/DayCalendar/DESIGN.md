# DayCalendar

## Purpose and Scope
Day/week paging and selection composition. Parent: [CalendarUI module](../DESIGN.md). No child design units.

## Responsibilities and Boundaries
Owns day/week paging and selection composition. Applications own their data and rendering styles.

## Related Designs
| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [Module](../DESIGN.md) | parent | DayCalendar and CalendarPager | Used by Applications | Recheck callers after contract changes |
| [DateCalculation](../DateCalculation/DESIGN.md) | depends on | CalendarDates | Calendar boundaries | Use the same configured Calendar |
| [TimeCalendar](../TimeCalendar/DESIGN.md) | depends on | TimeCalendar.emptySlots | Slot and event rendering | Pass the same time zone |

## Architecture
```text
Caller -> DayCalendar -> DateCalculation / SwiftUI
```

## Contracts and Invariants
Drag/long-press callbacks retain their existing SwiftUI value type on iOS, macOS, and watchOS. tvOS cannot represent DragGesture and exposes the same calendar constructors without those callback parameters. Its date buttons and standard SwiftUI scrolling remain available. This conditional API reflects a platform capability, not a different selection or synchronization contract.

A date-only placeholder renders each empty visible time slot. Event content is forwarded to TimeCalendar. The supplied time zone controls pages, selection, and event filtering. Paging is SwiftUI-only and keeps a bounded offset range of -9999..<9999; external selections outside that window recenter the anchor. Week paging preserves the selected weekday. Page state is owned by the mounted view, and date binding is owned by the application.

## State, Ownership, and Lifecycle
Calendar calculations use local value state. SwiftUI owns mounted view state and its lifecycle. There is no shared mutable global state, externally owned resource, or asynchronous shutdown requirement.

## Failure, Concurrency, and Constraints
Nonthrowing public view construction uses explicit preconditions for invalid configuration. Invalid event periods are not rendered. Date/time calculations do not perform I/O or emit callbacks while holding a lock. The UI remains on SwiftUI's isolation boundary.

## Verification and Change Impact
[DayCalendarTests](../../../Tests/CalendarUITests/DayCalendarTests.swift) owns regression evidence. Native hosting tests verify actual view-builder invocation and scrolling. Changes to dates or time coordinates require rechecking callers and the [module](../DESIGN.md).
