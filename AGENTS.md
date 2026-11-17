# AGENT.md — SL Departures board (app + Lock Screen widget)

## Project Overview

An iOS app + WidgetKit extension that shows live SL (Stockholm public
transport) departure times. The project ships **two equal features**:

- **App** — a multi-station board: one rectangular panel per selected station,
  with the next departure in focus and the remaining departures listed below.
- **Widget** — one station in every widget slot that fits: Home Screen small,
  medium and large, and the Lock Screen rectangular, circular and inline sizes.

Both use the same visual language: **amber (`#FF8C00`) Courier text on black,
inside square-cornered rectangles**. There is no dot-matrix rendering, no LED
font, and no scrolling / marquee text anywhere. That styling was retired.

## Tech Stack

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Widgets**: WidgetKit (iOS 17+)
- **Configuration**: App Intents (`WidgetConfigurationIntent`, `AppEntity`)
- **Networking**: URLSession + async/await
- **JSON**: Codable / JSONDecoder
- **Dependencies**: None. Do not add SPM packages unless explicitly approved.

## Skill: write-swift Conventions

This project follows the `write-swift` skill's guidance. Key rules to observe:

### Concurrency & Threading
- All UI updates on `@MainActor`.
- Use `async/await`; never use `URLSession.dataTask` with completion handlers.
- Use `task {}` in SwiftUI views for async work — it auto-cancels on view
  disappearance.

### State Management
- Use `@StateObject` for objects the view creates and owns.
- Use `@ObservedObject` only for objects injected from a parent.
- Prefer the `@Observable` macro (iOS 17+) over `ObservableObject` when feasible.

### SwiftUI Patterns
- Avoid deprecated `NavigationView`; use `NavigationStack`.
- Extract expensive subviews into separate structs to prevent unnecessary
  re-evaluations.
- Use `LazyVStack`/`LazyHStack` inside `ScrollView` for lists.

### Anti-patterns to Avoid
- Massive views; keep each view focused.
- Using `@ObservedObject` to *create* a view model — use `@StateObject` instead.
- Mixing `NavigationView` and `NavigationStack` in the same hierarchy.

## Data Source (IMPORTANT)

Use **only** the official SL open API:

https://transport.integration.sl.se/v1/sites/{siteId}/departures

- No API key required.
- Returns JSON with a `departures` array.
- Relevant fields per departure:
  - `line.designation` — line number/letter (e.g. `"14"`, `"43"`, `"Pendeltåg 40"`)
  - `destination` — terminus name (e.g. `"Mörby centrum"`)
  - `display` — human-readable countdown (e.g. `"3 min"`, `"Nu"`)
  - `expected` — timestamp of expected departure
  - `scheduled` — timestamp of scheduled departure
  - `transport_mode` — `"METRO"`, `"BUS"`, `"TRAIN"`, `"TRAM"`, `"SHIP"`

`expected`/`scheduled` have no timezone offset, so they are decoded as strings
and the board shows `display` instead.

### Station list endpoint (for the pickers)

https://transport.integration.sl.se/v1/sites?expand=true

Returns an array of all stations with `id`, `name`, `abbreviation`, `lat`,
`lon`, `valid`. It ships as `Stations.json` and is cached by `StationCatalog`.

## Architecture

```
SLDepartures/
├── SLDeparturesApp.swift        # App entry + navigation bar appearance
├── ContentView.swift            # Board, panels, polling (DepartureBoardModel)
├── StationPanelView.swift       # One station's rectangular panel
├── StationPickerView.swift      # Searchable add-station sheet
├── StationSelectionStore.swift  # @AppStorage JSON selection helpers
├── WidgetSetupView.swift        # Read-only widget instructions
├── DepartureModels.swift        # Codable structs for the SL API (shared)
├── DepartureService.swift       # Async SL API client (shared)
├── StationCatalog.swift         # Bundled + cached station list (shared)
└── Stations.json                # Offline station list (shared)

Shared/                          # Compiled into BOTH targets
├── BoardTheme.swift             # Amber palette + Courier font roles
└── DepartureRowView.swift       # [line] [destination] [time] row

SLDeparturesWidget/
├── SLDeparturesWidget.swift     # @main Widget, supportedFamilies
├── DepartureProvider.swift      # AppIntentTimelineProvider
├── DepartureEntry.swift         # TimelineEntry model
├── DepartureView.swift          # Widget board + #Previews
├── SelectStationIntent.swift    # WidgetConfigurationIntent
├── StationEntity.swift          # AppEntity + EntityQuery
└── Info.plist
```

## Visual Language (applies to both targets)

- **Colours:** amber `#FF8C00` text (`BoardPalette.orange`) on black
  (`BoardPalette.background`); panels are `BoardPalette.panel` with a 1 pt
  amber hairline (`BoardPalette.hairline`).
- **Font:** Courier / Courier-Bold at `.body`, `.callout`, `.caption` sizes
  (`BoardFont`). Do not use `.system(design: .monospaced)` and do not add a
  bitmap or dot-matrix font.
- **Corners:** square only. Use `Rectangle`; never capsules, pills or
  `RoundedRectangle` with a visible radius.
- **No motion:** no marquee, ticker, scrolling text, or animated offsets.
- **Row format:** `[line designation] [destination] [time]`, time
  right-aligned, destination tail-truncated. Use `DepartureRowView` in both
  targets instead of writing another row layout.

## Widget Behavior

- **Families**: `.systemSmall`, `.systemMedium`, `.systemLarge` (Home Screen)
  and `.accessoryRectangular`, `.accessoryCircular`, `.accessoryInline` (Lock
  Screen). Do **not** add `.systemExtraLarge`, `.systemExtraLargePortrait`
  (iPad-only) or `.accessoryCorner` (watchOS).
- **Layouts**:
  - rectangular: header + 2 rows; small: 4 rows; medium: 5 rows; large: 9 rows;
  - circular: the next departure's line and countdown only;
  - inline: a single `Text`, because that family renders one line
    ("T-Centralen: 14 Mörby centrum 3 min").
- **Last refresh:** every board family shows "Senast HH:mm" in the bottom-right
  corner (via a `Spacer` + trailing-aligned caption). The circular and inline
  families have no room for it.
- **Required:** `.containerBackground(for: .widget)` with the black board
  background, or the widget will not render on iOS 17+.

## Configuration (App Intents)

### `SelectStationIntent`
- Conforms to `WidgetConfigurationIntent`.
- Single `@Parameter` of type `StationEntity`.
- `static var parameterSummary` shows "Departures for \(\.$station)".
- Default value: T-Centralen (`9001`).

### `StationEntity`
- Conforms to `AppEntity`; `id` is the short numeric site ID (e.g. `3685`).
- `static var typeDisplayRepresentation` = "Station".
- `static var defaultQuery = StationQuery()`.

### `StationQuery`
- Conforms to `EntityQuery` (or `EnumerableEntityQuery` if feasible).
- Reads from `StationCatalog`, which caches the bundled list in memory and on
  disk.
- On failure, return an empty list and log — never crash or force-unwrap.

## Timeline / Refresh

- `AppIntentTimelineProvider`.
- `placeholder(in:)` returns a mock entry.
- `snapshot(for:in:)` returns the loaded entry (a mock in previews).
- `timeline(for:in:)` fetches and returns one entry with
  `.after(Date().addingTimeInterval(60))`.
- **Document in code and README**: iOS throttles widget refreshes. 60 seconds
  is a request, not a guarantee — typically a handful of reloads per hour for a
  frequently viewed widget. Never claim real-time updates.

## App Refresh

- Poll every 45 seconds while `scenePhase == .active`; cancel on background.
- Footer: "Last updated HH:MM".
- A failed fetch keeps the last known departures on screen and shows a small
  amber `!` next to the timestamp (footer and panel header).

## App Interaction

- The board's title bar is a normal view (`titleBar`) pinned above the `List`,
  with the navigation bar hidden. Do not switch back to `.navigationTitle` —
  the large title scrolls away, which is exactly what the pinned header avoids.
- Panels are rows of a `List`, which is required for the two gestures below.
- **Delete:** `.swipeActions(edge: .trailing, allowsFullSwipe: false)` with a
  `role: .destructive` button. Do not add a visible "×" button back into the
  panel header.
- **Reorder:** `ForEach.onMove` on the boards collection. Write the new order
  to `@AppStorage` and reorder the visible sections with
  `DepartureBoardModel.retain(ids:)`.

## Error Handling

- Network/decoding errors → keep previous data; panel shows "Kunde inte hämta"
  when there is nothing to keep.
- Empty `departures` array → "Inga avgångar".
- Widget failure → dashes plus "Senast HH:mm".
- Never force-unwrap.

## Code Style

- Swift API Design Guidelines.
- One type per file where reasonable; shared views live in `Shared/`.
- Comments in English; user-facing UI text in Swedish where natural (with the
  English empty state and footer wording the product spec asks for).
- Use `async/await` for networking — no completion handlers.
- Prefer `struct` over `class`.
- Mark widget types `@main` only once (the widget extension entry).

## Testing

- Use Xcode Previews for the row, the panel and the widget states.
- Test on a physical device for Lock Screen rendering and refresh behaviour.
- Test configuration flow: add widget → long-press → Edit Widget → pick a
  different station → confirm the widget updates.
- Test adding/removing stations and the Airplane Mode failure state.

## Out of Scope

- Live Activities / Dynamic Island (ActivityKit).
- Watch complications.
- iPad-only widget sizes (`.systemExtraLarge`, `.systemExtraLargePortrait`) and
  the watchOS `.accessoryCorner` family.
- Journey planning / routing.
- Push notifications for delays.
- Multi-station widgets (single station per widget instance is fine).
- Any marquee / scrolling-text treatment, and any dot-matrix or bitmap font.

## Common Pitfalls (for AI agents)

1. **Do not confuse the two SL ID formats.** Use the short API site ID
   (e.g. `3685`), not the long Stop Lookup ID (e.g. `300109001`).
2. **Do not omit `containerBackground`** — required for iOS 17+ widgets.
3. **Do not use `URLSession.shared.dataTask`** — use `URLSession.shared.data(from:)`.
4. **Do not hardcode a station ID in the production path** — the station comes
   from `configuration.station`. Mock IDs only in `placeholder` / previews.
5. **Do not attempt the t-skylt.se endpoint** — see the warning above.
6. **Do not promise real-time refresh** — iOS controls widget update cadence.
7. **Do not use the legacy `IntentTimelineProvider`** — use
   `AppIntentTimelineProvider`.
8. **Cache the station list** — do not re-fetch `/v1/sites` per keystroke.
9. **Do not reintroduce `DotMatrix`, `BitmapFont` or marquee/ticker code.**
   That styling is retired in both targets; use `DepartureRowView`.
10. **Do not add rounded corners or capsules** — the design is square
    rectangles only.
11. **Do not create view models with `@ObservedObject`** — use `@StateObject`.
12. **Do not mix `NavigationView` and `NavigationStack`.**
13. **Do not move the stations back into a `ScrollView`/`LazyVStack`.** The
    panels must stay `List` rows — `.swipeActions` and `ForEach.onMove` only
    work on list rows.

## Definition of Done

- [ ] Project compiles for iOS 17+ without warnings.
- [ ] Widget extension installs and appears in the Lock Screen widget gallery.
- [ ] Widget renders amber Courier rows (header + 2 departures) for the
      selected station.
- [ ] Long-press → Edit Widget shows a searchable station picker.
- [ ] App renders one rectangular panel per station: header, next departure,
      remaining departures.
- [ ] Stations can be added and removed; the selection survives launches.
- [ ] A panel can be swiped left to delete it and long-pressed/dragged to
      reorder the board, with the new order persisted.
- [ ] Footer shows "Last updated HH:MM"; network failure keeps data and shows
      the amber `!`.
- [ ] `#Preview` works with mock data in Xcode.
- [ ] App Intents metadata still contains `SelectStationIntent`,
      `StationEntity` and `StationQuery`.
- [ ] No references to `DotMatrix`, `BitmapFont`, `TickerRow` or
      `data.t-skylt.se` anywhere in the codebase.
- [ ] README presents the app and the widget as equal features with the shared
      amber-on-black design language.
