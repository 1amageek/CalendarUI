# TimeCalendar

## Purpose and Scope
Timeline rendering, empty slots, current time, and scroll anchors. Parent: [CalendarUI module](../DESIGN.md). No child design units.

## Responsibilities and Boundaries
Owns timeline rendering, empty slots, current time, and scroll anchors. Applications own their data and rendering styles.

## Related Designs
| Design | Relationship | Contract Used | Summary | Cautions |
|---|---|---|---|---|
| [Module](../DESIGN.md) | parent | TimeCalendar, PeriodRepresentable, TimeAxis, and TimelineContent | Used by DayCalendar and applications | Recheck callers after contract changes |
| [DateCalculation](../DateCalculation/DESIGN.md) | depends on | CalendarDates | Calendar boundaries | Use the same configured Calendar |
| [DayCalendar](../DayCalendar/DESIGN.md) | used by | TimeCalendar.emptySlots | Event and placeholder composition | Preserve the date-only builder contract |

## Architecture
```text
Caller -> TimeCalendar -> DateCalculation / SwiftUI
```

## Contracts and Invariants
Use one TimeAxis for events, slots, labels, current time, and scroll targets. Ranges satisfy 0 <= lower < upper <= 24; minuteInterval is 1...1440. Events use half-open periods and are clipped to the visible interval; reversed/empty/outside periods are excluded. Slots advance in elapsed minutes, so daylight-saving transitions retain all real instants. Every scroll target is the start of a rendered slot, including empty calendars and String event IDs. A periodic SwiftUI TimelineView updates the current-time line while mounted; it creates no independent scheduler or background task. Events preserve input order and may overlap; collision lanes are not part of this API.

## State, Ownership, and Lifecycle
Calendar calculations use local value state. SwiftUI owns mounted view state and its lifecycle. There is no shared mutable global state, externally owned resource, or asynchronous shutdown requirement.

## Failure, Concurrency, and Constraints
Nonthrowing public view construction uses explicit preconditions for invalid configuration. Invalid event periods are not rendered. Date/time calculations do not perform I/O or emit callbacks while holding a lock. The UI remains on SwiftUI's isolation boundary.

## Verification and Change Impact
[TimeCalendarTests](../../../Tests/CalendarUITests/TimeCalendarTests.swift) owns regression evidence. Native hosting tests verify actual view-builder invocation and scrolling. Changes to dates or time coordinates require rechecking callers and the [module](../DESIGN.md).

[FoundationIntegrationTests](../../../Tests/CalendarUITests/FoundationIntegrationTests.swift) compares slots and hour marks against Foundation date sequences across 30/60-minute clock changes. It checks placement of standard RecurrenceRule dates and closed-range end boundaries. [NativeRenderingTests](../../../Tests/CalendarUITests/NativeRenderingTests.swift) mounts events expanded by Foundation and verifies event/placeholder selection.
