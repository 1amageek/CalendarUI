# DateCalculation

## Purpose and Scope
Date enumeration and boundaries. Parent: [CalendarUI module](../DESIGN.md). No child design units.

## Responsibilities and Boundaries
Owns date enumeration and boundaries. Applications own their data and rendering styles.

## Related Designs
| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [Module](../DESIGN.md) | parent | CalendarDates | Used by MonthCalendar, WeekCalendar, DayCalendar, and TimeCalendar | Recheck callers after contract changes |
| [MonthCalendar](../MonthCalendar/DESIGN.md) | used by | CalendarDates | Complete month grids | Preserve requested time zone |
| [WeekCalendar](../WeekCalendar/DESIGN.md) | used by | CalendarDates | Week boundaries | Preserve calendar weekday rules |
| [DayCalendar](../DayCalendar/DESIGN.md) | used by | CalendarDates | Page boundaries | Preserve selection identity |
| [TimeCalendar](../TimeCalendar/DESIGN.md) | used by | CalendarDates | Day boundaries | Preserve daylight-saving transitions |

## Architecture
```text
Caller -> DateCalculation -> Foundation.Calendar
```

## Contracts and Invariants
Use Calendar.dateInterval for month/week/day boundaries and retain the requested time zone. Invalid dates fail explicit preconditions. Month grids cover complete weeks. Foundation's Calendar.dates(byAdding:startingAt:in:) owns bounded day enumeration. The component owns the enclosing week range and explicitly includes its first date because the standard sequence starts after its anchor. This keeps additions anchored to the original date across midnight clock changes, rather than accumulating a shifted hour after one nonexistent midnight.

## State, Ownership, and Lifecycle
Calendar calculations use local value state. SwiftUI owns mounted view state and its lifecycle. There is no shared mutable global state, externally owned resource, or asynchronous shutdown requirement.

## Failure, Concurrency, and Constraints
Nonthrowing public view construction uses explicit preconditions for invalid configuration. Invalid event periods are not rendered. Date/time calculations do not perform I/O or emit callbacks while holding a lock. The UI remains on SwiftUI's isolation boundary.

## Verification and Change Impact
[CalendarDatesTests](../../../Tests/CalendarUITests/CalendarDatesTests.swift) owns regression evidence. Native hosting tests verify actual view-builder invocation and scrolling. Changes to dates or time coordinates require rechecking callers and the [module](../DESIGN.md).

[FoundationIntegrationTests](../../../Tests/CalendarUITests/FoundationIntegrationTests.swift) independently compares month grids against Foundation's date sequences, including leap years, year boundaries, and different first weekdays. It also proves why the half-open overlap policy cannot be replaced directly with DateInterval's closed-interval intersection.

The standard-sequence migration preserves complete-week boundaries and requested-zone dates. A midnight daylight-saving transition is also checked against each date's calendar startOfDay, preventing drift into later days. Recheck MonthCalendar and DayCalendar after changes to this enumeration contract.
