//
//  ContentView.swift
//  Group5_RSMS
//
//  Created by Dhiraj on 10/04/26.
//
//  Root navigation: Login → Role Selection → Dashboard
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

@available(iOS 17.0, *)
struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var isCheckingSession = true

    var body: some View {
        Group {
            if isCheckingSession {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(RSMSTheme.Colors.accentGold)
                            .scaleEffect(1.5)
                    }
            } else if !appState.isLoggedIn {
                LoginView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            } else if appState.requiresPasswordChange {
                ForcePasswordChangeView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if let role = appState.selectedRole {
                dashboardForRole(role)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()
                    .overlay {
                        Text("Authorizing Role...")
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: appState.selectedRole)
        .animation(.easeInOut(duration: 0.3), value: isCheckingSession)
        .task {
            await checkSession()
        }
    }

    private func checkSession() async {
        #if canImport(Supabase)
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            try await appState.login(email: session.user.email ?? "")
            await MainActor.run {
                isCheckingSession = false
            }
        } catch {
            await MainActor.run {
                isCheckingSession = false
            }
        }
        #else
        isCheckingSession = false
        #endif
    }

    @ViewBuilder
    private func dashboardForRole(_ role: UserRole) -> some View {
        switch role {
        case .corporateAdmin:
            CorporateAdminDashboard()

        case .boutiqueManager:
            BoutiqueManagerDashboard()

        case .inventoryController:
            InventoryControllerDashboard()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
