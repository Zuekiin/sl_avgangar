import Foundation
import WidgetKit

/// Everything the widget needs to render one moment in time.
///
/// The widget is a static board: the station name and the next few departures.
/// There is no scrolling text — the provider hands over one entry and the
/// system redraws it when the timeline asks for a fresh one.
struct DepartureEntry: TimelineEntry {
    enum Status: Equatable, Sendable {
        case departures
        case noDepartures
        case failed
        case needsConfiguration
    }

    let date: Date
    let stationName: String
    let departures: [Departure]
    let status: Status
}

extension DepartureEntry {
    static let placeholder = DepartureEntry(
        date: .now,
        stationName: "T-Centralen",
        departures: [
            .mock(line: "14", destination: "Mörby centrum", display: "3 min"),
            .mock(line: "13", destination: "Ropsten", display: "7 min"),
            .mock(line: "19", destination: "Hagsätra", display: "Nu"),
            .mock(line: "11", destination: "Akalla", display: "5 min")
        ],
        status: .departures
    )

    static let failurePreview = DepartureEntry(
        date: .now,
        stationName: "T-Centralen",
        departures: [],
        status: .failed
    )

    static let emptyPreview = DepartureEntry(
        date: .now,
        stationName: "T-Centralen",
        departures: [],
        status: .noDepartures
    )

    /// A full Home Screen board for the previews.
    static let largePreview = DepartureEntry(
        date: .now,
        stationName: "T-Centralen",
        departures: [
            .mock(line: "14", destination: "Mörby centrum", display: "3 min"),
            .mock(line: "13", destination: "Ropsten", display: "7 min"),
            .mock(line: "19", destination: "Hagsätra", display: "Nu"),
            .mock(line: "11", destination: "Akalla", display: "4 min"),
            .mock(line: "10", destination: "Hjulsta", display: "9 min"),
            .mock(line: "18", destination: "Farsta strand", display: "12 min")
        ],
        status: .departures
    )
}
