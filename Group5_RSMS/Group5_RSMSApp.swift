import SwiftUI
import Supabase

@main
struct Group5_RSMSApp: App {
    @State private var appState = AppState()
    @AppStorage("rsms.appearanceMode") private var appearanceModeRaw = RSMSAppearanceMode.dark.rawValue
    @AppStorage("rsms.language") private var appLanguage = "system"

    private var selectedAppearanceMode: RSMSAppearanceMode {
        RSMSAppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(selectedAppearanceMode.colorScheme)
                .environment(\.locale, appLanguage == "system" ? Locale.current : .init(identifier: appLanguage))
                .onOpenURL { url in
                    Task {
                        do {
                            // This takes the link they clicked and logs them natively into the app!
                            try await SupabaseManager.shared.client.auth.session(from: url)
                        } catch {
                            print("Deep link auth failed: \(error)")
                        }
                    }
                }
        }
    }
}
