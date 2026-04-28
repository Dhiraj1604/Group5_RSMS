//
//  BMStaffTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Staff tab. Native iPadOS styling.
//  Enhanced with Liquid Glass UI and grand segmented control.
//

import SwiftUI

struct BMStaffTab: View {
    let boutiqueId: UUID

    @State private var selectedTab = 0
    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var addEmpVM = AddEmployeeViewModel()
    @StateObject private var shiftVM = ShiftViewModel()

    @State private var showAddEmployee = false
    @State private var showRangePicker = false
    @State private var showingAddShift = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Native Segmented Control with Enhanced Sizing
                Picker("Tab", selection: $selectedTab) {
                    Text("Directory").tag(0)
                    Text("Schedule").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 60)
                .padding(.vertical, 24)
                .background(Color(UIColor.systemGroupedBackground))

                Divider().opacity(0.5)

                switch selectedTab {
                case 0:
                    StaffListView(boutiqueId: boutiqueId, staffVM: staffVM, showAddEmployee: $showAddEmployee)
                default:
                    ShiftScheduleView(shiftVM: shiftVM, staffVM: staffVM, showingAddShift: $showingAddShift, boutiqueId: boutiqueId)
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if selectedTab == 0 { showAddEmployee = true }
                        else { showingAddShift = true }
                    } label: {
                        LiquidBarButton(icon: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEmployee) {
                AddEmployeeView(staffVM: staffVM, vm: addEmpVM, boutiqueId: boutiqueId)
            }
            .task {
                await staffVM.fetchEmployees(boutiqueId: boutiqueId)
                await staffVM.fetchSalesPerEmployee(boutiqueId: boutiqueId)
            }
        }
    }

    private var navigationTitle: String {
        switch selectedTab {
        case 0: return "Staff Intelligence"
        default: return "Roster Management"
        }
    }
}
