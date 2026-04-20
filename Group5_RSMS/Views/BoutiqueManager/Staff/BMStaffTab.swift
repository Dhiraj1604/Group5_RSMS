//
//  BMStaffTab.swift
//  Group5_RSMS
//

import SwiftUI

struct BMStaffTab: View {
    let boutiqueId: UUID

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: RSMSTheme.Spacing.md) {
//                    Image(systemName: "person.3.fill")
//                        .font(.system(size: 48))
//                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
//                    Text("Coming Soon")
//                        .font(.title3)
//                        .fontWeight(.semibold)
//                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
            .navigationTitle("Staff")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { BMStaffTab(boutiqueId: UUID()) }
