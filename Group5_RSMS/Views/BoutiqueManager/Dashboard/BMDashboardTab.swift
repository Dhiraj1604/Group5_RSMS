//
//  BMDashboardTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Dashboard overview tab.
//

import SwiftUI

struct BMDashboardTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Store Dashboard",
                icon: "chart.bar.fill",
                description: "View daily sales, footfall, and performance metrics for your boutique."
            )
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
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
    BMDashboardTab()
        .environment(AppState())
}
