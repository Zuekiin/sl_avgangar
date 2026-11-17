import SwiftUI

@main
struct SLDeparturesApp: App {
    init() {
        Self.configureNavigationBar()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    /// The navigation bar is part of the board, so it gets the same black
    /// background and amber titles as the panels. `ContentView` sets
    /// `.preferredColorScheme(.dark)`, which keeps the system controls dark.
    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(BoardPalette.orange)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(BoardPalette.orange)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(BoardPalette.orange)
    }
}
