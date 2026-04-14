//
//  BMStaffTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Staff management tab placeholder.
//

import SwiftUI

struct BMStaffTab: View {
    var body: some View {
        NavigationStack {
            ComingSoonView(
                title: "Staff",
                icon: "person.3.fill",
                description: "Manage staff schedules, assign roles, and monitor employee activity in your boutique."
            )
            .navigationTitle("Staff")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { BMStaffTab() }
