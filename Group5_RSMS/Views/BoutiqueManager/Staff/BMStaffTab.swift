//
//  BMStaffTab.swift
//  Group5_RSMS
//

import SwiftUI

struct BMStaffTab: View {
    let boutiqueId: UUID

    var body: some View {
        NavigationStack {
            StaffListView(boutiqueId: boutiqueId)
                .navigationTitle("Staff")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { BMStaffTab(boutiqueId: UUID()) }
