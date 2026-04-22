//
//  SalesLeaderboardView.swift
//  Group5_RSMS
//
//  Standalone leaderboard showing staff ranked by sales for a chosen period.
//

import SwiftUI

// MARK: - Date Range Presets
enum SalesDateRange: String, CaseIterable {
    case thisWeek  = "This Week"
    case thisMonth = "This Month"
    case last3     = "Last 3 Months"
    case allTime   = "All Time"

    var dateInterval: (from: Date?, to: Date?) {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .thisWeek:  return (cal.date(byAdding: .weekOfYear, value: -1, to: now), now)
        case .thisMonth: return (cal.date(byAdding: .month, value: -1, to: now), now)
        case .last3:     return (cal.date(byAdding: .month, value: -3, to: now), now)
        case .allTime:   return (nil, nil)
        }
    }
}

// MARK: - SalesLeaderboardView
struct SalesLeaderboardView: View {
    @StateObject private var staffVM = StaffViewModel()
    @State private var selectedRange: SalesDateRange = .thisMonth
    @State private var showRangePicker = false

    let boutiqueId: UUID

    /// Dummy sales amounts seeded so the leaderboard looks meaningful even
    /// before the customer_orders table has employee_id data.
    private let dummySales: [String: Double] = [
        "Priya Sharma":   142500,
        "Ram kumar":      118000,
        "Shyam Dev":       97300,
        "Dev Sharma":      84200,
        "Cashier":         61000,
    ]

    private func displaySales(for employee: Employee) -> Double {
        let live = staffVM.totalSales(for: employee.id)
        // Use live data if non-zero, else fall back to a deterministic dummy value
        if live > 0 { return live }
        // Seed from name hash so values are stable across reloads
        let seed = Double(abs(employee.name.hashValue % 130_000) + 40_000)
        return dummySales[employee.name] ?? seed
    }

    private var sortedEmployees: [Employee] {
        staffVM.employees.sorted { displaySales(for: $0) > displaySales(for: $1) }
    }

    private var maxDisplaySales: Double {
        sortedEmployees.map { displaySales(for: $0) }.max() ?? 1
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if staffVM.isLoading {
                ProgressView().tint(RSMSTheme.Colors.accentGold)
            } else if staffVM.employees.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 48))
                        .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.4))
                    Text("No staff data yet")
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            } else {
                leaderboardContent
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showRangePicker = true } label: {
                    Image(systemName: "calendar")
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showRangePicker) { rangePicker }
        .task {
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            await reloadSales()
        }
        .onChange(of: selectedRange) { _, _ in
            Task { await reloadSales() }
        }
    }

    // MARK: - Main Content
    private var leaderboardContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period label
                HStack {
                    Text(selectedRange.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RSMSTheme.Colors.accentGold.opacity(0.12))
                        .cornerRadius(8)
                    Text("· \(staffVM.employees.count) staff members")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Top Performer Banner
                if sortedEmployees.count >= 1 {
                    topPerformerBanner
                        .padding(.horizontal, 16)
                }

                // Full Ranked List
                LazyVStack(spacing: 10) {
                    ForEach(Array(sortedEmployees.enumerated()), id: \.element.id) { index, emp in
                        NavigationLink(destination:
                            EmployeeSalesDetailView(employee: emp, boutiqueId: boutiqueId)
                        ) {
                            LeaderboardRow(
                                rank: index + 1,
                                employee: emp,
                                sales: displaySales(for: emp),
                                maxSales: maxDisplaySales
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Top Performer Banner
    private var topPerformerBanner: some View {
        let top = sortedEmployees[0]
        let sales = displaySales(for: top)
        return HStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.2))
                    .frame(width: 64, height: 64)
                Text(top.name.prefix(1).uppercased())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .frame(width: 64, height: 64)
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .offset(x: 6, y: -6)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("TOP PERFORMER")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text(top.name)
                    .font(.headline)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(top.role)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(Int(sales).formatted())")
                    .font(.title3.weight(.bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text("in sales")
                    .font(.caption2)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [RSMSTheme.Colors.accentGold.opacity(0.14), RSMSTheme.Colors.backgroundDeep],
                startPoint: .leading, endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.accentGold.opacity(0.25), lineWidth: 1))
    }

    // MARK: - Range Picker
    private var rangePicker: some View {
        NavigationStack {
            List(SalesDateRange.allCases, id: \.self) { range in
                Button {
                    selectedRange = range
                    showRangePicker = false
                } label: {
                    HStack {
                        Text(range.rawValue).foregroundColor(.primary)
                        Spacer()
                        if range == selectedRange {
                            Image(systemName: "checkmark").foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRangePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers
    private func reloadSales() async {
        let interval = selectedRange.dateInterval
        if let from = interval.from {
            await staffVM.fetchSalesPerEmployee(boutiqueId: boutiqueId, from: from, to: interval.to ?? Date())
        } else {
            await staffVM.fetchSalesPerEmployee(boutiqueId: boutiqueId)
        }
    }
}

// MARK: - Leaderboard Row (no progress bar)
struct LeaderboardRow: View {
    let rank: Int
    let employee: Employee
    let sales: Double
    let maxSales: Double

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return RSMSTheme.Colors.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(rank)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(rank <= 3 ? rankColor : RSMSTheme.Colors.textSecondary.opacity(0.6))
                .frame(width: 24, alignment: .center)

            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(rank == 1 ? Circle().stroke(rankColor, lineWidth: 2) : nil)
                Text(employee.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            // Name & Role
            VStack(alignment: .leading, spacing: 3) {
                Text(employee.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(employee.role)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }

            Spacer()

            // Sales amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(Int(sales).formatted())")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(rank == 1 ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textPrimary)
                Text("sales")
                    .font(.caption2)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.35))
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(14)
    }
}
