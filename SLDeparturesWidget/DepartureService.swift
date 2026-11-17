import Foundation
import os

enum DepartureServiceError: LocalizedError {
    case invalidSiteID(String)
    case invalidURL
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidSiteID(let value):
            return "Ogiltigt stations-ID: \(value)"
        case .invalidURL:
            return "Kunde inte bygga URL:en till SL:s API."
        case .httpStatus(let statusCode):
            return "SL:s API svarade med HTTP \(statusCode)."
        }
    }
}

/// Fetches departures from the official SL open API.
///
/// No API key is required. The station comes from the widget configuration,
/// never from a constant.
struct DepartureService {
    private static let logger = Logger(
        subsystem: "com.example.SLDepartures",
        category: "DepartureService"
    )

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func departures(siteID: String, limit: Int = 3) async throws -> [Departure] {
        guard let numericID = Int(siteID), numericID > 0 else {
            throw DepartureServiceError.invalidSiteID(siteID)
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "transport.integration.sl.se"
        components.path = "/v1/sites/\(numericID)/departures"

        guard let url = components.url else {
            throw DepartureServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        // A widget refresh should show what is happening now, not a cached
        // response from the previous timeline reload.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DepartureServiceError.httpStatus(-1)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            Self.logger.error(
                "Departures request for site \(numericID, privacy: .public) failed with HTTP \(httpResponse.statusCode, privacy: .public)."
            )
            throw DepartureServiceError.httpStatus(httpResponse.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(DeparturesResponse.self, from: data)
            let count = max(0, limit)
            return Array(decoded.departures.prefix(count))
        } catch {
            Self.logger.error(
                "Could not decode departures for site \(numericID, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }
}
