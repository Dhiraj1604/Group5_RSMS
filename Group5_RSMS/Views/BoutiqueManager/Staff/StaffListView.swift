//
//  StaffListView.swift
//  Group5_RSMS
//
//  Clean staff directory — just the list of employees with their contact + role info.
//

import SwiftUI

enum StaffFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"
}

struct StaffListView: View {
    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var addEmpVM = AddEmployeeViewModel()
    @State private var showAddEmployee = false
    @State private var selectedFilter: StaffFilter = .all

    let boutiqueId: UUID
    
    var filteredEmployees: [Employee] {
        switch selectedFilter {
        case .all:
            return staffVM.employees
        case .active:
            return staffVM.employees.filter { $0.isActive ?? true }
        case .inactive:
            return staffVM.employees.filter { !($0.isActive ?? true) }
        }
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if staffVM.isLoading {
                ProgressView().tint(RSMSTheme.Colors.accentGold)
            } else if staffVM.employees.isEmpty {
                emptyState
            } else {
                employeeList
                VStack(spacing: 0) {
                    Picker("Filter Staff", selection: $selectedFilter) {
                        ForEach(StaffFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    if filteredEmployees.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.6))
                            Text("No \(selectedFilter.rawValue.lowercased()) staff members")
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredEmployees) { employee in
                                    NavigationLink(destination:
                                        EmployeeSalesDetailView(
                                            employee: employee,
                                            boutiqueId: boutiqueId,
                                            staffVM: staffVM
                                        )
                                    ) {
                                        EmployeeCard(
                                            employee: employee,
                                            totalSales: staffVM.totalSales(for: employee.id)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddEmployee = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showAddEmployee) {
            AddEmployeeView(boutiqueId: boutiqueId, staffVM: staffVM, vm: addEmpVM)
        }
        .task {
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
        }
        .alert("Error", isPresented: Binding(
            get: { staffVM.errorMessage != nil },
            set: { if !$0 { staffVM.errorMessage = nil } }
        )) {
            Button("OK") { staffVM.errorMessage = nil }
        } message: {
            Text(staffVM.errorMessage ?? "")
        }
    }

    // MARK: - Employee List
    private var employeeList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(staffVM.employees) { employee in
                    NavigationLink(destination:
                        EmployeeSalesDetailView(employee: employee, boutiqueId: boutiqueId)
                    ) {
                        StaffDirectoryCard(employee: employee)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 52))
                .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.5))
            Text("No staff found")
                .font(.headline)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Button {
                showAddEmployee = true
            } label: {
                Label("Add Employee", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RSMSTheme.Colors.accentGold)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - Staff Directory Card
struct StaffDirectoryCard: View {
    let employee: Employee

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(employee.name.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.headline)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(employee.role)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                if let phone = employee.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption2)
                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                }

                // Active badge
                Text((employee.isActive ?? true) ? "ACTIVE" : "INACTIVE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background((employee.isActive ?? true) ? RSMSTheme.Colors.success.opacity(0.15) : RSMSTheme.Colors.error.opacity(0.15))
                    .foregroundColor((employee.isActive ?? true) ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
                    .cornerRadius(4)
            }

            Spacer()

            // Status pill
            Text("Active")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12))
                .cornerRadius(8)

            Image(systemName: "chevron.right")
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.4))
                .font(.caption)
                .padding(.leading, 8)
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundDeep)
        //.cornerRadius(14)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}
