import Foundation

/// Top-level response from `GET /v1/sites/{siteId}/departures`.
struct DeparturesResponse: Decodable, Sendable {
    let departures: [Departure]

    private enum CodingKeys: String, CodingKey {
        case departures
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // An empty response body or a missing key should mean "no departures",
        // not a decoding failure that forces the widget into its error state.
        departures = try container.decodeIfPresent([Departure].self, forKey: .departures) ?? []
    }

    init(departures: [Departure]) {
        self.departures = departures
    }
}

/// A single departure from the SL API.
///
/// Only the fields the widget renders are decoded. `expected` and `scheduled`
/// are kept as strings on purpose: the live API returns local Stockholm time
/// without a timezone offset (for example `2026-11-16T02:37:54`), which makes
/// `JSONDecoder.DateDecodingStrategy.iso8601` throw. The widget displays the
/// server-provided `display` string instead, so it never needs a parsed `Date`.
struct Departure: Decodable, Sendable {
    let destination: String?
    let display: String?
    let expected: String?
    let scheduled: String?
    let transportMode: String?
    let line: Line?
    let stopArea: StopArea?

    private enum CodingKeys: String, CodingKey {
        case destination
        case display
        case expected
        case scheduled
        case line
        case transportMode = "transport_mode"
        case stopArea = "stop_area"
    }

    struct Line: Decodable, Sendable {
        let designation: String?
        let transportMode: String?

        private enum CodingKeys: String, CodingKey {
            case designation
            case transportMode = "transport_mode"
        }
    }

    struct StopArea: Decodable, Sendable {
        let name: String?
    }

    enum Mode: String, Sendable {
        case metro = "METRO"
        case bus = "BUS"
        case train = "TRAIN"
        case tram = "TRAM"
        case ship = "SHIP"
    }

    /// The line number, or a dash when the API omits it.
    var lineDesignation: String {
        let designation = line?.designation?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return designation.isEmpty ? "–" : designation
    }

    /// The terminus, or a Swedish fallback when the API omits it.
    var destinationName: String {
        let destination = destination?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return destination.isEmpty ? "Okänd destination" : destination
    }

    /// The human-readable countdown: "Nu", "3 min", or a clock time.
    var countdown: String {
        let display = display?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return display.isEmpty ? "–" : display
    }

    /// The API puts `transport_mode` inside `line`; accept a top-level value too.
    var mode: Mode? {
        let rawValue = (transportMode ?? line?.transportMode ?? "").uppercased()
        return Mode(rawValue: rawValue)
    }

    var modeName: String? {
        guard let mode else { return nil }

        switch mode {
        case .metro: return "Tunnelbana"
        case .bus: return "Buss"
        case .train: return "Tåg"
        case .tram: return "Spårvagn"
        case .ship: return "Båt"
        }
    }

    var accessibilityLabel: String {
        [modeName.map { "\($0) " } ?? "", "linje \(lineDesignation)"]
            .joined()
            + " mot \(destinationName), \(countdown)"
    }
}

extension Departure {
    /// Mock data for previews and placeholders. Never used for a real fetch.
    static func mock(
        line: String,
        destination: String,
        display: String,
        mode: Mode = .metro
    ) -> Departure {
        Departure(
            destination: destination,
            display: display,
            expected: nil,
            scheduled: nil,
            transportMode: mode.rawValue,
            line: Line(designation: line, transportMode: mode.rawValue),
            stopArea: nil
        )
    }
}
