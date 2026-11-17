import AppIntents
import Foundation

/// Widget configuration intent shown when the user edits the widget.
///
/// The station is chosen exclusively from a searchable entity picker, so the
/// user never has to know SL's numeric site IDs.
struct SelectStationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Välj station"
    static let description = IntentDescription(
        "Visar nästa avgångar för en SL-station."
    )

    @Parameter(
        title: "Station",
        description: "SL-stationen som widgeten visar avgångar för."
    )
    var station: StationEntity

    init() {
        station = .tCentralen
    }

    init(station: StationEntity) {
        self.station = station
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Avgångar för \(\.$station)")
    }

    /// The site ID used by the departures endpoint, with T-Centralen as a
    /// last-resort fallback for an empty value.
    var effectiveSiteID: String {
        let id = station.id
        return id.isEmpty ? StationEntity.tCentralen.id : id
    }

    /// The station name to show in the widget header.
    var configuredStationName: String? {
        let name = station.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }
}
