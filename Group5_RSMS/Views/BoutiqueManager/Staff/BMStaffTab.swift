//
//  BMStaffTab.swift
//  Group5_RSMS
//
//  Premium Staff Module for Boutique Managers.
//  Separates Directory and Schedule into a clean, single-header layout.
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
                    // ── PREMIUM TAB PICKER ──
                    Picker("Staff Section", selection: $selectedTab) {
                        Text("Directory").tag(0)
                        Text("Schedule").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.Colors.backgroundPrimary)

                    // ── CONSISTENT SEARCH BAR (Luxury Style) ──
                    if selectedTab == 0 {
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                TextField("Search staff members...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                                if !searchText.isEmpty {
                                    Button { searchText = "" } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(RSMSTheme.Colors.backgroundElevated)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.Colors.backgroundPrimary)
                    }

                    // ── CONTENT ──
                    Group {
                        if selectedTab == 0 {
                            StaffListView(boutiqueId: boutiqueId, staffVM: staffVM, searchText: $searchText, showAddEmployee: $showAddEmployee)
                        } else {
                            ShiftScheduleView(shiftVM: shiftVM, staffVM: staffVM, showingAddShift: $showingAddShift, boutiqueId: boutiqueId)
                        }
                    }
                }
            }
            .navigationTitle("Staff Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    trailingToolbarContent
                }
            }
            .sheet(isPresented: $showAddEmployee) {
                AddEmployeeView(boutiqueId: boutiqueId, staffVM: staffVM, vm: addEmpVM)
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
