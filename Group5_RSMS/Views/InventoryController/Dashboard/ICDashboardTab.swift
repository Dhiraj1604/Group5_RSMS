//
//  ICDashboardTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Dashboard overview tab.
//

import SwiftUI

struct ICDashboardTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Inventory Dashboard",
                icon: "chart.bar.fill",
                description: "Overview of stock levels, pending shipments, and low-stock alerts across all warehouses."
            )
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            appState.goBackToRoleSelection()
                        } label: {
                            Label("Switch Role", systemImage: "arrow.left.arrow.right")
                        }
                        Button(role: .destructive) {
                            appState.logout()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
    }
}

#Preview {
    ICDashboardTab()
        .environment(AppState())
}
