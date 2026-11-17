import Observation
import SwiftUI

/// The app's main screen: one rectangular panel per selected station, each
/// showing its next departures as a static list.
///
/// The Lock Screen widget is a separate, equal feature. Both surfaces use the
/// same orange-on-black board language (see `BoardTheme.swift`), and neither
/// scrolls its text.
struct ContentView: View {
    @AppStorage(StationSelectionStore.key) private var selectionJSON = "[]"
    @Environment(\.scenePhase) private var scenePhase

    @State private var board = DepartureBoardModel()
    @State private var isPickingStation = false

    private var stationIDs: [String] {
        StationSelectionStore.load(from: selectionJSON)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // A fixed header instead of a navigation-title: the title has
                // to stay on screen while the board scrolls.
                titleBar
                content
            }
            .background(BoardPalette.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isPickingStation) {
                StationPickerView(existingIDs: Set(stationIDs)) { station in
                    add(station)
                }
            }
        }
        .tint(BoardPalette.orange)
        .preferredColorScheme(.dark)
        .task(id: pollingKey) {
            guard scenePhase == .active else { return }
            await board.poll(stationIDs: stationIDs)
        }
        .onChange(of: stationIDs) { _, ids in
            board.retain(ids: ids)
        }
    }

    /// Always-visible board header: title on the left, add and setup buttons on
    /// the right, on the same black background as the panels.
    private var titleBar: some View {
        HStack(spacing: 4) {
            Text("Avgångar")
                .font(BoardFont.title)
                .foregroundStyle(BoardPalette.orange)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                isPickingStation = true
            } label: {
                titleBarIcon("plus")
            }
            .accessibilityLabel("Lägg till station")

            NavigationLink {
                WidgetSetupView()
            } label: {
                titleBarIcon("gearshape")
            }
            .accessibilityLabel("Widget")
        }
        .padding(.horizontal, 12)
        .padding(.top, 2)
        .padding(.bottom, 4)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .background(BoardPalette.background)
    }

    private func titleBarIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 19, weight: .medium))
            .foregroundStyle(BoardPalette.orange)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }

    @ViewBuilder
    private var content: some View {
        if stationIDs.isEmpty {
            emptyState
        } else if board.boards.isEmpty {
            loadingState
        } else {
            boardList
        }
    }

    private var boardList: some View {
        List {
            ForEach(board.boards) { section in
                StationPanelView(
                    name: section.name,
                    departures: section.departures,
                    errorMessage: section.error
                )
                .frame(maxWidth: 620)
                .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                // Swipe left to remove the station. `allowsFullSwipe: false`
                // keeps a fast flick from deleting a station by accident.
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        remove(id: section.id)
                    } label: {
                        Label("Ta bort", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: move)

            updatedFooter
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BoardPalette.background)
    }

    private var loadingState: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(BoardPalette.orange)
            Text("Hämtar avgångar …")
                .font(BoardFont.row)
                .foregroundStyle(BoardPalette.orange.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BoardPalette.background)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(BoardPalette.orange.opacity(0.7))

            Text("No stations yet")
                .font(BoardFont.station)

            Text("Tap + to add one.")
                .font(BoardFont.row)
                .foregroundStyle(BoardPalette.orange.opacity(0.7))
        }
        .foregroundStyle(BoardPalette.orange)
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BoardPalette.background)
    }

    /// "Last updated 01:37", with a small orange "!" when the most recent
    /// refresh failed. The list above keeps showing the last known departures.
    private var updatedFooter: some View {
        HStack(spacing: 6) {
            if board.hasError {
                Text("!")
                    .font(BoardFont.meta)
                    .foregroundStyle(BoardPalette.orange)
                    .accessibilityLabel("Uppdateringen misslyckades")
            }

            Text(board.lastUpdated.map { "Last updated \($0.formatted(.dateTime.hour().minute()))" }
                ?? "Updating …")
                .font(BoardFont.meta)
                .foregroundStyle(BoardPalette.orange.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    /// Polling restarts when the app becomes active or the station list
    /// changes, and stops while the app is in the background.
    private var pollingKey: String {
        "\(scenePhase == .active)|\(stationIDs.joined(separator: ","))"
    }

    private func add(_ station: Station) {
        let ids = StationSelectionStore.adding(station.id, to: stationIDs)
        selectionJSON = StationSelectionStore.encode(ids)
    }

    private func remove(id: String) {
        let ids = StationSelectionStore.removing(id, from: stationIDs)
        selectionJSON = StationSelectionStore.encode(ids)
    }

    /// Drag-to-reorder: writes the new order to `@AppStorage` and reorders the
    /// panels on screen right away, so the board does not wait for the next
    /// poll to catch up.
    private func move(from source: IndexSet, to destination: Int) {
        var ids = stationIDs
        ids.move(fromOffsets: source, toOffset: destination)
        guard ids != stationIDs else { return }

        selectionJSON = StationSelectionStore.encode(ids)
        board.retain(ids: ids)
    }
}

// MARK: - Board model

/// Fetches and holds the departures for every selected station.
///
/// Polls every 45 seconds while the app is foregrounded. A failed request
/// keeps the last known departures on screen and only raises a flag, so the
/// board never blanks out because of one bad response.
@Observable
@MainActor
final class DepartureBoardModel {
    struct Section: Identifiable {
        let id: String
        let name: String
        var departures: [Departure]
        var error: String?
    }

    private(set) var boards: [Section] = []
    private(set) var lastUpdated: Date?
    private(set) var hasError = false

    private let service = DepartureService()
    private let refreshInterval: Duration = .seconds(45)
    /// The panel shows the next departure plus up to six more.
    private let rowsPerStation = 7

    /// Refreshes immediately, then every 45 seconds until the task is
    /// cancelled (which is how leaving the foreground stops the polling).
    func poll(stationIDs: [String]) async {
        while !Task.isCancelled {
            await refresh(stationIDs: stationIDs)

            do {
                try await Task.sleep(for: refreshInterval)
            } catch {
                return
            }
        }
    }

    func refresh(stationIDs: [String]) async {
        guard !stationIDs.isEmpty else {
            boards = []
            return
        }

        var updated: [Section] = []
        var anyFailure = false
        var anySuccess = false

        for id in stationIDs {
            do {
                let departures = try await service.departures(
                    siteID: id,
                    limit: rowsPerStation
                )
                anySuccess = true
                let name = await stationName(
                    for: id,
                    fallback: departures.first?.stopArea?.name
                )
                updated.append(
                    Section(id: id, name: name, departures: departures, error: nil)
                )
            } catch {
                anyFailure = true
                let name = await stationName(
                    for: id,
                    fallback: boards.first { $0.id == id }?.name
                )

                // Keep the last known departures rather than blanking the row.
                let previous = boards.first { $0.id == id }?.departures ?? []
                updated.append(
                    Section(
                        id: id,
                        name: name,
                        departures: previous,
                        error: error.localizedDescription
                    )
                )
            }
        }

        boards = updated
        hasError = anyFailure

        // A partial failure still counts as an update: the stations that
        // answered are showing fresh data.
        if anySuccess {
            lastUpdated = .now
        }
    }

    /// Drops sections whose station the user removed.
    func retain(ids: [String]) {
        boards = ids.compactMap { id in boards.first { $0.id == id } }
    }

    private func stationName(for id: String, fallback: String?) async -> String {
        if let fallback, !fallback.isEmpty { return fallback }

        let all = await StationCatalog.shared.allStations()
        return all.first { $0.id == id }?.name ?? "Station \(id)"
    }
}

#Preview {
    ContentView()
}
