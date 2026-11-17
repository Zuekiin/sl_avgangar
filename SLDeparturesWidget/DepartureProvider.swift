import Foundation
import WidgetKit
import os

/// Loads the departures for the configured station and asks WidgetKit to
/// reload after a minute.
///
/// **iOS decides when a widget actually refreshes.** The `.after(…)` policy is
/// a request, not a promise: the system budgets reloads by battery state, Low
/// Power Mode, how often the widget is seen, and time of day. A frequently
/// viewed widget typically gets a handful of reloads per hour, and far fewer
/// when the phone is idle. The board is therefore never real-time.
struct DepartureProvider: AppIntentTimelineProvider {
    typealias Entry = DepartureEntry
    typealias Intent = SelectStationIntent

    private static let logger = Logger(
        subsystem: "com.example.SLDepartures",
        category: "DepartureProvider"
    )

    /// The large Home Screen board shows the header plus up to nine rows, so
    /// fetch enough for every family; the small ones just use a prefix.
    private static let departureLimit = 10
    /// What we ask iOS for. See the type comment: this is a request only.
    private static let refreshInterval: TimeInterval = 60

    private let service = DepartureService()

    func placeholder(in context: Context) -> DepartureEntry {
        .placeholder
    }

    func snapshot(
        for configuration: SelectStationIntent,
        in context: Context
    ) async -> DepartureEntry {
        if context.isPreview {
            return .placeholder
        }
        return await loadEntry(for: configuration)
    }

    func timeline(
        for configuration: SelectStationIntent,
        in context: Context
    ) async -> Timeline<DepartureEntry> {
        let entry = await loadEntry(for: configuration)
        let refresh = Date().addingTimeInterval(Self.refreshInterval)
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func loadEntry(
        for configuration: SelectStationIntent
    ) async -> DepartureEntry {
        let siteID = configuration.effectiveSiteID

        do {
            let departures = try await service.departures(
                siteID: siteID,
                limit: Self.departureLimit
            )
            let stationName = configuration.configuredStationName
                ?? departures.first?.stopArea?.name
                ?? "Station \(siteID)"

            return DepartureEntry(
                date: .now,
                stationName: stationName,
                departures: departures,
                status: departures.isEmpty ? .noDepartures : .departures
            )
        } catch {
            Self.logger.error(
                "Could not load departures for site \(siteID, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )

            return DepartureEntry(
                date: .now,
                stationName: configuration.configuredStationName ?? "Station \(siteID)",
                departures: [],
                status: .failed
            )
        }
    }
}
