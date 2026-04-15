//
//  BoutiqueManagerDashboard.swift
//  Group5_RSMS
//
//  Main dashboard for Boutique Manager with 5 tabs.
//

import SwiftUI

struct BoutiqueManagerDashboard: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BMDashboardTab()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            BMInventoryTab()
                .tabItem {
                    Label("Inventory", systemImage: "shippingbox.fill")
                }
                .tag(1)

            BMSalesTab()
                .tabItem {
                    Label("Sales", systemImage: "cart.fill")
                }
                .tag(2)

            BMStaffTab()
                .tabItem {
                    Label("Staff", systemImage: "person.3.fill")
                }
                .tag(3)

            BMReportsTab()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(4)
        }
        .tint(RSMSTheme.Colors.accentGold)
    }
}

#Preview {
    BoutiqueManagerDashboard()
        .environment(AppState())
}
