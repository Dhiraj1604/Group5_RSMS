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
            result.sort { $0.achievementPercentage > $1.achievementPercentage }
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
        ScrollView {
            VStack(spacing: RSMSTheme.Spacing.lg) {
                // Custom Large Title
                HStack {
                    Text("All Stores Performance")
                        .font(.custom("Helvetica-Bold", size: 34))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.top, 20)
                
                // Filter Chips at top of scroll
                HStack {
                    filterChips
                    Spacer()
                }
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.top, RSMSTheme.Spacing.md)
                
                if filteredAndSortedStores.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 20)], spacing: 24) {
                        ForEach(Array(filteredAndSortedStores.enumerated()), id: \.element.id) { index, storeKPI in
                            PremiumStoreCard(storeKPI: storeKPI, viewModel: viewModel, rank: (filterActive == nil && searchText.isEmpty) ? index + 1 : nil)
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.bottom, 120)
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("")
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
        ZStack(alignment: .topLeading) {
            // Base Background
            RSMSTheme.Colors.backgroundDeep
            
            // Subtle Radial Glow
            RadialGradient(
                gradient: Gradient(colors: [RSMSTheme.Colors.accentGold.opacity(0.15), .clear]),
                center: .topTrailing,
                startRadius: 0,
                endRadius: 250
            )
            
            // Original Top-Left Rank Watermark
            if let rank = rank {
                Text("\(rank)")
                    .font(.custom("HelveticaNeue-Bold", size: 82))
                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .padding(10)
                    .allowsHitTesting(false)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                // Top Right: Status Badge
                HStack {
                    Spacer()
                    // Ultra-Minimal Status Dot (Only)
                    StatusDot(isActive: storeKPI.isActive)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Store Name & City
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeKPI.storeName)
                        .font(.custom("HelveticaNeue-Bold", size: 24))
                        .foregroundStyle(RSMSTheme.Colors.accentGoldLight)
                        .lineLimit(1)
                    Text(storeKPI.storeCity.uppercased())
                        .font(.custom("HelveticaNeue-Medium", size: 11))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        .tracking(1.5)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Progress Bar & Metrics Section
                VStack(spacing: 28) {
                    // Custom Premium Progress Bar
                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(RSMSTheme.Colors.accentGold)
                                .frame(width: barGeo.size.width * min(storeKPI.achievementPercentage / 100.0, 1.0), height: 6)
                                .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.3), radius: 4, x: 0, y: 0)
                        }
                    }
                    .frame(height: 6)
                    
                    // Aligned Metrics Below Progress Bar
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("% TO TARGET")
                                .font(.custom("HelveticaNeue-Bold", size: 10))
                                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.8))
                                .tracking(1)
                            
                            Text(String(format: "%.0f%%", storeKPI.achievementPercentage))
                                .font(.custom("HelveticaNeue-Bold", size: 22))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("TOTAL REVENUE")
                                .font(.custom("HelveticaNeue-Bold", size: 10))
                                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.8))
                                .tracking(1)
                            
                            Text(viewModel.localizedShortRevenue(storeKPI.revenue, currencyCode: storeKPI.currencyCode))
                                 .font(.custom("HelveticaNeue-Bold", size: 22))
                                 .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 12, y: 8)
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

