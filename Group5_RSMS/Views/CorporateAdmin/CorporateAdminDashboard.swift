//
//  CorporateAdminDashboard.swift
//  Group5_RSMS
//
//  Main dashboard for Corporate Admin with 5 tabs.
//

import SwiftUI

struct CorporateAdminDashboard: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardTab()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            StoresTab()
                .tabItem {
                    Label("Stores", systemImage: "building.2.fill")
                }
                .tag(1)

            ProductsTab()
                .tabItem {
                    Label("Products", systemImage: "tag.fill")
                }
                .tag(2)

            OffersTab()
                .tabItem {
                    Label("Offers", systemImage: "gift.fill")
                }
                .tag(3)

            ReportsTab()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(4)
        }
        .tint(RSMSTheme.Colors.accentGold)
    }
}

#Preview {
    CorporateAdminDashboard()
        .environment(AppState())
}
