//
//  BMStaffTab.swift
//  Group5_RSMS
//
//  Premium Staff Module for Boutique Managers.
//  Separates Directory, Leaderboard, and Schedule into a clean, single-header layout.
//

import SwiftUI

struct BMStaffTab: View {
    let boutiqueId: UUID

    @State private var selectedTab = 0
    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var addEmpVM = AddEmployeeViewModel()
    @StateObject private var shiftVM = ShiftViewModel() // Added for Schedule tab support

    @State private var showAddEmployee = false
    @State private var showRangePicker = false
    @State private var showingAddShift = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // PREMIUM TAB PICKER
                    Picker("Staff Section", selection: $selectedTab) {
                        Text("Directory").tag(0)
                        Text("Leaderboard").tag(1)
                        Text("Schedule").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.Colors.backgroundPrimary)

                    // CONTENT
                    switch selectedTab {
                    case 0:
                        StaffListView(boutiqueId: boutiqueId, staffVM: staffVM, showAddEmployee: $showAddEmployee)
                    case 1:
                        SalesLeaderboardView(staffVM: staffVM, showRangePicker: $showRangePicker, boutiqueId: boutiqueId)
                    default:
                        ShiftScheduleView(shiftVM: shiftVM, staffVM: staffVM, showingAddShift: $showingAddShift, boutiqueId: boutiqueId)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarContent
                }
            }
            // Centralised Sheets
            .sheet(isPresented: $showAddEmployee) {
                AddEmployeeView(boutiqueId: boutiqueId, staffVM: staffVM, vm: addEmpVM)
            }
            .task {
                await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            }
        }
    }

    private var navigationTitle: String {
        switch selectedTab {
        case 0: return "Staff Directory"
        case 1: return "Sales Leaderboard"
        default: return "Shift Schedule"
        }
    }

    @ViewBuilder
    private var trailingToolbarContent: some View {
        switch selectedTab {
        case 0:
            Button { showAddEmployee = true } label: {
                Image(systemName: "plus")
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
        case 1:
            // This button is now handled by the child via a shared binding if needed, 
            // or we just trigger the child's action.
            Button { showRangePicker = true } label: {
                Image(systemName: "calendar")
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
        case 2:
            Button { showingAddShift = true } label: {
                Image(systemName: "plus")
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
        default:
            EmptyView()
        }
    }
}
