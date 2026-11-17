import SwiftUI

/// One station's board in the app: a square-cornered rectangle with the
/// station name at the top, the next departure emphasised below it, and the
/// remaining departures as a plain static list.
///
/// The panel has no animation, no scrolling text and no rounded corners; it
/// only changes when new departures arrive.
struct StationPanelView: View {
    let name: String
    let departures: [Departure]
    /// Non-nil when the most recent refresh for this station failed. The
    /// previous departures stay on screen and a small "!" appears in the
    /// header.
    let errorMessage: String?

    /// The next departure plus at most six more.
    private let maxRows = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Rectangle()
                .fill(BoardPalette.hairline)
                .frame(height: 1)
            content
        }
        .background(BoardPalette.panel)
        .overlay {
            Rectangle()
                .strokeBorder(BoardPalette.hairline, lineWidth: 1)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(name)
                .font(BoardFont.station)
                .lineLimit(1)
                .truncationMode(.tail)

            if errorMessage != nil {
                Text("!")
                    .font(BoardFont.station)
                    .accessibilityLabel("Uppdateringen misslyckades")
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(BoardPalette.orange)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if let next = departures.first {
            VStack(alignment: .leading, spacing: 0) {
                DepartureRowView(
                    departure: next,
                    font: BoardFont.prominent,
                    lineColumn: 34,
                    timeColumn: 66
                )
                .padding(.bottom, 10)

                let remaining = Array(departures.dropFirst().prefix(maxRows - 1))
                if !remaining.isEmpty {
                    Rectangle()
                        .fill(BoardPalette.hairline)
                        .frame(height: 1)
                        .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(Array(remaining.enumerated()), id: \.offset) { _, departure in
                            DepartureRowView(departure: departure)
                        }
                    }
                }
            }
            .padding(14)
        } else {
            Text(errorMessage == nil ? "Inga avgångar" : "Kunde inte hämta")
                .font(BoardFont.row)
                .foregroundStyle(BoardPalette.orange.opacity(0.7))
                .padding(14)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            StationPanelView(
                name: "T-Centralen",
                departures: [
                    .mock(line: "14", destination: "Mörby centrum", display: "3 min"),
                    .mock(line: "13", destination: "Ropsten", display: "7 min"),
                    .mock(line: "19", destination: "Hagsätra", display: "Nu"),
                    .mock(line: "11", destination: "Akalla", display: "11 min")
                ],
                errorMessage: nil
            )

            StationPanelView(
                name: "Karlsbodavägen",
                departures: [
                    .mock(line: "30", destination: "Solna station", display: "4 min", mode: .bus)
                ],
                errorMessage: "Nätverket svarade inte"
            )
        }
        .padding()
    }
    .background(BoardPalette.background)
    .preferredColorScheme(.dark)
}
