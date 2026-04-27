//
//  VIPClientDetailView.swift
//  Group5_RSMS
//

import SwiftUI

struct VIPClientDetailView: View {
    let client: VIPClient
    @ObservedObject var viewModel: VIPEventsViewModel
    @ObservedObject var tasksVM: BMTasksViewModel
    
    @State private var showingRequestSheet = false
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    statsSection
                    preferencesSection
                    purchasesSection
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Log Request") {
                    showingRequestSheet = true
                }
                .fontWeight(.bold)
                .foregroundColor(RSMSTheme.Colors.accentGold)
            }
        }
        .sheet(isPresented: $showingRequestSheet) {
            VIPRequestSheet(client: client, tasksVM: tasksVM)
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 80, height: 80)
                Text(String(client.name.prefix(1)))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            
            VStack(spacing: 4) {
                Text(client.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(client.email)
                    .font(.system(size: 14))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Text(client.phone)
                    .font(.system(size: 14))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            
            if let milestone = client.upcomingMilestone {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                    Text("Upcoming: \(milestone)")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 13))
                .foregroundColor(RSMSTheme.Colors.backgroundPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RSMSTheme.Colors.accentGold)
                .clipShape(Capsule())
                .padding(.top, 8)
            }
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(title: "Lifetime Spend", value: client.totalSpend.formatted(.currency(code: "INR")))
            statCard(title: "Tier", value: client.tier)
        }
        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
    }
    
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                ForEach(client.preferences, id: \.self) { pref in
                    Text(pref)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.Colors.surfacePrimary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var purchasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Purchases")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            
            let clientPurchases = viewModel.purchases[client.id] ?? []
            if clientPurchases.isEmpty {
                Text("No purchases found.")
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            } else {
                ForEach(clientPurchases) { purchase in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(purchase.itemName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            Text("SKU: \(purchase.sku)")
                                .font(.system(size: 12))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(purchase.price.formatted(.currency(code: "INR")))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            Text(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 12))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(RSMSTheme.Colors.backgroundElevated)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                    )
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                }
            }
        }
    }
}
