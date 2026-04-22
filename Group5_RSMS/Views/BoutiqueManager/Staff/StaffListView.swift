//
//  StaffListView.swift
//  Group5_RSMS
//
//  Clean staff directory — just the list of employees with their contact + role info.
//

import SwiftUI

struct StaffListView: View {
    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var addEmpVM = AddEmployeeViewModel()
    @State private var showAddEmployee = false

    let boutiqueId: UUID

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if staffVM.isLoading {
                ProgressView().tint(RSMSTheme.Colors.accentGold)
            } else if staffVM.employees.isEmpty {
                emptyState
            } else {
                employeeList
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
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(14)
    }
}
