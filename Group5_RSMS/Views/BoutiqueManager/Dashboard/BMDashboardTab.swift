//
//  BMDashboardTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Dashboard. Uses shared RSMSTheme (dark/gold).
//  Top 3 performers shown inline; See All navigates to full list.
//

import SwiftUI

// MARK: - See All Staff Performance
struct AllStaffPerformanceView: View {
    let entries: [StaffPerformanceEntry]

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        let maxComm = entries.map { $0.potentialCommission }.max() ?? 1
                        StaffPerfRow(entry: entry, rank: index + 1, maxValue: maxComm)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Staff Performance")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
    }
}

// MARK: - See All Tasks
struct AllTasksView: View {
    @ObservedObject var tasksVM: BMTasksViewModel

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            if tasksVM.tasks.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(RSMSTheme.Colors.success.opacity(0.5))
                    Text("All tasks completed!")
                        .font(.headline)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tasksVM.tasks) { task in
                            let staffName = tasksVM.staff.first(where: { $0.id == task.assignedTo })?.name
                            TaskRowView(task: task, onToggle: {
                                Task { await tasksVM.cycleTaskStatus(task) }
                            }, staffName: staffName)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Store Tasks")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
    }
}

// MARK: - Main Dashboard
struct BMDashboardTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var tasksVM     = BMTasksViewModel()
    @StateObject private var dashboardVM = BMDashboardViewModel()

    @State private var showingAddTask = false
    @State private var showingProfile = false

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        pacingCard.padding(.horizontal, 20)
                        teamMetricsRow.padding(.horizontal, 20)
                        staffSection
                        tasksSection.padding(.horizontal, 20)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 14) {
                        Button { showingAddTask = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityLabel("Add task")
                        .accessibilityHint("Opens the form to create a new store task.")
                        Button { showingProfile = true } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityLabel("My profile")
                        .accessibilityHint("Opens profile, appearance, and account settings.")
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                BMProfileView().presentationDetents([.large])
            }
            .sheet(isPresented: $showingAddTask) {
                if let boutiqueId = appState.currentStoreID {
                    AddTaskSheet(boutiqueId: boutiqueId, staff: tasksVM.staff) { newTask in
                        Task { await tasksVM.addTask(newTask) }
                    }
                }
            }
            .task {
                if let id = appState.currentStoreID {
                    await dashboardVM.loadDailyPacing(boutiqueId: id)
                    await dashboardVM.loadStaffPerformance(boutiqueId: id)
                    await tasksVM.fetchTasksAndStaff(boutiqueId: id)
                }
            }
            .onChange(of: appState.currentStoreID) { _, newId in
                guard let id = newId else { return }
                Task {
                    await dashboardVM.loadDailyPacing(boutiqueId: id)
                    await dashboardVM.loadStaffPerformance(boutiqueId: id)
                    await tasksVM.fetchTasksAndStaff(boutiqueId: id)
                }
            }
        }
    }

    // MARK: - Greeting Header
    private var greetingHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Text("Boutique Manager")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            Text(Date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.system(size: 14))
                .foregroundColor(RSMSTheme.Colors.textTertiary)
        }
    }

    // MARK: - Daily Pacing Card
    private var pacingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DAILY PACING")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Spacer()
                Text("\(Int(dashboardVM.progress * 100))% to target")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .clipShape(Capsule())
            }

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(RSMSTheme.Colors.surfacePrimary, lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: dashboardVM.progress)
                        .stroke(RSMSTheme.Colors.accentGold, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: dashboardVM.progress)
                    VStack(spacing: 2) {
                        Text("\(Int(dashboardVM.progress * 100))%")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        Text("achieved")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }
                .frame(width: 115, height: 115)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actual Sales")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        Text(dashboardVM.actualSales, format: .currency(code: "INR"))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(RSMSTheme.Colors.success)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        Text(dashboardVM.dailyTarget, format: .currency(code: "INR"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                    }
                }
                Spacer()
            }
        }
        .padding(18)
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily sales pacing.")
        .accessibilityValue("\(Int(dashboardVM.progress * 100)) percent of daily target achieved. Actual sales are \(dashboardVM.actualSales.formatted(.currency(code: "INR"))). The daily target is \(dashboardVM.dailyTarget.formatted(.currency(code: "INR"))).")
    }

    // MARK: - Team Metrics Row
    private var teamMetricsRow: some View {
        HStack(spacing: 10) {
            DashMetricCard(icon: "indianrupeesign.circle.fill", title: "Team Sales",  value: "₹\(fmt(dashboardVM.teamTotalSales))")
            DashMetricCard(icon: "calendar.circle.fill",        title: "This Month",  value: "₹\(fmt(dashboardVM.teamThisMonthSales))")
            DashMetricCard(icon: "bag.circle.fill",             title: "Orders",      value: "\(dashboardVM.teamTotalOrders)")
        }
    }

    // MARK: - Staff Section (Top 3 + See All)
    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Performers")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)

            if dashboardVM.isLoadingStaff {
                ProgressView()
                    .tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity).padding(24)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
            } else if dashboardVM.staffPerformance.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 36))
                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.4))
                    Text("No sales data yet")
                        .font(.subheadline)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 28)
                .background(RSMSTheme.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            } else {
                // ✅ Show top 3 based on potential commission
                let maxComm = dashboardVM.staffPerformance.map { $0.potentialCommission }.max() ?? 1
                VStack(spacing: 10) {
                    ForEach(Array(dashboardVM.staffPerformance.prefix(3).enumerated()), id: \.element.id) { idx, entry in
                        StaffPerfRow(entry: entry, rank: idx + 1, maxValue: maxComm)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Tasks Section (Top 2 + See All)
    private var tasksSection: some View {
        let pending = tasksVM.tasks.filter { $0.status != .verified }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Store Tasks")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                if pending.count > 2 {
                    NavigationLink(destination: AllTasksView(tasksVM: tasksVM)) {
                        HStack(spacing: 3) {
                            Text("See All")
                                .font(.system(size: 14, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
            }

            if tasksVM.isLoading && tasksVM.tasks.isEmpty {
                ProgressView()
                    .tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity).padding(24)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if pending.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(RSMSTheme.Colors.success.opacity(0.7))
                    Text("All tasks completed!")
                        .font(.subheadline)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(RSMSTheme.Colors.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            } else {
                VStack(spacing: 10) {
                    ForEach(pending.prefix(2)) { task in
                        let staffName = tasksVM.staff.first(where: { $0.id == task.assignedTo })?.name
                        TaskRowView(task: task, onToggle: {
                            Task { await tasksVM.cycleTaskStatus(task) }
                        }, staffName: staffName)
                    }
                }
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "%.2fCr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "%.2fL", v / 100_000) }
        if v >= 1_000      { return String(format: "%.1fK", v / 1_000) }
        return String(format: "%.0f", v)
    }
}

// MARK: - Dashboard Metric Card (3-up)
struct DashMetricCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.accentGold)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title).")
        .accessibilityValue("\(value).")
    }
}

// MARK: - Staff Performance Row
struct StaffPerfRow: View {
    let entry: StaffPerformanceEntry
    let rank: Int
    let maxValue: Double

    private var pct: Double { maxValue > 0 ? entry.potentialCommission / maxValue : 0 }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return RSMSTheme.Colors.textSecondary
        }
    }

    private func formatValue(_ v: Double) -> String {
        if v >= 10_000_000 { return String(format: "%.2fCr", v / 10_000_000) }
        if v >= 100_000    { return String(format: "%.2fL", v / 100_000) }
        if v >= 1_000      { return String(format: "%.1fK", v / 1_000) }
        return String(format: "%.0f", v)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(rank <= 3 ? rankColor.opacity(0.18) : RSMSTheme.Colors.surfacePrimary)
                        .frame(width: 36, height: 36)
                    if rank <= 3 {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(rankColor)
                    } else {
                        Text("#\(rank)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary).lineLimit(1)
                    
                    Text("\(Int(entry.commissionRate))% rate")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                        .cornerRadius(4)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("₹\(formatValue(entry.potentialCommission))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(rank <= 3 ? rankColor : RSMSTheme.Colors.textPrimary)
                    Text("est. commission")
                        .font(.system(size: 11))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(rank). \(entry.name).")
        .accessibilityValue("Estimated commission is \(entry.potentialCommission.formatted(.currency(code: "INR"))). Commission rate is \(Int(entry.commissionRate)) percent.")
    }
}

#Preview {
    BMDashboardTab().environment(AppState())
}
