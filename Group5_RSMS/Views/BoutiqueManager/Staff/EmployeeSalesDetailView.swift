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
    @StateObject private var addEmpVM = AddEmployeeViewModel()
    
    @State private var showSetCommission = false
    @State private var showCreatePayout = false
    @State private var showEditEmployee = false
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
                VStack(spacing: 24) {

                    // MARK: - Employee Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                                .frame(width: 90, height: 90)
                            Text(currentEmployee.name.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }

                        VStack(spacing: 4) {
                            Text(currentEmployee.name)
                                .font(.title3.weight(.bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)

                            Text(currentEmployee.role)
                                .font(.subheadline)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)

                            if let joining = employee.joiningDate {
                                Text("Joined \(joining.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.6))
                            }
                        }

                        // Active / Inactive toggle
                        HStack {
                            Text(displayIsActive ? "Active" : "Inactive")
                                .font(.caption.weight(.bold))
                                .foregroundColor(displayIsActive ? RSMSTheme.Colors.success : .red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background((displayIsActive ? RSMSTheme.Colors.success : Color.red).opacity(0.1))
                                .cornerRadius(20)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding<Bool>(
                                get: { displayIsActive },
                                set: { _ in
                                    optimisticIsActive = !displayIsActive
                                    Task {
                                        await staffVM.toggleEmployeeStatus(currentEmployee, boutiqueId: boutiqueId)
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(RSMSTheme.Colors.success)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(14)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top)

                    // MARK: - Info Cards
                    HStack(spacing: 12) {
                        InfoCard(title: "Phone", value: currentEmployee.phone ?? "N/A", icon: "phone.fill")
                        InfoCard(title: "Email", value: currentEmployee.email ?? "N/A", icon: "envelope.fill")
                    }
                    .padding(.horizontal)

                    // MARK: - Key Stats Row
                    VStack(alignment: .leading, spacing: 12) {
                        Text("EMPLOYMENT INFO")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                EmployeeStatCell(
                                    title: "Salary",
                                    value: employee.salary.map { "₹\(Int($0))" } ?? "N/A",
                                    icon: "indianrupeesign"
                                )
                                Divider().frame(height: 30).background(RSMSTheme.Colors.textSecondary.opacity(0.1))
                                EmployeeStatCell(
                                    title: "Commission",
                                    value: currentRate != nil ? String(format: "%.1f", currentRate!.ratePercentage) + "%" : "N/A",
                                    icon: "percent"
                                )
                            }
                            .padding(.vertical, 16)
                            
                            Divider().background(RSMSTheme.Colors.textSecondary.opacity(0.1)).padding(.horizontal)
                            
                            HStack(spacing: 0) {
                                EmployeeStatCell(
                                    title: "Shift",
                                    value: currentEmployee.assignedShift ?? "N/A",
                                    icon: "clock"
                                )
                                Divider().frame(height: 30).background(RSMSTheme.Colors.textSecondary.opacity(0.1))
                                EmployeeStatCell(
                                    title: "Off Day",
                                    value: currentEmployee.weeklyOff ?? "N/A",
                                    icon: "calendar.badge.clock"
                                )
                            }
                            .padding(.vertical, 16)
                        }
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    // MARK: - Sales Performance Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SALES PERFORMANCE")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                            .padding(.leading, 4)

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                PerformanceMetricBlock(title: "Total Sales", value: "₹0")
                                PerformanceMetricBlock(title: "This Month", value: "₹0")
                            }
                            HStack(spacing: 12) {
                                PerformanceMetricBlock(title: "Total Orders", value: "0")
                                PerformanceMetricBlock(title: "Avg Order Value", value: "₹0")
                            }
                        }

                        Text("Sales data will appear here once linked to customer orders.")
                            .font(.caption2)
                            .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)

                    // MARK: - Commission Rate Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("COMMISSION SETTINGS")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                            .padding(.leading, 4)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current Rate")
                                    .font(.caption2)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                Text(currentRate != nil ? String(format: "%.1f", currentRate!.ratePercentage) + "%" : "Not Set")
                                    .font(.headline)
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                            }
                            Spacer()

                            if let rate = currentRate {
                                Button {
                                    Task {
                                        await commissionVM.deleteCommissionRate(id: rate.id, boutiqueId: boutiqueId)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .foregroundColor(.red.opacity(0.7))
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 4)
                            }

                            Button {
                                showSetCommission = true
                            } label: {
                                Text(currentRate != nil ? "Edit" : "Set")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(RSMSTheme.Colors.accentGold)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    // MARK: - Payouts Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PAYOUT HISTORY")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                                .padding(.leading, 4)
                            Spacer()
                            Button {
                                showCreatePayout = true
                            } label: {
                                Image(systemName: "plus")
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                                    .font(.caption.weight(.bold))
                                    .padding(6)
                                    .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }

                        if commissionVM.payouts.isEmpty {
                            Text("No payout records found")
                                .font(.subheadline)
                                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.5))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 1) {
                                ForEach(commissionVM.payouts) { payout in
                                    PayoutRow(
                                        payout: payout,
                                        managerId: appState.managerAuthId ?? UUID(),
                                        commissionVM: commissionVM
                                    )
                                    
                                    if payout.id != commissionVM.payouts.last?.id {
                                        Divider().background(RSMSTheme.Colors.textSecondary.opacity(0.1))
                                    }
                                }
                            }
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(currentEmployee.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditEmployee = true
                } label: {
                    Image(systemName: "pencil")
                        .fontWeight(.semibold)
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .task {
            await commissionVM.fetchCommissionRates(boutiqueId: boutiqueId)
            await commissionVM.fetchPayouts(employeeId: employee.id)
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            await shiftVM.fetchShifts(boutiqueId: boutiqueId)
        }
        .sheet(isPresented: $showEditEmployee) {
            AddEmployeeView(boutiqueId: boutiqueId, staffVM: staffVM, vm: addEmpVM, employeeToEdit: currentEmployee)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .font(.caption)
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(14)
    }
}

// MARK: - Employee Stat Cell
struct EmployeeStatCell: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.8))
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Performance Metric Block
struct PerformanceMetricBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.6))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.accentGold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(12)
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
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("₹\(String(format: "%.2f", payout.commissionAmount))")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text("\(payout.periodStart.formatted(date: .abbreviated, time: .omitted)) – \(payout.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
            }

            Spacer()

            if payout.status == .pending {
                HStack(spacing: 12) {
                    Button {
                        Task {
                            await commissionVM.deletePayout(id: payout.id, employeeId: payout.employeeId)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red.opacity(0.6))
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RSMSTheme.Colors.accentGold)
                            .cornerRadius(6)
                    }
                }
            } else {
                Text(payout.status.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(16)
    }
}
