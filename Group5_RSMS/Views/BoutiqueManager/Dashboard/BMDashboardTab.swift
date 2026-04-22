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
                    await tasksVM.fetchTasksAndStaff(boutiqueId: boutiqueId)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                if let boutiqueId = appState.currentStoreID {
                    AddTaskSheet(boutiqueId: boutiqueId, staff: tasksVM.staff) { newTask in
                        Task {
                            await tasksVM.addTask(newTask)
                        }
                    }
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
                        Text(dashboardVM.actualSales, format: .currency(code: "USD"))
                            .font(RSMSTheme.Typography.heading3)
                            .foregroundColor(RSMSTheme.Colors.success)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Target")
                            .font(RSMSTheme.Typography.bodyCopy2)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        Text(dashboardVM.dailyTarget, format: .currency(code: "USD"))
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
}

#Preview {
    BMDashboardTab()
        .environment(AppState())
}
