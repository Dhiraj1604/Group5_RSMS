//
//  BMStaffTab.swift
//  Group5_RSMS
//

import SwiftUI

struct BMStaffTab: View {
    let boutiqueId: UUID
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    Picker("Staff View", selection: $selectedTab) {
                        Text("Directory").tag(0)
                        Text("Leaderboard").tag(1)
                        Text("Schedule").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if selectedTab == 0 {
                        StaffListView(boutiqueId: boutiqueId)
                    } else if selectedTab == 1 {
                        SalesLeaderboardView(boutiqueId: boutiqueId)
                    } else {
                        ShiftScheduleView(boutiqueId: boutiqueId)
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Staff Directory" : selectedTab == 1 ? "Leaderboard" : "Shift Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            StaffListView(boutiqueId: boutiqueId)
                .navigationTitle("Staff")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { BMStaffTab(boutiqueId: UUID()) }
