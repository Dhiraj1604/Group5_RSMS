//
//  ContentView.swift
//  Group5_RSMS
//
//  Created by Dhiraj on 10/04/26.
//
//  Root navigation: Login → Role Selection → Dashboard
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if !appState.isLoggedIn {
                LoginView()
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            } else if appState.selectedRole == nil {
                RoleSelectionView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                dashboardForRole(appState.selectedRole!)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: appState.selectedRole)
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
