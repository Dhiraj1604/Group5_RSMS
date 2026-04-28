//
//  BMDashboardTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Dashboard. iOS 26 Liquid Glass & Segmented Cards.
//

import SwiftUI

struct BMDashboardTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var tasksVM     = BMTasksViewModel()
    @StateObject private var dashboardVM = BMDashboardViewModel()

    @State private var showingAddTask = false
    @State private var showingProfile = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    pacingCard
                    teamMetricsRow
                    staffSection
                    tasksSection
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 20) {
                        Button { showingAddTask = true } label: {
                            LiquidBarButton(icon: "plus")
                        }
                        Button { showingProfile = true } label: {
                            LiquidBarButton(icon: "person.fill")
                        }
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
        }
    }

    // MARK: - Daily Pacing (Segmented Card)
    private var pacingCard: some View {
        VStack(spacing: 0) {
            // Top: Progress Intelligence
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAILY VELOCITY")
                        .font(.custom("Helvetica", size: 12))
                        .fontWeight(.black)
                        .tracking(2)
                        .foregroundColor(.accentColor)
                    Text("Today's Performance")
                        .font(.custom("Helvetica", size: 28))
                        .fontWeight(.bold)
                }
                Spacer()
                Text("\(Int(dashboardVM.progress * 100))%")
                    .font(.custom("Helvetica", size: 20))
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
            }
            .padding(32)
            .background(.ultraThinMaterial)

            Divider().opacity(0.3)

            // Bottom: Analytics
            HStack(alignment: .center, spacing: 60) {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.tertiarySystemGroupedBackground), lineWidth: 20)
                    Circle()
                        .trim(from: 0, to: min(dashboardVM.progress, 1.0))
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0, dampingFraction: 0.7), value: dashboardVM.progress)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(dashboardVM.progress * 100))%")
                            .font(.custom("Helvetica", size: 44))
                            .fontWeight(.bold)
                        Text("ATTAINED")
                            .font(.custom("Helvetica", size: 10))
                            .fontWeight(.black)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 180, height: 180)

                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Current Sales", systemImage: "arrow.up.right.circle.fill")
                            .font(.custom("Helvetica", size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text(dashboardVM.actualSales, format: .currency(code: "INR"))
                            .font(.custom("Helvetica", size: 36))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Daily Objective", systemImage: "target")
                            .font(.custom("Helvetica", size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text(dashboardVM.dailyTarget, format: .currency(code: "INR"))
                            .font(.custom("Helvetica", size: 24))
                            .fontWeight(.bold)
                    }
                }
                Spacer()
            }
            .padding(40)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
    }

    // MARK: - Team Metrics Row
    private var teamMetricsRow: some View {
        HStack(spacing: 24) {
            DashMetricCard(
                icon: "indianrupeesign",
                iconColor: .green,
                title: "GROSS SALES",
                value: "₹\(fmt(dashboardVM.teamTotalSales))"
            )
            DashMetricCard(
                icon: "calendar",
                iconColor: .blue,
                title: "MONTHLY",
                value: "₹\(fmt(dashboardVM.teamThisMonthSales))"
            )
            DashMetricCard(
                icon: "bag.fill",
                iconColor: .purple,
                title: "VOLUME",
                value: "\(dashboardVM.teamTotalOrders)"
            )
        }
    }

    // MARK: - Staff Section
    private var staffSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Specialist Ranking")
                    .font(.system(size: 24, weight: .black))
                Spacer()
                if dashboardVM.staffPerformance.count > 3 {
                    NavigationLink(destination: AllStaffPerformanceView(
                        entries: dashboardVM.staffPerformance,
                        teamTotal: dashboardVM.teamTotalSales)) {
                        ZStack {
                            Capsule().fill(.ultraThinMaterial).frame(width: 56, height: 40)
                                .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                            Image(systemName: "chevron.right").font(.system(size: 14, weight: .bold))
                        }
                    }
                }
            }

            VStack(spacing: 16) {
                if dashboardVM.staffPerformance.isEmpty {
                    NoDataIntelligence(icon: "person.3.fill", message: "No performance data available")
                } else {
                    ForEach(Array(dashboardVM.staffPerformance.prefix(3).enumerated()), id: \.element.id) { idx, entry in
                        StaffPerfRow(entry: entry, rank: idx + 1, teamTotal: dashboardVM.teamTotalSales)
                    }
                }
            }
        }
    }

    // MARK: - Tasks Section
    private var tasksSection: some View {
        let pending = tasksVM.tasks.filter { $0.status != .verified }
        return VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Strategic Tasks")
                    .font(.system(size: 24, weight: .black))
                Spacer()
                if !pending.isEmpty {
                    Text("\(pending.count)")
                        .font(.system(size: 14, weight: .black))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }

            VStack(spacing: 16) {
                if pending.isEmpty {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle().fill(Color.green.opacity(0.12)).frame(width: 56, height: 56)
                            Image(systemName: "checkmark.seal.fill").font(.title2).foregroundColor(.green)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Operational Excellence")
                                .font(.system(size: 18, weight: .bold))
                            Text("All boutique tasks are currently finalized.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(32)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                } else {
                    ForEach(pending.prefix(2)) { task in
                        let staffName = tasksVM.staff.first(where: { $0.id == task.assignedTo })?.name
                        TaskRowView(task: task, onToggle: {
                            Task { await tasksVM.cycleTaskStatus(task) }
                        }, staffName: staffName)
                        .padding(28)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
                    }
                }
            }
        }
    }

    private func fmt(_ v: Double) -> String {
        if v >= 100_000 { return String(format: "%.1fL", v / 100_000) }
        if v >= 1_000   { return String(format: "%.1fK", v / 1_000) }
        return String(format: "%.0f", v)
    }
}

// MARK: - Dashboard Components

struct DashMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ZStack {
                    Circle().fill(iconColor.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(iconColor)
                }
                Spacer()
                Text(title)
                    .font(.custom("Helvetica", size: 10))
                    .fontWeight(.black)
                    .tracking(1.2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.custom("Helvetica", size: 32))
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }
}

struct StaffPerfRow: View {
    let entry: StaffPerformanceEntry
    let rank: Int
    let teamTotal: Double

    private var pct: Double { teamTotal > 0 ? entry.totalSales / teamTotal : 0 }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.75, blue: 0.0)
        case 2: return Color(white: 0.65)
        case 3: return Color(red: 0.72, green: 0.45, blue: 0.2)
        default: return .secondary
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 64, height: 64)
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                    Text(rank <= 3 ? (rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉")) : "#\(rank)")
                        .font(.custom("Helvetica", size: 24))
                        .fontWeight(.bold)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.name)
                        .font(.custom("Helvetica", size: 20))
                        .fontWeight(.bold)
                    Text("\(entry.totalOrders) Transactions · Avg Basket ₹\(Int(entry.avgOrderValue))")
                        .font(.custom("Helvetica", size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("₹\(Int(entry.totalSales).formatted())")
                        .font(.custom("Helvetica", size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(rank <= 3 ? rankColor : .primary)
                    Text("\(Int(pct * 100))% Portfolio")
                        .font(.custom("Helvetica", size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.tertiarySystemGroupedBackground)).frame(height: 10)
                    Capsule().fill(rank <= 3 ? rankColor : Color.accentColor)
                        .frame(width: max(0, geo.size.width * pct), height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(28)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

struct AllStaffPerformanceView: View {
    let entries: [StaffPerformanceEntry]
    let teamTotal: Double

    var body: some View {
        List {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                StaffPerfRow(entry: entry, rank: index + 1, teamTotal: teamTotal)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }
        }
        .listStyle(.insetGrouped)
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Specialist Analytics")
    }
}
