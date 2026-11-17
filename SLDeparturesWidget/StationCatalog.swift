import Foundation
import os

/// A station as shown in the widget configuration picker.
///
/// `id` is the short numeric site ID used by the departures endpoint
/// (for example `3685`), never the long Stop Lookup ID.
struct Station: Codable, Hashable, Sendable {
    let id: String
    let name: String
    let note: String?
}

/// Loads and caches the SL station list.
///
/// The full `/v1/sites?expand=true` response ships with the widget extension
/// (`Stations.json`), so the configuration picker can search by name
/// immediately, even on a first launch without network access. A successful
/// live fetch refreshes the list and replaces the bundled data.
///
/// The list is large (several thousand entries), so it is cached in memory and
/// on disk. The picker can issue several queries while the user types; none of
/// them performs a network request.
actor StationCatalog {
    static let shared = StationCatalog()

    private struct SiteDTO: Decodable {
        let id: Int
        let name: String
        let note: String?
    }

    private struct DiskCache: Codable {
        let fetchedAt: Date
        let stations: [Station]
    }

    private static let logger = Logger(
        subsystem: "com.example.SLDepartures",
        category: "StationCatalog"
    )

    private static let cacheFileName = "sl-stations-v1.json"
    private static let cacheMaxAge: TimeInterval = 24 * 60 * 60
    private static let retryInterval: TimeInterval = 5 * 60

    /// Shown first in the picker. T-Centralen is also the default selection.
    private static let suggestedIDs = [
        "9001", // T-Centralen
        "9192", // Slussen
        "9117", // Odenplan
        "9115", // Fridhemsplan
        "9189", // Gullmarsplan
        "9294", // Liljeholmen
        "9112", // Alvik
        "9529", // Älvsjö
        "9200", // Mörby centrum
        "9280", // Norsborg
        "1080"  // Stockholm City
    ]

    private var stations: [Station] = []
    private var lastRefresh: Date?
    private var lastRefreshAttempt: Date?
    private var refreshTask: Task<Void, Never>?

    /// All stations, alphabetically sorted. Always returns the bundled list
    /// when neither a disk cache nor a network response is available.
    func allStations() async -> [Station] {
        loadLocalStationsIfNeeded()
        startRefreshIfNeeded()
        return stations
    }

    /// Local, diacritic-insensitive search across the cached station list.
    func stations(matching query: String) async -> [Station] {
        let all = await allStations()
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !needle.isEmpty else {
            return Array(all.prefix(30))
        }

        let matches = all.filter { station in
            station.name.localizedStandardContains(needle)
                || station.note?.localizedStandardContains(needle) == true
                || station.id == needle
                || Self.normalizedName(station.name).contains(Self.normalizedName(needle))
        }

        return Array(matches.prefix(40))
    }

    /// Folds case, diacritics, spaces and punctuation so that for example
    /// "T Centralen" and "t-centralen" find the same stop.
    private nonisolated static func normalizedName(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }

    /// A short list of well-known stations for the picker's initial state.
    func suggestedStations() async -> [Station] {
        let all = await allStations()

        let byID = Dictionary(
            all.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let suggested = Self.suggestedIDs.compactMap { byID[$0] }

        return suggested.isEmpty ? Array(all.prefix(12)) : suggested
    }

    // MARK: - Local data

    /// Seeds the in-memory list from the disk cache, or from the bundled list
    /// when the cache is missing. This is synchronous and instant, so picker
    /// queries never wait for the network.
    private func loadLocalStationsIfNeeded() {
        guard stations.isEmpty else { return }

        if let diskCache = Self.readDiskCache(), !diskCache.stations.isEmpty {
            stations = diskCache.stations
            lastRefresh = diskCache.fetchedAt
        } else {
            stations = Self.loadBundledStations()
        }
    }

    /// Refreshes in the background when the data is old. The picker keeps
    /// using the bundled or cached list while the request is in flight.
    private func startRefreshIfNeeded() {
        guard refreshTask == nil else { return }

        if let lastRefresh,
           Date.now.timeIntervalSince(lastRefresh) < Self.cacheMaxAge {
            return
        }

        if let lastRefreshAttempt,
           Date.now.timeIntervalSince(lastRefreshAttempt) < Self.retryInterval {
            return
        }

        lastRefreshAttempt = .now
        refreshTask = Task.detached(priority: .utility) { [weak self] in
            let fetched = await Self.fetchStations()
            await self?.applyRefresh(fetched)
        }
    }

    private func applyRefresh(_ fetched: [Station]) {
        refreshTask = nil

        guard !fetched.isEmpty else {
            // Keep the bundled or cached list; retry later.
            return
        }

        stations = fetched
        lastRefresh = .now
        Self.writeDiskCache(DiskCache(fetchedAt: .now, stations: fetched))
    }

    // MARK: - Disk cache

    private nonisolated static var cacheURL: URL? {
        FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(cacheFileName, isDirectory: false)
    }

    private nonisolated static func readDiskCache() -> DiskCache? {
        guard let url = cacheURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(DiskCache.self, from: data)
        } catch {
            logger.debug("Ignoring unreadable station cache: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private nonisolated static func writeDiskCache(_ cache: DiskCache) {
        guard let url = cacheURL else { return }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(cache)
            try data.write(to: url, options: .atomic)
        } catch {
            logger.error("Could not write station cache: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Bundled data

    private nonisolated static func loadBundledStations() -> [Station] {
        guard let url = Bundle.main.url(
            forResource: "Stations",
            withExtension: "json"
        ) else {
            logger.error("Bundled Stations.json is missing from the extension.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Station].self, from: data)
        } catch {
            logger.error(
                "Could not decode bundled stations: \(error.localizedDescription, privacy: .public)"
            )
            return []
        }
    }

    // MARK: - Network

    private nonisolated static func fetchStations() async -> [Station] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "transport.integration.sl.se"
        components.path = "/v1/sites"
        components.queryItems = [URLQueryItem(name: "expand", value: "true")]

        guard let url = components.url else {
            logger.error("Could not build the station list URL.")
            return []
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                logger.error("Station list request failed with HTTP \(status).")
                return []
            }

            let sites = try JSONDecoder().decode([SiteDTO].self, from: data)

            return sites
                .map { Station(id: String($0.id), name: $0.name, note: $0.note) }
                .sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
        } catch {
            logger.error("Could not fetch the station list: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }
}
