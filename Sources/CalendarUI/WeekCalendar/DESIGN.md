# WeekCalendar

## Purpose and Scope
Week grid composition and positive time intervals. Parent: [CalendarUI module](../DESIGN.md). No child design units.

## Responsibilities and Boundaries
Owns week grid composition and positive time intervals. Applications own their data and rendering styles.

## Related Designs
| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [Module](../DESIGN.md) | parent | WeekCalendar and Interval | Used by Applications | Recheck callers after contract changes |
| [DateCalculation](../DateCalculation/DESIGN.md) | depends on | CalendarDates | Calendar boundaries | Use the same configured Calendar |

## Architecture
```text
Caller -> WeekCalendar -> DateCalculation / SwiftUI
```

## Contracts and Invariants
weekOfMonth is the zero-based offset from the week containing the first day of the month. Every positive interval emits all starts before the end of a civil day, including a partial final section. Count and time calculations use the same unmodified interval. Values must be positive; arithmetic is bounded to one day before multiplication.

## State, Ownership, and Lifecycle
Calendar calculations use local value state. SwiftUI owns mounted view state and its lifecycle. There is no shared mutable global state, externally owned resource, or asynchronous shutdown requirement.

## Failure, Concurrency, and Constraints
Nonthrowing public view construction uses explicit preconditions for invalid configuration. Invalid event periods are not rendered. Date/time calculations do not perform I/O or emit callbacks while holding a lock. The UI remains on SwiftUI's isolation boundary.

## Verification and Change Impact
[WeekCalendarTests](../../../Tests/CalendarUITests/WeekCalendarTests.swift) owns regression evidence. Native hosting tests verify actual view-builder invocation and scrolling. Changes to dates or time coordinates require rechecking callers and the [module](../DESIGN.md).
