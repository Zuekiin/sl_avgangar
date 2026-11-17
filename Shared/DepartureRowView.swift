import SwiftUI

/// One departure line, shared by the app's station panels and by the Lock
/// Screen widget.
///
/// Layout is always `[line designation] [destination] [time]`: the line takes
/// a fixed minimum so the destinations start at the same place, the
/// destination fills the middle and truncates at its tail, and the time is
/// pinned to the trailing edge so every countdown in a column lines up.
struct DepartureRowView: View {
    let departure: Departure

    /// The row's type size. `BoardFont.prominent` for a panel's next
    /// departure, `BoardFont.row` for the rest, `BoardFont.widgetRow` on the
    /// Lock Screen.
    var font: Font = BoardFont.row

    /// Minimum width of the line column. Long designations such as
    /// "Pendeltåg 40" widen their own column instead of being truncated.
    var lineColumn: CGFloat = 30

    /// Minimum width of the time column, right-aligned.
    var timeColumn: CGFloat = 58

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(departure.lineDesignation)
                .lineLimit(1)
                .frame(minWidth: lineColumn, alignment: .leading)

            Text(departure.destinationName)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(departure.countdown)
                .lineLimit(1)
                .frame(minWidth: timeColumn, alignment: .trailing)
                .fixedSize()
        }
        .font(font)
        .foregroundStyle(BoardPalette.orange)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(departure.accessibilityLabel)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        DepartureRowView(
            departure: .mock(line: "30", destination: "Solna station", display: "3 min"),
            font: BoardFont.prominent
        )
        DepartureRowView(
            departure: .mock(line: "40", destination: "Uppsala centralstation", display: "12 min")
        )
        DepartureRowView(
            departure: .mock(line: "Pendeltåg 43", destination: "Västerhaninge", display: "Nu")
        )
    }
    .padding()
    .background(BoardPalette.panel)
    .preferredColorScheme(.dark)
}
