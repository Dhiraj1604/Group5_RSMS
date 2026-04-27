//
//  VIPClientListView.swift
//  Group5_RSMS
//

import SwiftUI

struct VIPClientListView: View {
    @ObservedObject var viewModel: VIPEventsViewModel
    @ObservedObject var tasksVM: BMTasksViewModel
    @State private var searchText = ""
    
    var filteredClients: [VIPClient] {
        if searchText.isEmpty {
            return viewModel.vipClients
        } else {
            return viewModel.vipClients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    TextField("Search VIP clients...", text: $searchText)
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                }
                .padding(12)
                .background(RSMSTheme.Colors.surfacePrimary)
                .cornerRadius(10)
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                
                // VIP List
                LazyVStack(spacing: 14) {
                    ForEach(filteredClients) { client in
                        NavigationLink(destination: VIPClientDetailView(client: client, viewModel: viewModel, tasksVM: tasksVM)) {
                            VIPClientRow(client: client)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.bottom, 20)
            }
        }
    }
}

struct VIPClientRow: View {
    let client: VIPClient
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(String(client.name.prefix(1)))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(client.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    
                    if client.tier == "Platinum" {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
                
                Text("Last Visit: \(client.lastVisit.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                
                if let milestone = client.upcomingMilestone {
                    HStack(spacing: 4) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 10))
                        Text(milestone)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(RSMSTheme.Colors.backgroundPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.Colors.accentGold)
                    .clipShape(Capsule())
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.textTertiary)
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}
