//
//  EmployeeSalesDetailView.swift
//  Group5_RSMS
//

import SwiftUI

struct EmployeeSalesDetailView: View {
    let employee: Employee
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel

    @StateObject private var commissionVM = CommissionViewModel()
    @State private var showSetCommission = false
    @State private var showCreatePayout = false
    @State private var showDeleteConfirmation = false
    @State private var optimisticIsActive: Bool? = nil
    
    @State private var employeeOrders: [EmployeeOrder] = []
    @State private var isLoadingOrders = true

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

    // Computed Sales Metrics
    private var totalSalesParams: Double { employeeOrders.reduce(0) { $0 + $1.totalAmount } }
    private var currentMonthSales: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        return employeeOrders.filter { 
            Calendar.current.component(.month, from: $0.createdAt) == currentMonth &&
            Calendar.current.component(.year, from: $0.createdAt) == currentYear
        }.reduce(0) { $0 + $1.totalAmount }
    }
    private var totalOrders: Int { employeeOrders.count }
    private var avgOrderValue: Double { totalOrders > 0 ? (totalSalesParams / Double(totalOrders)) : 0.0 }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Employee Header
                    // MARK: - Employee Header
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
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

                        // Status Toggle
                        Toggle(isOn: Binding<Bool>(
                            get: { displayIsActive },
                            set: { newValue in
                                optimisticIsActive = newValue
                                Task {
                                    // Pass currentEmployee so the next toggle correctly negates the NEW status
                                    await staffVM.toggleEmployeeStatus(currentEmployee, boutiqueId: boutiqueId)
                                }
                            }
                        )) {
                            Text(displayIsActive ? "Active Account" : "Inactive Account")
                                .font(.subheadline)
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        .tint(RSMSTheme.Colors.success)
                        .padding(.horizontal, 60)
                        .padding(.top, 8)
                    }
                    .padding(.top)

                    // MARK: - Info Cards
                    HStack(spacing: 12) {
                        InfoCard(title: "Phone", value: currentEmployee.phone ?? "N/A", icon: "phone.fill")
                        InfoCard(title: "Email", value: currentEmployee.email ?? "N/A", icon: "envelope.fill")
                    }
                    .padding(.horizontal)

                    // MARK: - Sales Summary Card
                    HStack(spacing: 0) {
                        EmployeeStatCell(title: "Salary", value: employee.salary.map { "₹\(Int($0))" } ?? "N/A", icon: "indianrupeesign.circle.fill")
                        Divider().frame(height: 40).background(RSMSTheme.Colors.textSecondary.opacity(0.2))
                        EmployeeStatCell(title: "Shifts", value: "–", icon: "clock.fill")
                        Divider().frame(height: 40).background(RSMSTheme.Colors.textSecondary.opacity(0.2))
                        EmployeeStatCell(title: "Commission", value: currentRate != nil ? String(format: "%.1f", currentRate!.ratePercentage) + "%" : "Not Set", icon: "percent")
                    }
                    .padding()
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(14)
                    // MARK: - Sales Performance Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sales Performance")
                            .font(.headline)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)

                        if isLoadingOrders {
                            ProgressView()
                                .tint(RSMSTheme.Colors.accentGold)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            VStack(spacing: 10) {
                                HStack(spacing: 10) {
                                    PerformanceMetricBlock(title: "Total Sales", value: "₹\(String(format: "%.0f", totalSalesParams))")
                                    PerformanceMetricBlock(title: "This Month", value: "₹\(String(format: "%.0f", currentMonthSales))")
                                }
                                HStack(spacing: 10) {
                                    PerformanceMetricBlock(title: "Total Orders", value: "\(totalOrders)")
                                    PerformanceMetricBlock(title: "Avg Order Value", value: "₹\(String(format: "%.0f", avgOrderValue))")
                                }
                            }
                        }
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
                                        .foregroundColor(RSMSTheme.Colors.error)
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
                                    managerId: appState.managerAuthId ?? UUID(),   // ← pass it here
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
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(RSMSTheme.Colors.error)
                }
                .confirmationDialog("Delete Employee", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) {
                        dismiss()
                        Task {
                            await staffVM.deleteEmployee(employee, boutiqueId: boutiqueId)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete \(currentEmployee.name)? This will permanently remove their profile and all associated data.")
                }
            }
        }
        .task {
            isLoadingOrders = true
            
            async let fetchRates: () = await commissionVM.fetchCommissionRates(boutiqueId: boutiqueId)
            async let fetchPayouts: () = await commissionVM.fetchPayouts(employeeId: employee.id)
            async let fetchOrders: () = {
                if let fetched = try? await SupabaseSyncManager.shared.fetchEmployeeOrders(employeeId: employee.id) {
                    self.employeeOrders = fetched
                }
                isLoadingOrders = false
            }()
            
            _ = await (fetchRates, fetchPayouts, fetchOrders)
        }
        .sheet(isPresented: $showSetCommission) {
            SetCommissionView(
                employee: employee,
                boutiqueId: boutiqueId,
                commissionVM: commissionVM
            )
        }
        .sheet(isPresented: $showCreatePayout) {
            CommissionPayoutView(
                employee: employee,
                boutiqueId: boutiqueId,
                commissionVM: commissionVM
            )
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
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)  // ← shrinks text to fit instead of cutting
                
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(12)
    }
}

// MARK: - Stat Cell (used in employee 3-column row)
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
                Text("₹\(payout.commissionAmount, specifier: "%.2f")")
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
                        .foregroundColor(RSMSTheme.Colors.error)
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
