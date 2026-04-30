//
//  BMStaffTab.swift
//  Group5_RSMS
//
//  Premium Staff Module for Boutique Managers.
//  Uses native .searchable for iOS-consistent search UX.
//

import SwiftUI

struct BMStaffTab: View {
    let boutiqueId: UUID

    @State private var selectedTab = 0
    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var addEmpVM = AddEmployeeViewModel()
    @StateObject private var shiftVM = ShiftViewModel()

    @State private var searchText = ""
    @State private var showAddEmployee = false
    @State private var showingAddShift = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("Staff Section", selection: $selectedTab) {
                        Text("Directory").tag(0)
                        Text("Schedule").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

//                     // CONTENT
//                     switch selectedTab {
//                     case 0:
//                         StaffListView(boutiqueId: boutiqueId, staffVM: staffVM, showAddEmployee: $showAddEmployee)
//                     case 1:
//                         SalesLeaderboardView(staffVM: staffVM, showRangePicker: $showRangePicker, boutiqueId: boutiqueId)
//                     default:
//                         ShiftScheduleView(shiftVM: shiftVM, staffVM: staffVM, showingAddShift: $showingAddShift, boutiqueId: boutiqueId)
                    // ── CONTENT ──
                    if selectedTab == 0 {
                        StaffListView(
                            boutiqueId: boutiqueId,
                            staffVM: staffVM,
                            searchText: $searchText,
                            showAddEmployee: $showAddEmployee
                        )
                    } else {
                        ShiftScheduleView(
                            shiftVM: shiftVM,
                            staffVM: staffVM,
                            showingAddShift: $showingAddShift,
                            boutiqueId: boutiqueId
                        )
                    }
                }
            }
            .navigationTitle("Staff Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarContent
                }
            }
            // ── Native iOS search bar — Directory tab ──
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search staff members..."
            )
            .sheet(isPresented: $showAddEmployee) {
                AddEmployeeView(boutiqueId: boutiqueId, staffVM: staffVM, shiftVM: shiftVM, vm: addEmpVM)
            }
            .task {
                await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            }
        }
    }

    @ViewBuilder
    private var trailingToolbarContent: some View {
        if selectedTab == 0 {
            Button { showAddEmployee = true } label: {
                Image(systemName: "plus")
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
        } else {
            Button { showingAddShift = true } label: {
                Image(systemName: "plus")
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
        }
    }
}
