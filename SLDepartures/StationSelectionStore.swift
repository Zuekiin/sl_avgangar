import Foundation

/// The stations the board shows, persisted as a JSON array of SL site IDs.
///
/// The views read and write the raw string through `@AppStorage`, so the
/// selection survives launches without any extra persistence layer; these
/// helpers own the encoding rules in one place.
struct StationSelectionStore {
    /// The `@AppStorage` key holding the JSON array of site IDs.
    static let key = "selectedStations"

    /// Decodes the stored JSON, ignoring anything unreadable.
    static func load(from json: String) -> [String] {
        guard let data = json.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        // Keep the user's order, but drop duplicates.
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    /// Encodes a selection for storage.
    static func encode(_ ids: [String]) -> String {
        guard let data = try? JSONEncoder().encode(ids),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    static func adding(_ id: String, to ids: [String]) -> [String] {
        guard !ids.contains(id) else { return ids }
        return ids + [id]
    }

    static func removing(_ id: String, from ids: [String]) -> [String] {
        ids.filter { $0 != id }
    }
}
