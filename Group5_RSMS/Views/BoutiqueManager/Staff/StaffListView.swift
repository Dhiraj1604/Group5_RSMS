//
//  StaffListView.swift
//  Group5_RSMS
//

import SwiftUI

struct StaffListView: View {
    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var commissionVM = CommissionViewModel()
    @State private var showAddEmployee = false

    let boutiqueId: UUID

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
                        Label("Add Employee", systemImage: "plus")
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(staffVM.employees) { employee in
                            NavigationLink(destination:
                                EmployeeSalesDetailView(
                                    employee: employee,
                                    boutiqueId: boutiqueId
                                )
                            ) {
                                EmployeeCard(
                                    employee: employee,
                                    totalSales: staffVM.totalSales(for: employee.id)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddEmployee = true
                } label: {
                    Image(systemName: "plus")
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
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(12)
    }
}
