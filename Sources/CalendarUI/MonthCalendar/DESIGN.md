# MonthCalendar

## Purpose and Scope
Month grid composition. Parent: [CalendarUI module](../DESIGN.md). No child design units.

## Responsibilities and Boundaries
Owns month grid composition. Applications own their data and rendering styles.

## Related Designs
| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [Module](../DESIGN.md) | parent | MonthCalendar | Used by Applications | Recheck callers after contract changes |
| [DateCalculation](../DateCalculation/DESIGN.md) | depends on | CalendarDates | Calendar boundaries | Use the same configured Calendar |

## Architecture
```text
Caller -> MonthCalendar -> DateCalculation / SwiftUI
```

## Contracts and Invariants
The month and its complete surrounding weeks are calculated using one configured Calendar. Content receives each date once. Header receives zero-based column indexes in that Calendar's weekday order. Both initializers use the same implementation.

## State, Ownership, and Lifecycle
Calendar calculations use local value state. SwiftUI owns mounted view state and its lifecycle. There is no shared mutable global state, externally owned resource, or asynchronous shutdown requirement.

## Failure, Concurrency, and Constraints
Nonthrowing public view construction uses explicit preconditions for invalid configuration. Invalid event periods are not rendered. Date/time calculations do not perform I/O or emit callbacks while holding a lock. The UI remains on SwiftUI's isolation boundary.

## Verification and Change Impact
[MonthCalendarTests](../../../Tests/CalendarUITests/MonthCalendarTests.swift) owns regression evidence. Native hosting tests verify actual view-builder invocation and scrolling. Changes to dates or time coordinates require rechecking callers and the [module](../DESIGN.md).
