import SwiftUI
import Supabase

@main
struct Group5_RSMSApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
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

