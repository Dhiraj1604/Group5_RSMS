//
//  BMDashboardTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Dashboard overview tab.
//

import SwiftUI

struct BMDashboardTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var tasksVM = BMTasksViewModel()
    @StateObject private var dashboardVM = BMDashboardViewModel()
    
    @State private var showingAddTask = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Daily Pacing Dashboard
                        dailyPacingSection
                        
                        // MARK: - Staff Performance
                        staffPerformanceSection

                        // MARK: - Pending Store Operations
                        tasksSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            appState.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
            }
            .task {
                if let boutiqueId = appState.currentStoreID {
                    await dashboardVM.loadDailyPacing(boutiqueId: boutiqueId)
                    await dashboardVM.loadStaffPerformance(boutiqueId: boutiqueId)
                    await tasksVM.fetchTasksAndStaff(boutiqueId: boutiqueId)
                }
            }
            .onChange(of: appState.currentStoreID) { _, newId in
                guard let boutiqueId = newId else { return }
                Task {
                    await dashboardVM.loadDailyPacing(boutiqueId: boutiqueId)
                    await dashboardVM.loadStaffPerformance(boutiqueId: boutiqueId)
                    await tasksVM.fetchTasksAndStaff(boutiqueId: boutiqueId)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                if let boutiqueId = appState.currentStoreID {
                    AddTaskSheet(
                        boutiqueId: boutiqueId,
                        staff: tasksVM.staff,
                        onSave: { newTask in
                            Task {
                                await tasksVM.addTask(newTask)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var dailyPacingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Pacing")
                .font(RSMSTheme.Typography.heading3)
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            
            HStack(spacing: 20) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(RSMSTheme.Colors.surfacePrimary, lineWidth: 16)
                    
                    Circle()
                        .trim(from: 0, to: dashboardVM.progress)
                        .stroke(RSMSTheme.Colors.accentGold, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.0), value: dashboardVM.progress)
                    
                    VStack {
                        Text("\(Int(dashboardVM.progress * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        Text("to target")
                            .font(RSMSTheme.Typography.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }
                .frame(width: 140, height: 140)
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actual Sales")
                            .font(RSMSTheme.Typography.bodyCopy2)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        Text(dashboardVM.actualSales, format: .currency(code: "INR"))
                            .font(RSMSTheme.Typography.heading3)
                            .foregroundColor(RSMSTheme.Colors.success)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Target")
                            .font(RSMSTheme.Typography.bodyCopy2)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        Text(dashboardVM.dailyTarget, format: .currency(code: "INR"))
                            .font(RSMSTheme.Typography.heading4)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(RSMSTheme.Colors.backgroundElevated)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Staff Performance Section
    private var staffPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Staff Performance")
                    .font(RSMSTheme.Typography.heading3)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                Text("\(dashboardVM.staffPerformance.count) members")
                    .font(RSMSTheme.Typography.bodyCopy2)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .cornerRadius(8)
            }

            // Team Summary Row
            HStack(spacing: 10) {
                TeamMetricCard(title: "Team Sales", value: "₹\(formatNumber(dashboardVM.teamTotalSales))", icon: "indianrupeesign.circle.fill")
                TeamMetricCard(title: "This Month", value: "₹\(formatNumber(dashboardVM.teamThisMonthSales))", icon: "calendar.circle.fill")
                TeamMetricCard(title: "Orders", value: "\(dashboardVM.teamTotalOrders)", icon: "bag.circle.fill")
            }

            if dashboardVM.isLoadingStaff {
                ProgressView()
                    .tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if dashboardVM.staffPerformance.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3")
                        .font(.system(size: 40))
                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.5))
                    Text("No sales data available yet.")
                        .font(RSMSTheme.Typography.bodyCopy1)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(RSMSTheme.Colors.backgroundElevated)
                .cornerRadius(16)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(dashboardVM.staffPerformance.enumerated()), id: \.element.id) { index, entry in
                        StaffPerformanceRow(entry: entry, rank: index + 1, teamTotal: dashboardVM.teamTotalSales)
                    }
                }
            }
        }
    }
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Pending Store Operations")
                    .font(RSMSTheme.Typography.heading3)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                Text("\(tasksVM.tasks.filter { !$0.isCompleted }.count) left")
                    .font(RSMSTheme.Typography.bodyCopy2)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .cornerRadius(8)
            }
            
            if tasksVM.isLoading && tasksVM.tasks.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if tasksVM.tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 48))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    Text("No pending operations.")
                        .font(RSMSTheme.Typography.bodyCopy1)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(RSMSTheme.Colors.backgroundElevated)
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(tasksVM.tasks) { task in
                        let staffName = tasksVM.staff.first(where: { $0.id == task.assignedTo })?.name
                        TaskRowView(task: task, onToggle: {
                            Task { await tasksVM.toggleTaskCompletion(task) }
                        }, staffName: staffName)
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func formatNumber(_ value: Double) -> String {
        if value >= 100_000 {
            return String(format: "%.1fL", value / 100_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}

// MARK: - Team Metric Card
struct TeamMetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(RSMSTheme.Colors.accentGold)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Staff Performance Row
struct StaffPerformanceRow: View {
    let entry: StaffPerformanceEntry
    let rank: Int
    let teamTotal: Double

    private var contribution: Double {
        guard teamTotal > 0 else { return 0 }
        return entry.totalSales / teamTotal
    }

    private var rankBadgeColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return RSMSTheme.Colors.textSecondary
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankBadgeColor.opacity(rank <= 3 ? 0.2 : 0.1))
                        .frame(width: 36, height: 36)
                    if rank <= 3 {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14))
                            .foregroundColor(rankBadgeColor)
                    } else {
                        Text("#\(rank)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }

                // Name & Orders
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                        .lineLimit(1)
                    Text("\(entry.totalOrders) orders · Avg ₹\(String(format: "%.0f", entry.avgOrderValue))")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Sales Amount
                VStack(alignment: .trailing, spacing: 2) {
                    Text("₹\(String(format: "%.0f", entry.totalSales))")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                    Text("\(Int(contribution * 100))% of team")
                        .font(.caption2)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Sales contribution bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(RSMSTheme.Colors.surfacePrimary)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(RSMSTheme.Colors.accentGold)
                        .frame(width: geo.size.width * contribution, height: 3)
                        .animation(.easeOut(duration: 0.6), value: contribution)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    BMDashboardTab()
        .environment(AppState())
}
