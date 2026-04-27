//
//  BMVIPEventsTab.swift
//  Group5_RSMS
//

import SwiftUI

struct BMVIPEventsTab: View {
    @StateObject private var viewModel = VIPEventsViewModel()
    @State private var selectedTabSegment = 0 // 0 = VIP Clients, 1 = Events Calendar
    
    // Pass this down if we want to log requests that create tasks
    @StateObject private var tasksVM = BMTasksViewModel()
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Segmented Picker
                    Picker("VIP & Events", selection: $selectedTabSegment) {
                        Text("VIP Clients").tag(0)
                        Text("Events Calendar").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.vertical, RSMSTheme.Spacing.md)
                    
                    if selectedTabSegment == 0 {
                        VIPClientListView(viewModel: viewModel, tasksVM: tasksVM)
                    } else {
                        EventsCalendarView(viewModel: viewModel)
                    }
                }
            }
            .navigationTitle(selectedTabSegment == 0 ? "VIP Clients" : "Events Calendar")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                if let id = appState.currentStoreID {
                    await tasksVM.fetchTasksAndStaff(boutiqueId: id)
                }
            }
        }
    }
}

#Preview {
    BMVIPEventsTab()
        .environment(AppState())
}
