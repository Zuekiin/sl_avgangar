import SwiftUI

/// Read-only instructions for adding the Lock Screen widget.
///
/// The widget is a separate, equal feature: it shows one station on the Lock
/// Screen (and the small Home Screen size), while the app shows several
/// stations. It uses the same amber-on-black rectangles as this screen.
struct WidgetSetupView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("SL Avgångar finns även som widget för låsskärmen och hemskärmen. Så här lägger du till den.")
                    .font(BoardFont.row)
                    .foregroundStyle(BoardPalette.orange.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 18) {
                    StepRow(
                        number: 1,
                        title: "Redigera låsskärmen",
                        detail: "Håll fingret på låsskärmen och tryck på Anpassa → Låsskärm."
                    )
                    StepRow(
                        number: 2,
                        title: "Lägg till SL Avgångar",
                        detail: "Tryck på widgetområdet och välj SL Avgångar i listan."
                    )
                    StepRow(
                        number: 3,
                        title: "Välj station",
                        detail: "Tryck på widgeten och sök på stationens namn, till exempel Karlsbodavägen. Alla SL-stationer finns i listan."
                    )
                    StepRow(
                        number: 4,
                        title: "Hemskärmen",
                        detail: "Håll fingret på hemskärmen, tryck på + och välj SL Avgångar i liten storlek."
                    )
                }

                InfoCard(
                    icon: "keyboard",
                    title: "Om sökningen inte hittar stationen",
                    text: "Sökningen matchar namn utan hänsyn till versaler, mellanslag och punkter — \"T Centralen\" och \"tcentralen\" hittar samma station. Hittar du ändå inte stationen kan du ange dess numeriska SL-ID direkt i widgetens inställning; ID:t är samma kortnummer som i SL:s öppna API (till exempel 9001 för T-Centralen)."
                )

                InfoCard(
                    icon: "clock.arrow.circlepath",
                    title: "Uppdatering styrs av iOS",
                    text: "Widgeten ber iOS om nya avgångar ungefär varje minut, men det är iOS som bestämmer hur ofta den faktiskt uppdateras. En widget som visas ofta får några uppdateringar i timmen; i strömsparläge kan det dröja betydligt längre. Avgångarna är därför inte garanterat i realtid."
                )
            }
            .padding(20)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(BoardPalette.background)
        .navigationTitle("Widget")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(BoardFont.meta)
                .foregroundStyle(BoardPalette.background)
                .frame(width: 24, height: 24)
                .background(BoardPalette.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BoardFont.station)
                    .foregroundStyle(BoardPalette.orange)

                Text(detail)
                    .font(BoardFont.meta)
                    .foregroundStyle(BoardPalette.orange.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct InfoCard: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(BoardPalette.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(BoardFont.station)
                    .foregroundStyle(BoardPalette.orange)

                Text(text)
                    .font(BoardFont.meta)
                    .foregroundStyle(BoardPalette.orange.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BoardPalette.panel)
        .overlay {
            Rectangle().strokeBorder(BoardPalette.hairline, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        WidgetSetupView()
    }
    .preferredColorScheme(.dark)
}
