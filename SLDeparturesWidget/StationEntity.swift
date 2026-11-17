import AppIntents
import Foundation

/// The station picker's value type.
///
/// `id` is the numeric SL site ID (for example `"3685"`), and `name` is the
/// station name shown in the picker. The picker is made for browsing and
/// searching by name; the ID is only an implementation detail used to call the
/// departures endpoint, so it is not shown in the list.
struct StationEntity: AppEntity, Hashable, Sendable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Station"
    static let defaultQuery = StationQuery()

    let id: String
    let name: String
    let note: String?

    init(id: String, name: String, note: String? = nil) {
        self.id = id
        self.name = name
        self.note = note
    }

    init(_ station: Station) {
        self.init(id: station.id, name: station.name, note: station.note)
    }

    var displayRepresentation: DisplayRepresentation {
        guard let note, !note.isEmpty else {
            return DisplayRepresentation(title: "\(name)")
        }

        // The note is the stop area or platform qualifier, which is far more
        // useful than the numeric ID when several stops share a name.
        return DisplayRepresentation(title: "\(name)", subtitle: "\(note)")
    }

    /// The default and fallback station.
    static let tCentralen = StationEntity(id: "9001", name: "T-Centralen")
}

struct StationQuery: EntityStringQuery {
    func entities(for identifiers: [StationEntity.ID]) async throws -> [StationEntity] {
        let all = await StationCatalog.shared.allStations()
        let byID = Dictionary(
            all.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return identifiers.map { identifier in
            if let station = byID[identifier] {
                return StationEntity(station)
            }
            // Never lose the user's configuration just because the list could
            // not be loaded. The provider can still fetch this numeric ID.
            return StationEntity(id: identifier, name: "Station \(identifier)")
        }
    }

    func entities(matching string: String) async throws -> [StationEntity] {
        let matches = await StationCatalog.shared.stations(matching: string)
        return matches.map { StationEntity($0) }
    }

    func suggestedEntities() async throws -> [StationEntity] {
        let suggested = await StationCatalog.shared.suggestedStations()
        return suggested.map { StationEntity($0) }
    }
}
