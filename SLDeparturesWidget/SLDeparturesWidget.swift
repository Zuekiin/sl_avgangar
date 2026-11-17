import SwiftUI
import WidgetKit

@main
struct SLDeparturesWidget: Widget {
    static let kind = "SLDeparturesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: SelectStationIntent.self,
            provider: DepartureProvider()
        ) { entry in
            DepartureWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetBoardBackground()
                }
        }
        .configurationDisplayName("SL Avgångar")
        .description("Nästa avgångar från valfri SL-station.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular
        ])
    }
}
