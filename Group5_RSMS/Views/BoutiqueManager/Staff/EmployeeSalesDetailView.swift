//
//  EmployeeSalesDetailView.swift
//  Group5_RSMS
//

import SwiftUI

struct EmployeeSalesDetailView: View {
    let employee: Employee
    let boutiqueId: UUID

    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var commissionVM = CommissionViewModel()
    @StateObject private var shiftVM = ShiftViewModel()
    @State private var showSetCommission = false
    @State private var showCreatePayout = false
    @State private var showDeleteConfirmation = false
    @State private var optimisticIsActive: Bool? = nil

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var currentRate: CommissionRate? {
        commissionVM.currentRate(for: employee.id)
    }

    private var currentEmployee: Employee {
        staffVM.employees.first(where: { $0.id == employee.id }) ?? employee
    }

    private var displayIsActive: Bool {
        optimisticIsActive ?? (currentEmployee.isActive ?? true)
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Employee Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Text(currentEmployee.name.prefix(1).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                                .frame(width: 80, height: 80)
                        }

                        Text(currentEmployee.name)
                            .font(.title2)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)

                        Text(currentEmployee.role)
                            .font(.body)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)

                        if let joining = employee.joiningDate {
                            Text("Since \(joining.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                        }

                        // Active / Inactive toggle
                        Toggle(isOn: Binding<Bool>(
                            get: { displayIsActive },
                            set: { _ in
                                optimisticIsActive = !displayIsActive
                                Task {
                                    await staffVM.toggleEmployeeStatus(currentEmployee, boutiqueId: boutiqueId)
                                }
                            }
                        )) {
                            Text(displayIsActive ? "Active Account" : "Inactive Account")
                                .font(.subheadline)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        .tint(RSMSTheme.Colors.success)
                        .padding(.horizontal, 30)
                        .padding(.top, 8)
                    }
                    .padding(.top)

                    // MARK: - Info Cards
                    HStack(spacing: 12) {
                        InfoCard(title: "Phone", value: currentEmployee.phone ?? "N/A", icon: "phone.fill")
                        InfoCard(title: "Email", value: currentEmployee.email ?? "N/A", icon: "envelope.fill")
                    }
                    .padding(.horizontal)

                    // MARK: - Key Stats Row
                    HStack(spacing: 0) {
                        EmployeeStatCell(
                            title: "Salary",
                            value: employee.salary.map { "₹\(Int($0))" } ?? "N/A",
                            icon: "indianrupeesign.circle.fill"
                        )
                        Divider().frame(height: 40).background(RSMSTheme.Colors.textSecondary.opacity(0.2))
                        EmployeeStatCell(
                            title: "Shifts",
                            value: shiftVM.shifts.isEmpty ? "–" : "\(shiftVM.shifts.filter { $0.employeeId == employee.id }.count)",
                            icon: "clock.fill"
                        )
                        Divider().frame(height: 40).background(RSMSTheme.Colors.textSecondary.opacity(0.2))
                        EmployeeStatCell(
                            title: "Commission",
                            value: currentRate != nil ? String(format: "%.1f", currentRate!.ratePercentage) + "%" : "Not Set",
                            icon: "percent"
                        )
                    }
                    .padding()
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(14)
                    .padding(.horizontal)

                    // MARK: - Sales Performance Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sales Performance")
                            .font(.headline)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)

                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                PerformanceMetricBlock(title: "Total Sales", value: "₹0")
                                PerformanceMetricBlock(title: "This Month", value: "₹0")
                            }
                            HStack(spacing: 10) {
                                PerformanceMetricBlock(title: "Total Orders", value: "0")
                                PerformanceMetricBlock(title: "Avg Order Value", value: "₹0")
                            }
                        }

                        Text("Sales data will appear here once linked to customer orders.")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // MARK: - Commission Rate Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Commission")
                            .font(.headline)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Rate")
                                    .font(.caption)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                Text(currentRate != nil ? String(format: "%.1f", currentRate!.ratePercentage) + "%" : "Not Set")
                                    .font(.title2)
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                            }
                            Spacer()

                            if let rate = currentRate {
                                Button {
                                    Task {
                                        await commissionVM.deleteCommissionRate(id: rate.id, boutiqueId: boutiqueId)
                                    }
                                } label: {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                        .padding(.trailing, 8)
                                }
                            }

                            Button {
                                showSetCommission = true
                            } label: {
                                Text(currentRate != nil ? "Update Rate" : "Set Rate")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(RSMSTheme.Colors.accentGold)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // MARK: - Payouts Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Payouts")
                                .font(.headline)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            Spacer()
                            Button {
                                showCreatePayout = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                                    .font(.title3)
                            }
                        }

                        if commissionVM.payouts.isEmpty {
                            Text("No payouts yet")
                                .font(.body)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(commissionVM.payouts) { payout in
                                PayoutRow(
                                    payout: payout,
                                    managerId: appState.managerAuthId ?? UUID(),
                                    commissionVM: commissionVM
                                )
                            }
                        }
                    }
                    .padding()
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(employee.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .confirmationDialog(
                    "Delete Employee",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        dismiss()
                        Task { await staffVM.deleteEmployee(employee, boutiqueId: boutiqueId) }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete \(currentEmployee.name)?")
                }
            }
        }
        .task {
            await commissionVM.fetchCommissionRates(boutiqueId: boutiqueId)
            await commissionVM.fetchPayouts(employeeId: employee.id)
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            await shiftVM.fetchShifts(boutiqueId: boutiqueId)
        }
        .sheet(isPresented: $showSetCommission) {
            SetCommissionView(employee: employee, boutiqueId: boutiqueId, commissionVM: commissionVM)
        }
        .sheet(isPresented: $showCreatePayout) {
            CommissionPayoutView(employee: employee, boutiqueId: boutiqueId, commissionVM: commissionVM)
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(RSMSTheme.Colors.accentGold)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .truncationMode(.middle)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(12)
    }
}

// MARK: - Employee Stat Cell
struct EmployeeStatCell: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(RSMSTheme.Colors.accentGold)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Performance Metric Block
struct PerformanceMetricBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .lineLimit(1)
            Text(value)
                .font(.headline)
                .foregroundColor(RSMSTheme.Colors.accentGold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RSMSTheme.Colors.backgroundPrimary)
        .cornerRadius(8)
    }
}

// MARK: - Payout Row
struct PayoutRow: View {
    let payout: CommissionPayout
    let managerId: UUID
    @ObservedObject var commissionVM: CommissionViewModel

    var statusColor: Color {
        switch payout.status {
        case .pending:  return .orange
        case .approved: return .blue
        case .paid:     return .green
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("₹\(String(format: "%.2f", payout.commissionAmount))")
                    .font(.headline)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text("\(payout.periodStart.formatted(date: .abbreviated, time: .omitted)) – \(payout.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }

            Spacer()

            if payout.status == .pending {
                Button {
                    Task {
                        await commissionVM.deletePayout(id: payout.id, employeeId: payout.employeeId)
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }

                Button {
                    Task {
                        await commissionVM.approvePayout(
                            id: payout.id,
                            approvedBy: managerId,
                            employeeId: payout.employeeId
                        )
                    }
                } label: {
                    Text("Approve")
                        .font(.caption)
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RSMSTheme.Colors.accentGold)
                        .cornerRadius(8)
                }
            } else {
                Text(payout.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundPrimary)
        .cornerRadius(10)
    }
}
