import SwiftUI

/// Sheet for adding a station to the board.
///
/// Search runs against the bundled `StationCatalog`, so it works offline and
/// matches on names — never on the numeric site ID. The list follows the same
/// orange-on-black board language as the panels.
struct StationPickerView: View {
    /// Stations already on the board, shown as disabled.
    let existingIDs: Set<String>
    let onPick: (Station) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var stations: [Station] = []

    var body: some View {
        NavigationStack {
            List(stations, id: \.id) { station in
                let isAdded = existingIDs.contains(station.id)

                Button {
                    onPick(station)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(station.name)
                                .font(BoardFont.row)
                                .foregroundStyle(
                                    BoardPalette.orange.opacity(isAdded ? 0.45 : 1)
                                )

                            Text(subtitle(for: station))
                                .font(BoardFont.meta)
                                .foregroundStyle(BoardPalette.orange.opacity(0.55))
                        }

                        Spacer(minLength: 8)

                        if isAdded {
                            Text("TILLAGD")
                                .font(BoardFont.widgetMeta)
                                .foregroundStyle(BoardPalette.orange.opacity(0.55))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .disabled(isAdded)
                .listRowBackground(BoardPalette.panel)
                .listRowSeparatorTint(BoardPalette.hairline)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(BoardPalette.background)
            .overlay {
                if stations.isEmpty {
                    Text("Inga träffar")
                        .font(BoardFont.row)
                        .foregroundStyle(BoardPalette.orange.opacity(0.6))
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Sök station"
            )
            .navigationTitle("Välj station")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Klar") { dismiss() }
                }
            }
            .task(id: query) {
                await search()
            }
        }
        .tint(BoardPalette.orange)
        .preferredColorScheme(.dark)
    }

    /// The station's stop note when there is one, otherwise the site ID — two
    /// stops often share a name, so the subtitle disambiguates them.
    private func subtitle(for station: Station) -> String {
        guard let note = station.note, !note.isEmpty else {
            return "ID \(station.id)"
        }
        return note
    }

    private func search() async {
        // Let typing settle instead of querying on every keystroke; the
        // `.task(id:)` cancels this when the query changes again.
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else { return }

        let matches = await StationCatalog.shared.stations(matching: query)
        guard !Task.isCancelled else { return }
        stations = matches
    }
}

#Preview {
    StationPickerView(existingIDs: ["9001"]) { _ in }
}
