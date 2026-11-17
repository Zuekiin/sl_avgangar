# SL Avgångar — departure board app + Lock Screen widget

An iOS 17+ app and widget for live Stockholm SL departures. The project ships
**two equal features** that share one look:

| | What it does |
|---|---|
| **App** | A multi-station board. Add any number of stations; each is its own panel with the next departure in focus and the remaining ones listed below. Polls every 45 seconds while open. |
| **Widget** | One station in every widget slot that fits: Home Screen small, medium and large, plus the Lock Screen rectangular, circular and inline sizes. Same panel, same colours. |

```
App                                        Widget (Lock Screen / Home Screen)
┌───────────────────────────────┐          ┌────────────────────────────────┐
│ T-Centralen                   │          │ T-Centralen                    │
│ ───────────────────────────── │          │ ────────────────────────────── │
│ 192  Stockholm C         Nu   │          │ 192  Stockholm C          Nu   │
│ ───────────────────────────── │          │ 191  Norsborg          7 min   │
│ 191  Norsborg          7 min  │          └────────────────────────────────┘
│ 195  Hagsätra         17 min  │
│ 193  Stockholm C      19 min  │
└───────────────────────────────┘
```

- **Configuration:** App Intents + a searchable `AppEntity` picker (widget);
  a searchable sheet in the app
- **Data:** the official SL open API, no key required
- **Dependencies:** none

## The shared look

Both surfaces are the same board:

- **Amber on black.** Text is `#FF8C00`; the background is black and each panel
  is a slightly lifted near-black (`Color(white: 0.06)`) with a 1 pt amber
  hairline border.
- **Courier.** Every string uses `Courier` / `Courier-Bold` at `.body`,
  `.callout` and `.caption` sizes, in the app and in the widget.
- **Square corners.** Panels, borders and step badges are `Rectangle`s. There
  are no capsules, pills or rounded cards anywhere.
- **Rows read `[line] [destination] [time]`.** The line takes a fixed minimum
  width, the destination fills the middle and truncates at its tail, and the
  time is right-aligned in its own column.
- **Nothing moves.** No marquee, no ticker, no scrolling text, no animation.
  The board is static; it changes only when new data arrives.

The palette and the font roles live in `Shared/BoardTheme.swift`, and the row
itself is `Shared/DepartureRowView.swift` — the same code renders the app's
panels and the widget's rows.

## Requirements

- Xcode 15 or newer (iOS 17 SDK)
- An iPhone running iOS 17 or newer
- A physical iPhone for final widget QA — the simulator can install widgets,
  but Lock Screen rendering and refresh timing differ from a device

## Quick start

1. Open `SLDepartures.xcodeproj`.
2. Select the **SLDepartures** target → **Signing & Capabilities**, choose your
   development team, and change the bundle identifier from the placeholder
   `com.example.SLDepartures`. Do the same for **SLDeparturesWidget**, keeping
   the app's identifier as its prefix, for example:
   - App: `com.yourname.SLDepartures`
   - Widget: `com.yourname.SLDepartures.widget`
3. Run the app on your iPhone once. This installs the app and its widget
   extension.
4. In the app, tap **+** to add stations by name.

## The app

- **Navigation:** a `NavigationStack`. The root is the board; the gear button
  opens **Widget Setup**, and **+** opens the station picker. The title bar
  ("Avgångar" + the two buttons) is drawn by the app above the list rather than
  by the navigation bar, so it stays on screen while the board scrolls.
- **Panels:** one square-cornered panel per station.
  - Header: the station name, plus an amber **!** if that station's last
    refresh failed.
  - Next departure: larger `Courier-Bold` in the row format.
  - Remaining departures: up to six more rows in the standard size, below a
    hairline rule.
- **Adding and removing:** **+** opens a searchable sheet backed by
  `StationCatalog`. Swipe a panel to the left to reveal a red **Ta bort**
  action; the swipe stops short of a full-swipe delete, so a fast flick cannot
  remove a station by accident.
- **Reordering:** long-press a panel and drag it to a new position. The new
  order is written to `@AppStorage` and the board reorders immediately.
- **Rows:** panels are `List` rows, which is what makes both the swipe action
  and the drag-to-reorder gesture possible.
- **Persistence:** the selection is a JSON array of site IDs in `@AppStorage`
  under the key `selectedStations`, so it survives launches.
- **Live data:** an async polling loop every 45 seconds while the app is in the
  foreground; leaving the app (`scenePhase`) cancels it. The same loop restarts
  when the station list changes.
- **Footer:** "Last updated HH:MM". If a refresh fails, the last known
  departures stay on screen and a small amber **!** appears next to the
  timestamp — the board never blanks out.
- **Empty state:** "No stations yet" / "Tap + to add one."

## The widget

1. Lock the phone, long-press the Lock Screen, tap **Anpassa**, choose
   **Låsskärm**, tap the widget area, and add **SL Avgångar**.
2. Long-press the widget → **Redigera widget** → tap **Station** and search by
   name.

The widget shows the same amber-on-black board at whatever size it was added:

| Family | Content |
| --- | --- |
| `.accessoryRectangular` (Lock Screen) | Station header + 2 departures |
| `.accessoryCircular` (Lock Screen) | Next departure's line and countdown |
| `.accessoryInline` (Lock Screen) | One line: station, line, destination, time |
| `.systemSmall` (Home Screen) | Station header + 4 departures |
| `.systemMedium` (Home Screen) | Station header + 5 departures |
| `.systemLarge` (Home Screen) | Station header + 9 departures |

Every board size also prints the last refresh time ("Senast HH:mm") in its
bottom-right corner, so an old snapshot is obvious at a glance. The circular and
inline families are too small for it and show just the departure.

Every size is configured through `SelectStationIntent` / `StationEntity` /
`StationQuery`. The iPad-only `.systemExtraLarge` sizes and the watchOS
`.accessoryCorner` are deliberately not offered.

### Refresh

`DepartureProvider` asks WidgetKit to reload after **60 seconds**:

```swift
Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
```

**That is a request, not a guarantee.** iOS budgets widget reloads by battery
state, Low Power Mode, how often the widget is on screen, and time of day. A
frequently viewed widget typically gets a handful of reloads per hour, and far
fewer when the phone is idle. The widget is not a real-time board.

### Failure state

A failed fetch shows the station name, a row of dashes and the usual
"Senast HH:mm" in the corner, so the widget still looks like a board instead of
an error page.

## Choosing a station

Both pickers search the same bundled list:

- names match case-, space- and diacritic-insensitively ("T Centralen",
  "t-centralen" and "Tcentralen" all work);
- common stations come first (T-Centralen, Slussen, Odenplan, …);
- the full `/v1/sites?expand=true` list ships with the app and the widget, so
  search is instant and works offline;
- the list refreshes in the background and is cached on disk for 24 hours.

The widget's default station is **T-Centralen**. The app starts empty by
design, so you choose what to follow.

## API

Only the official SL API is used:

- Departures: `https://transport.integration.sl.se/v1/sites/{siteId}/departures`
- Stations: `https://transport.integration.sl.se/v1/sites?expand=true`

No API key is required.

### Notes from the live response

- `transport_mode` is nested inside `line` (the decoder also tolerates a
  top-level value).
- The `line` object has **no color fields**, which is why the board uses a
  single amber for every line instead of per-line colours.
- `expected` and `scheduled` are local Stockholm timestamps **without a
  timezone offset** (`2026-11-16T02:37:54`). `JSONDecoder`'s `.iso8601`
  strategy rejects that format, so those fields are decoded as `String?` and
  the server's `display` field is shown instead.
- The site list contains ~6,500 stops, including bus stops and platforms. The
  full list is bundled (`Stations.json`) and refreshed from the API, so the
  pickers work without network access. The note field, when present, is the
  picker subtitle that disambiguates stops with the same name.

## Project layout

```
SLDepartures.xcodeproj
├── project.pbxproj
└── xcshareddata/xcschemes/SLDepartures.xcscheme

SLDepartures/                      # app target
├── SLDeparturesApp.swift          # @main App + navigation bar appearance
├── ContentView.swift              # board, panels, polling (DepartureBoardModel)
├── StationPanelView.swift         # one station's rectangular panel
├── StationPickerView.swift        # searchable "add station" sheet
├── StationSelectionStore.swift    # @AppStorage JSON selection helpers
├── WidgetSetupView.swift          # widget instructions (read-only)
├── DepartureModels.swift          # shared data layer (also in the widget)
├── DepartureService.swift         # shared async URLSession client
├── StationCatalog.swift           # shared bundled + cached station list
├── Stations.json                  # shared offline station list (~6,500 stops)
└── Assets.xcassets/               # app icon + accent color

Shared/                            # compiled into BOTH targets
├── BoardTheme.swift               # amber palette + Courier font roles
└── DepartureRowView.swift         # [line] [destination] [time] row

SLDeparturesWidget/                # widget extension target
├── SLDeparturesWidget.swift       # @main Widget, families, containerBackground
├── DepartureProvider.swift        # AppIntentTimelineProvider (.after(60))
├── DepartureEntry.swift           # TimelineEntry + mock data
├── DepartureView.swift            # widget board + #Previews
├── SelectStationIntent.swift      # WidgetConfigurationIntent
├── StationEntity.swift            # AppEntity + EntityStringQuery
└── Info.plist                     # widgetkit-extension
```

## Implementation notes

- **Concurrency:** all networking uses `async/await` and
  `URLSession.data(for:)`; there are no completion handlers. The station cache
  is an `actor`; the board model is `@Observable` and `@MainActor`. The code
  also typechecks under Swift 6 strict concurrency.
- **Row layout:** `DepartureRowView` pins the time column to the trailing edge
  with a minimum width and gives the destination `maxWidth: .infinity` plus
  `.truncationMode(.tail)`. Long designations such as "Pendeltåg 40" widen the
  line column instead of being truncated.
- **Error handling:** a failed fetch keeps the previous departures in the
  panel and raises the amber **!**; the widget renders dashes plus a
  "Senast HH:MM" hint. Nothing force-unwraps or crashes.
- **No scrolling text anywhere:** the earlier dot-matrix LED board and the
  marquee are gone. `DotMatrix.swift`, `BitmapFont.swift` and `TickerRow.swift`
  are deleted, and neither the app nor the widget links a bitmap font.
- **One design source:** `BoardTheme.swift` holds the amber, the black and the
  Courier roles; both targets compile it, so the two surfaces cannot drift.
- **Board rows:** each station panel is a `List` row, so
  `.swipeActions(edge: .trailing)` can delete it and `ForEach.onMove` can
  reorder it. A move rewrites the stored ID array (`@AppStorage`) and calls
  `DepartureBoardModel.retain(ids:)`, so the board reflects the new order
  before the next poll.

## Xcode Previews and testing

- `DepartureRowView.swift` — fitting row, long destination, long designation.
- `StationPanelView.swift` — a full panel and a panel whose refresh failed.
- `DepartureView.swift` — widget families, failure and empty states.
- `WidgetSetupView.swift` — the help screen.

**App:** run it, tap **+**, add two stations, and confirm each renders as its
own panel. Swipe a panel left to delete it; long-press and drag a panel to
reorder the board. Neither gesture is available on a plain `ScrollView`, so the
panels live in a `List` row.

**Widget:** install on a physical device, add it to the Lock Screen, then pick
a station by name. Widget reload timing cannot be forced from the app; the
system controls it.

**Failure state:** turn on Airplane Mode, wait for the next poll, and confirm
the last departures stay on screen with the amber **!** next to the timestamp.

## Demo screenshots

The following screenshots were captured on real devices (iPhone 17 Pro simulator):

- **`Screenshot_iPhone_1.png`** — App board with no stations yet ("Inga avgångar") and the empty-state message.
- **`Screenshot_iPhone_2.png`** — App board with two stations selected (T-Centralen + Karlsbodavägen), live departures, footer **"Uppdaterad 01:37"**.
- **Widget – Lock Screen** — amber Courier rows on the black background (`.accessoryRectangular`).
- **Widget – Home Screen small** — same board at `.systemSmall`.
- **Widget – Home Screen medium** — same board at `.systemMedium`.
- **Widget – Home Screen large** — same board at `.systemLarge`.
- **Widget failure** — dashes plus amber **"Senast HH:mm"** hint in the corner.
- **Swipe-to-delete** — tap the trailing row to reveal a red destructive trash button.
- **Long-press / drag reorder** — long-press a panel and drag it to reorder the board instantly.

All images were taken with Xcode Previews and the simulator's default display settings.

## Known limitations

- **Widget refresh cadence is system-controlled**, as described above. The
  app's 45-second poll only runs while the app is in the foreground.
- **The widget shows one station.** The app is where several stations live.
- **iPad-only and watchOS sizes are not offered.** `.systemExtraLarge`,
  `.systemExtraLargePortrait` and `.accessoryCorner` are out of scope for this
  iPhone app.
- **Lock Screen colour is partly the system's.** The widget sets amber on
  black, but iOS applies its own vibrancy and translucency on the Lock Screen;
  the exact tone depends on the wallpaper.
- **No line colours** — the API does not expose them.
- **Search is local**: the full station list ships with the app and the widget,
  so both pickers work offline and search by name.
- The bundle identifiers and signing team are placeholders and must be changed
  before running on a device.
