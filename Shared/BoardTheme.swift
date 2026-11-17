import SwiftUI

/// The look shared by the app and the widget: amber Courier text on a
/// near-black board, drawn inside square-cornered rectangles.
///
/// Nothing in this file rounds a corner, and nothing here animates or
/// scrolls — both surfaces show the same static departure board.
enum BoardPalette {
    /// A fixed amber instead of the system `.orange`, so the app and the
    /// widget render the same tone everywhere.
    static let orange = Color(red: 1.0, green: 0.55, blue: 0.0) // #FF8C00
    static let background = Color.black
    static let panel = Color(white: 0.06)
    static let hairline = Color(red: 1.0, green: 0.55, blue: 0.0).opacity(0.22)
}

/// Courier at the text styles the board uses.
///
/// The sizes are grouped by role, and the widget has its own smaller set
/// because the Lock Screen rows have far less room than the app's panels.
enum BoardFont {
    /// The board's title. The app draws it itself so it never scrolls away.
    static let title = Font.custom("Courier-Bold", size: 28, relativeTo: .largeTitle)
    /// Station name at the top of a panel or the widget.
    static let station = Font.custom("Courier-Bold", size: 17, relativeTo: .headline)
    /// The next departure, which is the most important line on a panel.
    static let prominent = Font.custom("Courier-Bold", size: 18, relativeTo: .body)
    /// The remaining departures.
    static let row = Font.custom("Courier", size: 15, relativeTo: .callout)
    /// Timestamps, captions and other small print.
    static let meta = Font.custom("Courier", size: 12, relativeTo: .caption)

    // Lock Screen (`.accessoryRectangular`).
    static let widgetStation = Font.custom("Courier-Bold", size: 12, relativeTo: .caption)
    static let widgetRow = Font.custom("Courier", size: 10.5, relativeTo: .caption2)
    static let widgetMeta = Font.custom("Courier", size: 9.5, relativeTo: .caption2)

    // Home Screen `.systemSmall`.
    static let widgetStationSmall = Font.custom("Courier-Bold", size: 15, relativeTo: .subheadline)
    static let widgetRowSmall = Font.custom("Courier", size: 12, relativeTo: .caption)

    // Home Screen `.systemMedium`.
    static let widgetStationMedium = Font.custom("Courier-Bold", size: 16, relativeTo: .headline)
    static let widgetRowMedium = Font.custom("Courier", size: 13, relativeTo: .callout)

    // Lock Screen `.accessoryCircular`.
    static let circularLine = Font.custom("Courier-Bold", size: 15, relativeTo: .headline)
    static let circularTime = Font.custom("Courier", size: 10, relativeTo: .caption2)
}
