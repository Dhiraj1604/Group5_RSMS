//
//  StaffListView.swift
//  Group5_RSMS
//

import SwiftUI

enum StaffFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case inactive = "Inactive"
}

struct StaffListView: View {
    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var commissionVM = CommissionViewModel()
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
                ProgressView()
                    .tint(RSMSTheme.Colors.accentGold)
            } else if staffVM.employees.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.5))
                    Text("No staff found")
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .font(.body)
                    // Add Employee button in empty state too
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
                    .padding(.top, 8)
                }
            } else {
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
            AddEmployeeView(boutiqueId: boutiqueId, staffVM: staffVM)
        }
        .task {
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            await staffVM.fetchSalesPerEmployee(boutiqueId: boutiqueId)
        }
        .alert("Error", isPresented: .constant(staffVM.errorMessage != nil)) {
            Button("OK") { staffVM.errorMessage = nil }
        } message: {
            Text(staffVM.errorMessage ?? "")
        }
    }
}

// MARK: - Employee Card
struct EmployeeCard: View {
    let employee: Employee
    let totalSales: Double

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(employee.name.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.headline)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(employee.role)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)

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

            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(totalSales, specifier: "%.0f")")
                    .font(.headline)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text("Total Sales")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .font(.caption)
                .padding(.leading, 8)
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}
