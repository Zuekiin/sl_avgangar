import SwiftUI
import WidgetKit

/// The widget's board: the station name on top and its next departures below,
/// in the same amber-on-black rectangles the app uses.
///
/// Every supported family renders the same information at its own scale:
///
/// | Family | Layout |
/// | --- | --- |
/// | `.accessoryInline` | one line: station, line, destination, time |
/// | `.accessoryCircular` | line + countdown of the next departure |
/// | `.accessoryRectangular` | header + 2 rows |
/// | `.systemSmall` | header + 4 rows |
/// | `.systemMedium` | header + 5 rows |
/// | `.systemLarge` | header + 9 rows |
///
/// Every board family prints the last refresh time in its bottom-right corner
/// (the inline and circular families have no room for it). Nothing scrolls and
/// nothing animates — the system redraws this snapshot on each timeline reload.
struct DepartureWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: DepartureEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryCircular:
            circular
        default:
            board
        }
    }

    // MARK: - Board families

    private var metrics: Metrics {
        switch family {
        case .accessoryRectangular:
            Metrics(
                stationFont: BoardFont.widgetStation,
                rowFont: BoardFont.widgetRow,
                metaFont: BoardFont.widgetMeta,
                lineColumn: 18,
                timeColumn: 34,
                rowCount: 2,
                padding: 3,
                spacing: 2
            )
        case .systemMedium:
            Metrics(
                stationFont: BoardFont.widgetStationMedium,
                rowFont: BoardFont.widgetRowMedium,
                metaFont: BoardFont.meta,
                lineColumn: 26,
                timeColumn: 48,
                rowCount: 5,
                padding: 12,
                spacing: 5
            )
        case .systemLarge:
            Metrics(
                stationFont: BoardFont.station,
                rowFont: BoardFont.row,
                metaFont: BoardFont.meta,
                lineColumn: 30,
                timeColumn: 60,
                rowCount: 9,
                padding: 14,
                spacing: 6
            )
        default:
            Metrics(
                stationFont: BoardFont.widgetStationSmall,
                rowFont: BoardFont.widgetRowSmall,
                metaFont: BoardFont.widgetMeta,
                lineColumn: 22,
                timeColumn: 44,
                rowCount: 4,
                padding: 10,
                spacing: 4
            )
        }
    }

    private var board: some View {
        let metrics = metrics

        return VStack(alignment: .leading, spacing: metrics.spacing) {
            Text(entry.stationName)
                .font(metrics.stationFont)
                .lineLimit(1)
                .truncationMode(.tail)

            Rectangle()
                .fill(BoardPalette.hairline)
                .frame(height: 1)

            content(metrics)

            Spacer(minLength: 0)

            timestamp(metrics)
        }
        .foregroundStyle(BoardPalette.orange)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(metrics.padding)
        .accessibilityElement(children: .combine)
    }

    /// When the board was last refreshed, in the bottom-right corner.
    private func timestamp(_ metrics: Metrics) -> some View {
        Text("Senast \(entry.date, format: .dateTime.hour().minute())")
            .font(metrics.metaFont)
            .foregroundStyle(BoardPalette.orange.opacity(0.55))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func content(_ metrics: Metrics) -> some View {
        switch entry.status {
        case .departures where !entry.departures.isEmpty:
            VStack(alignment: .leading, spacing: metrics.spacing) {
                ForEach(
                    Array(entry.departures.prefix(metrics.rowCount).enumerated()),
                    id: \.offset
                ) { _, departure in
                    DepartureRowView(
                        departure: departure,
                        font: metrics.rowFont,
                        lineColumn: metrics.lineColumn,
                        timeColumn: metrics.timeColumn
                    )
                }
            }
        case .failed:
            VStack(alignment: .leading, spacing: metrics.spacing) {
                ForEach(0..<(family == .accessoryRectangular ? 1 : 2), id: \.self) { _ in
                    DepartureRowView(
                        departure: .mock(line: "—", destination: "—", display: "—"),
                        font: metrics.rowFont,
                        lineColumn: metrics.lineColumn,
                        timeColumn: metrics.timeColumn
                    )
                }
            }
        case .noDepartures, .departures:
            Text("Inga avgångar")
                .font(metrics.rowFont)
                .foregroundStyle(BoardPalette.orange.opacity(0.7))
                .lineLimit(1)
        case .needsConfiguration:
            Text("Välj station i widgetens inställning")
                .font(metrics.rowFont)
                .foregroundStyle(BoardPalette.orange.opacity(0.7))
                .lineLimit(2)
        }
    }

    // MARK: - Inline

    /// The inline family is a single line of text, so it shows the station and
    /// only the next departure.
    private var inline: some View {
        Text(inlineText)
    }

    private var inlineText: String {
        switch entry.status {
        case .departures:
            guard let next = entry.departures.first else {
                return "\(entry.stationName): inga avgångar"
            }
            return "\(entry.stationName): \(next.lineDesignation) \(next.destinationName) \(next.countdown)"
        case .noDepartures:
            return "\(entry.stationName): inga avgångar"
        case .failed:
            return "\(entry.stationName): kunde inte hämta"
        case .needsConfiguration:
            return "SL Avgångar: välj station"
        }
    }

    // MARK: - Circular

    /// The circular family has room for the next departure's line and
    /// countdown only.
    private var circular: some View {
        VStack(spacing: 0) {
            Text(nextDeparture?.lineDesignation ?? "—")
                .font(BoardFont.circularLine)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(nextDeparture?.countdown ?? "—")
                .font(BoardFont.circularTime)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(BoardPalette.orange)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(circularAccessibilityLabel)
    }

    private var nextDeparture: Departure? {
        entry.status == .departures ? entry.departures.first : nil
    }

    private var circularAccessibilityLabel: String {
        guard let next = nextDeparture else {
            return "SL avgångar, \(entry.stationName): inga avgångar"
        }
        return "SL avgångar, \(entry.stationName): linje \(next.lineDesignation) mot \(next.destinationName), \(next.countdown)"
    }

    // MARK: - Metrics

    private struct Metrics {
        var stationFont: Font
        var rowFont: Font
        var metaFont: Font
        var lineColumn: CGFloat
        var timeColumn: CGFloat
        var rowCount: Int
        var padding: CGFloat
        var spacing: CGFloat
    }
}

/// The board's background: black, square, on both the Lock Screen and the Home
/// Screen. The system applies its own vibrancy and corner mask on the Lock
/// Screen; the content stays amber.
struct WidgetBoardBackground: View {
    var body: some View {
        BoardPalette.background
    }
}

#Preview("Låsskärm – rektangel", as: .accessoryRectangular) {
    SLDeparturesWidget()
} timeline: {
    DepartureEntry.placeholder
}

#Preview("Låsskärm – rektangel, fel", as: .accessoryRectangular) {
    SLDeparturesWidget()
} timeline: {
    DepartureEntry.failurePreview
}

#Preview("Låsskärm – cirkel", as: .accessoryCircular) {
    SLDeparturesWidget()
} timeline: {
    DepartureEntry.placeholder
}

#Preview("Låsskärm – inline", as: .accessoryInline) {
    SLDeparturesWidget()
} timeline: {
    DepartureEntry.placeholder
}

#Preview("Hem – liten", as: .systemSmall) {
    SLDeparturesWidget()
} timeline: {
    DepartureEntry.largePreview
}

#Preview("Hem – medel", as: .systemMedium) {
    SLDeparturesWidget()
} timeline: {
    DepartureEntry.largePreview
}

#Preview("Hem – stor", as: .systemLarge) {
    SLDeparturesWidget()
} timeline: {
    DepartureEntry.largePreview
}
