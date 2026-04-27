//
//  AllStorePerformanceView.swift
//  Group5_RSMS
//
//  Created by Corporate Admin
//

import SwiftUI

struct AllStorePerformanceView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var searchText = ""
    @State private var filterActive: Bool? = nil
    @State private var sortOption: SortOption = .revenue

    enum SortOption: String, CaseIterable {
        case revenue = "Revenue"
        case orders = "Orders"
        case inventory = "Inventory"
        case name = "Name"
    }

    private var filteredAndSortedStores: [DashboardViewModel.StoreKPI] {
        var result = viewModel.storeKPIs

        if let active = filterActive {
            result = result.filter { $0.isActive == active }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.storeName.localizedCaseInsensitiveContains(searchText) ||
                $0.storeCity.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .revenue:
            result.sort { $0.revenue > $1.revenue }
        case .orders:
            result.sort { $0.orderCount > $1.orderCount }
        case .inventory:
            result.sort { $0.inventoryUnits > $1.inventoryUnits }
        case .name:
            result.sort { $0.storeName < $1.storeName }
        }

        return result
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Filters
                VStack(spacing: RSMSTheme.Spacing.md) {
                    HStack {
                        filterChips
                        Spacer()
                        sortMenu
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.vertical, RSMSTheme.Spacing.sm)
                    
                    Divider().background(RSMSTheme.Colors.borderLight)
                }

                if filteredAndSortedStores.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 20)], spacing: 24) {
                            ForEach(Array(filteredAndSortedStores.enumerated()), id: \.element.id) { index, storeKPI in
                                PremiumStoreCard(storeKPI: storeKPI, viewModel: viewModel, rank: (sortOption == .revenue && filterActive == nil && searchText.isEmpty) ? index + 1 : nil)
                            }
                        }
                        .padding(RSMSTheme.Spacing.horizontalMargin)
                        .padding(.top, RSMSTheme.Spacing.md)
                        .padding(.bottom, 120)
                    }
                }
            }
        }
        .navigationTitle("All Stores Performance")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search stores...")
    }

    // MARK: - Components

    private var filterChips: some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            filterChip(label: "All", isSelected: filterActive == nil) { filterActive = nil }
            filterChip(label: "Active", isSelected: filterActive == true) { filterActive = true }
            filterChip(label: "Inactive", isSelected: filterActive == false) { filterActive = false }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .black : RSMSTheme.Colors.textSecondary)
                .padding(.horizontal, RSMSTheme.Spacing.md)
                .padding(.vertical, 6)
                .background(isSelected ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button { sortOption = option } label: {
                    HStack {
                        Text(option.rawValue)
                        if sortOption == option { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text(sortOption.rawValue)
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(RSMSTheme.Colors.accentGold)
            .padding(.horizontal, RSMSTheme.Spacing.md)
            .padding(.vertical, 6)
            .background(RSMSTheme.Colors.accentGold.opacity(0.15))
            .clipShape(Capsule())
        }
    }

    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No stores found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text("Try adjusting your search or filters.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Premium Store Card

struct PremiumStoreCard: View {
    let storeKPI: DashboardViewModel.StoreKPI
    let viewModel: DashboardViewModel
    var rank: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Hero Area (Square-ish)
            ZStack(alignment: .topLeading) {
                // Rank Watermark (Background)
                if let rank = rank {
                    Text("\(rank)")
                        .font(.custom("HelveticaNeue-Bold", size: 82))
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.1))
                        .padding(10)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    Text(storeKPI.storeName)
                        .font(.custom("HelveticaNeue-Bold", size: 26))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    
                    Text(storeKPI.storeCity.uppercased())
                        .font(.custom("HelveticaNeue-Bold", size: 13))
                        .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.9))
                        .tracking(2)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(RSMSTheme.Colors.backgroundDeep)
            
            // 2. Metrics Area
            VStack(alignment: .leading, spacing: 14) {
                // Revenue Hero
                VStack(alignment: .leading, spacing: 0) {
                    Text(viewModel.shortRevenue(storeKPI.revenue))
                        .font(.custom("HelveticaNeue-Bold", size: 38))
                        .foregroundStyle(.white)
                    Text("REVENUE")
                        .font(.custom("HelveticaNeue-Bold", size: 12))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        .tracking(1)
                }
                
                // Operational Stats
                HStack(spacing: 0) {
                    miniStat(label: "ORDERS", value: "\(storeKPI.orderCount)")
                    Divider().frame(height: 20).background(RSMSTheme.Colors.borderLight).padding(.horizontal, 10)
                    miniStat(label: "STOCK", value: "\(storeKPI.inventoryUnits)")
                    Divider().frame(height: 20).background(RSMSTheme.Colors.borderLight).padding(.horizontal, 10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STATUS")
                            .font(.custom("HelveticaNeue-Bold", size: 10))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        
                        Text(storeKPI.isActive ? "ACTIVE" : "INACTIVE")
                            .font(.custom("HelveticaNeue-Bold", size: 11))
                            .foregroundStyle(storeKPI.isActive ? RSMSTheme.Colors.success : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(storeKPI.isActive ? RSMSTheme.Colors.success.opacity(0.1) : Color.red.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(storeKPI.isActive ? RSMSTheme.Colors.success.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1))
                    }
                }
            }
            .padding(20)
            .background(RSMSTheme.Colors.backgroundDeep.opacity(0.5))
        }
        .frame(height: 280)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [RSMSTheme.Colors.accentGold.opacity(0.5), .clear, RSMSTheme.Colors.accentGold.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 10, y: 6)
    }
    
    private func miniStat(label: String, value: String, color: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("HelveticaNeue-Bold", size: 10))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text(value)
                .font(.custom("HelveticaNeue-Bold", size: 18))
                .foregroundStyle(color)
        }
    }
    
    private func minimalMetric(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.6))
                Text(label)
                    .font(.custom("HelveticaNeue-Bold", size: 10))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .tracking(1)
            }
            Text(value)
                .font(.custom("HelveticaNeue-Bold", size: 21))
                .foregroundStyle(.white)
        }
    }
    
    private func metricChip(value: String, label: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(value)
                .font(.custom("HelveticaNeue-Bold", size: 16))
                .foregroundStyle(.white)
            Text(label)
                .font(.custom("HelveticaNeue-Bold", size: 7))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                .tracking(1)
        }
        .frame(width: 45)
    }

    private func metricPill(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.8))
                Text(title.uppercased())
                    .font(.custom("HelveticaNeue-Bold", size: 8))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .tracking(1)
            }
            Text(value)
                .font(.custom("HelveticaNeue-Bold", size: 20))
                .foregroundStyle(.white)
        }
    }

    }

