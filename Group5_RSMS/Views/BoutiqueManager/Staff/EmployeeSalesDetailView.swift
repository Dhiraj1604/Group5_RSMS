//
//  EmployeeSalesDetailView.swift
//  Group5_RSMS
//
//  Premium Employee Detail View - iOS 26 Liquid Glass & Segmented Cards.
//

import SwiftUI

struct EmployeeSalesDetailView: View {
    let employee: Employee
    let boutiqueId: UUID

    @StateObject private var staffVM = StaffViewModel()
    @StateObject private var commissionVM = CommissionViewModel()
    @StateObject private var shiftVM = ShiftViewModel()
    
    @State private var showEditEmployee = false
    @State private var showSetCommission = false
    @State private var optimisticIsActive: Bool? = nil

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var currentEmployee: Employee {
        staffVM.employees.first(where: { $0.id == employee.id }) ?? employee
    }

    private var currentRate: CommissionRate? {
        commissionVM.currentRate(for: employee.id)
    }

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    
                    // MARK: - Header Profile (Liquid Glass Card)
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 160, height: 160)
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                            
                            Text(currentEmployee.name.prefix(1).uppercased())
                                .font(.custom("Helvetica", size: 80))
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                            
                            if !(currentEmployee.isActive ?? true) {
                                Image(systemName: "person.slash.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 55, y: 55)
                            }
                        }
                        .padding(.top, 40)

                        VStack(spacing: 10) {
                            Text(currentEmployee.name)
                                .font(.custom("Helvetica", size: 48))
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(currentEmployee.role.uppercased())
                                .font(.custom("Helvetica", size: 14))
                                .fontWeight(.black)
                                .tracking(3)
                                .foregroundColor(.accentColor)
                            
                            if let joining = currentEmployee.joiningDate {
                                Text("ASSOCIATED SINCE \(joining.formatted(.dateTime.year().month(.wide)))")
                                    .font(.custom("Helvetica", size: 11))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                                    .tracking(1.5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // MARK: - Contact Actions
                    HStack(spacing: 24) {
                        LiquidActionButton(icon: "phone.fill", color: .green)
                        LiquidActionButton(icon: "envelope.fill", color: .blue)
                        LiquidActionButton(icon: "message.fill", color: .orange)
                    }
                    .padding(.horizontal, 32)

                    // MARK: - Key Metrics (Segmented Cards)
                    HStack(spacing: 20) {
                        SegmentedMetricCard(title: "ANNUAL SALARY", value: currentEmployee.salary.map { "₹\(Int($0).formatted())" } ?? "N/A", icon: "indianrupeesign", color: .green)
                        SegmentedMetricCard(title: "TOTAL SHIFTS", value: "\(shiftVM.shifts.filter { $0.employeeId == employee.id }.count)", icon: "calendar", color: .blue)
                        SegmentedMetricCard(title: "COMMISSION", value: currentRate != nil ? "\(Int(currentRate!.ratePercentage))%" : "0%", icon: "percent", color: .orange)
                    }
                    .padding(.horizontal, 32)

                    // MARK: - Performance Intelligence
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Performance Intelligence")
                            .font(.custom("Helvetica", size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                        
                        VStack(spacing: 0) {
                            PerformanceIntelligenceRow(label: "Gross Revenue Contribution", value: "₹\(Int(staffVM.totalSales(for: employee.id)).formatted())", icon: "chart.line.uptrend.xyaxis")
                            Divider().opacity(0.3).padding(.leading, 64)
                            PerformanceIntelligenceRow(label: "Total Transactions", value: "\(staffVM.transactionCount(for: employee.id))", icon: "bag.fill")
                            Divider().opacity(0.3).padding(.leading, 64)
                            PerformanceIntelligenceRow(label: "Avg Transaction Value", value: "₹\(Int(staffVM.averageOrderValue(for: employee.id)).formatted())", icon: "sparkles")
                            Divider().opacity(0.3).padding(.leading, 64)
                            PerformanceIntelligenceRow(label: "Yield Strategy Status", value: currentEmployee.isActive ?? true ? "Optimal" : "Suspended", icon: "bolt.fill", valueColor: currentEmployee.isActive ?? true ? .green : .red)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 32)

                    // MARK: - Commission History
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("Payout Audit Trail")
                                .font(.custom("Helvetica", size: 24))
                                .fontWeight(.bold)
                            Spacer()
                            Button { showSetCommission = true } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.headline)
                            }
                        }
                        .padding(.horizontal, 8)
                        
                        VStack(spacing: 20) {
                            if commissionVM.payouts.isEmpty {
                                NoDataIntelligence(icon: "banknote.fill", message: "No disbursement records found")
                            } else {
                                ForEach(commissionVM.payouts) { payout in
                                    PayoutAuditRow(payout: payout)
                                    if payout.id != commissionVM.payouts.last?.id { Divider().opacity(0.3) }
                                }
                            }
                        }
                        .padding(32)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 80)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    LiquidBarButton(icon: "chevron.left")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showEditEmployee = true } label: {
                    LiquidBarButton(icon: "pencil")
                }
            }
        }
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $showEditEmployee) {
            EditEmployeeView(employee: currentEmployee, boutiqueId: boutiqueId, staffVM: staffVM)
        }
        .sheet(isPresented: $showSetCommission) {
            SetCommissionView(employee: employee, boutiqueId: boutiqueId, commissionVM: commissionVM)
        }
        .task {
            await commissionVM.fetchCommissionRates(boutiqueId: boutiqueId)
            await commissionVM.fetchPayouts(employeeId: employee.id)
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            await staffVM.fetchSalesPerEmployee(boutiqueId: boutiqueId)
            await shiftVM.fetchShifts(boutiqueId: boutiqueId)
        }
    }
}

    

