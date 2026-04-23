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
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: RSMSTheme.Spacing.lg)], spacing: RSMSTheme.Spacing.lg) {
                            ForEach(Array(filteredAndSortedStores.enumerated()), id: \.element.id) { index, storeKPI in
                                PremiumStoreCard(storeKPI: storeKPI, viewModel: viewModel, rank: (sortOption == .revenue && filterActive == nil && searchText.isEmpty) ? index + 1 : nil)
                            }
                        }
                        .padding(RSMSTheme.Spacing.horizontalMargin)
                        .padding(.top, RSMSTheme.Spacing.md)
                        .padding(.bottom, RSMSTheme.Spacing.xxl)
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
        let isTop3 = (rank ?? 4) <= 3
        
        VStack(alignment: .leading, spacing: 0) {
            // Header with Rank Badge
            HStack(alignment: .center) {
                if let rank = rank {
                    ZStack {
                        Circle()
                            .fill(rank == 1 ? RSMSTheme.Colors.accentGold : (rank == 2 ? Color.gray : Color.brown.opacity(0.8)))
                            .frame(width: 40, height: 40)
                            .shadow(color: (rank == 1 ? RSMSTheme.Colors.accentGold : .clear).opacity(0.4), radius: 8)
                        
                        Text("\(rank)")
                            .font(.custom("Helvetica-Bold", size: 18))
                            .foregroundStyle(.black)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(storeKPI.storeName)
                        .font(.custom("Helvetica-Bold", size: 20))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                        Text(storeKPI.storeCity)
                            .font(.custom("Helvetica-Bold", size: 12))
                    }
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .padding(.leading, 10)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(storeKPI.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
                            .frame(width: 6, height: 6)
                        Text(storeKPI.isActive ? "ONLINE" : "OFFLINE")
                            .font(.custom("Helvetica-Bold", size: 9))
                            .foregroundStyle(storeKPI.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RSMSTheme.Colors.backgroundPrimary.opacity(0.4))
                    .clipShape(Capsule())
                }
            }
            .padding(.bottom, 24)

            // Revenue Section
            VStack(alignment: .leading, spacing: 6) {
                Text("TOTAL REVENUE")
                    .font(.custom("Helvetica-Bold", size: 11))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .kerning(1.2)
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(viewModel.shortRevenue(storeKPI.revenue))
                        .font(.custom("Helvetica-Bold", size: 42))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                        Text("12%")
                    }
                    .font(.custom("Helvetica-Bold", size: 12))
                    .foregroundStyle(RSMSTheme.Colors.success)
                }
            }
            .padding(.bottom, 24)

            Divider().background(RSMSTheme.Colors.borderLight.opacity(0.4))
                .padding(.bottom, 20)

            // Sub-metrics Grid
            HStack(spacing: 24) {
                metricPill(title: "Orders", value: "\(storeKPI.orderCount)", icon: "bag.fill", color: .blue)
                metricPill(title: "SKU", value: "\(storeKPI.inventoryUnits)", icon: "shippingbox.fill", color: .purple)
                metricPill(title: "Staff", value: "8", icon: "person.2.fill", color: .orange)
            }
        }
        .padding(28)
        .background(
            ZStack {
                RSMSTheme.Colors.backgroundDeep
                if isTop3 {
                    LinearGradient(
                        colors: [RSMSTheme.Colors.accentGold.opacity(0.12), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(isTop3 ? RSMSTheme.Colors.accentGold.opacity(0.3) : RSMSTheme.Colors.borderLight, lineWidth: isTop3 ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 15, x: 0, y: 8)
    }

    private func metricPill(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(color)
                Text(title)
                    .font(.custom("Helvetica-Bold", size: 10))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.custom("Helvetica-Bold", size: 20))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    }

