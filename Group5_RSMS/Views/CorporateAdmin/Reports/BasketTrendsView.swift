//
//  BasketTrendsView.swift
//  Group5_RSMS
//
//  Corporate Admin — Basket Size Trends chart with store/category filters.
//  Uses Swift Charts for visualization.
//

import SwiftUI
import Charts

struct BasketTrendsView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = BasketTrendsViewModel()
    @State private var showAllBasketRows = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if viewModel.isLoading && viewModel.activeTrendData.isEmpty {
                // First-load spinner — show before any data arrives
                loadingView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: RSMSTheme.Spacing.lg) {
                        if viewModel.activeTrendData.isEmpty {
                            filtersSection
                            inlineEmptyState
                        } else {
                            ViewThatFits {
                                HStack(alignment: .top, spacing: RSMSTheme.Spacing.lg) {
                                    filtersSection.frame(maxWidth: .infinity)
                                    summaryCards.frame(maxWidth: .infinity)
                                }
                                VStack(spacing: RSMSTheme.Spacing.lg) {
                                    filtersSection
                                    summaryCards
                                }
                            }
                            chartSection
                            trendTable
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                    .padding(.bottom, 100)
                    .frame(maxWidth: 1000)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Basket Trends")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
        .task { await viewModel.fetchTrends() }
    }

    // MARK: - Loading
    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ProgressView().tint(RSMSTheme.Colors.accentGold).scaleEffect(1.2)
            Text("Analyzing transactions...")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    // MARK: - Empty
    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.3))
            Text("No Transaction Data")
                .font(.title3).fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text("Transaction data will appear here once sales are recorded.")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, RSMSTheme.Spacing.xxl)
    }

    /// Inline placeholder shown below filters when selected store/category has no data.
    private var inlineEmptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: "basket")
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.25))
            Text("No Basket Data")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text("No transactions found for the selected store or category.\nTry switching the store or selecting a different category.")
                .font(.system(size: 13))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSTheme.Spacing.xxxl)
        .padding(.horizontal, RSMSTheme.Spacing.xl)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            metricCard(
                title: "Avg Basket",
                value: String(format: "%.1f", viewModel.overallAvgBasket),
                subtitle: "items/txn",
                icon: "basket.fill",
                color: RSMSTheme.Colors.accentGold
            )
            metricCard(
                title: "Avg Value",
                value: "₹\(String(format: "%.0f", viewModel.overallAvgValue))",
                subtitle: "per txn",
                icon: "indianrupeesign.circle.fill",
                color: RSMSTheme.Colors.accentGold
            )
            metricCard(
                title: "Total Txns",
                value: "\(viewModel.totalTransactions)",
                subtitle: "recorded",
                icon: "receipt.fill",
                color: RSMSTheme.Colors.accentGold
            )
        }
    }

    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Consolidated Filters

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            // Row 1: Store dropdown
            storeDropdown

            // Row 2: Category filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    filterChip(label: "All Categories", isSelected: viewModel.selectedCategory == nil) {
                        viewModel.selectedCategory = nil
                        Task { await viewModel.fetchTrends() }
                    }
                    ForEach(viewModel.categories, id: \.self) { cat in
                        filterChip(label: cat, isSelected: viewModel.selectedCategory == cat) {
                            viewModel.selectedCategory = cat
                            Task { await viewModel.fetchTrends() }
                        }
                    }
                }
            }


        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Store Dropdown

    private var storeDropdown: some View {
        let isFiltered = viewModel.selectedStoreId != nil
        let selectedName: String = {
            guard let id = viewModel.selectedStoreId else { return "All Stores" }
            return appState.stores.first(where: { $0.id == id })?.name ?? "All Stores"
        }()

        return Menu {
            Button {
                viewModel.selectedStoreId = nil
                Task { await viewModel.fetchTrends() }
            } label: {
                HStack {
                    Text("All Stores")
                    if viewModel.selectedStoreId == nil { Image(systemName: "checkmark") }
                }
            }

            if !appState.stores.isEmpty { Divider() }

            ForEach(appState.stores) { store in
                Button {
                    viewModel.selectedStoreId = store.id
                    Task { await viewModel.fetchTrends() }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.name)
                            Text(store.city).font(.caption)
                        }
                        if viewModel.selectedStoreId == store.id { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(isFiltered ? Color.black : RSMSTheme.Colors.accentGold)

                VStack(alignment: .leading, spacing: 1) {
                    Text("STORE")
                        .font(.system(size: 9, weight: .semibold)).tracking(0.8)
                        .foregroundStyle(isFiltered ? Color.black.opacity(0.6) : RSMSTheme.Colors.textTertiary)
                    Text(selectedName)
                        .font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        .foregroundStyle(isFiltered ? Color.black : RSMSTheme.Colors.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isFiltered ? Color.black.opacity(0.6) : RSMSTheme.Colors.textSecondary)
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .padding(.vertical, RSMSTheme.Spacing.md)
            .background(isFiltered ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(isFiltered ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isSelected ? .black : RSMSTheme.Colors.textSecondary)
                .background(isSelected ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1)
                )
        }
    }

    // MARK: - Chart

    private var basketPeriodDropdown: some View {
        Menu {
            ForEach(BasketTrendsViewModel.Period.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectedPeriod = period }
                } label: {
                    HStack {
                        Text(period.rawValue)
                        if viewModel.selectedPeriod == period { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedPeriod.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(RSMSTheme.Colors.accentGold)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RSMSTheme.Colors.accentGold.opacity(0.12))
            .cornerRadius(12)
        }
    }
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Text("Avg Items per Transaction")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                basketPeriodDropdown
            }

            Chart {
                ForEach(viewModel.activeTrendData) { point in
                    AreaMark(
                        x: .value("Period", point.label),
                        y: .value("Avg Basket", point.avgBasketSize)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [RSMSTheme.Colors.accentGold.opacity(0.3), RSMSTheme.Colors.accentGold.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)

                    LineMark(
                        x: .value("Period", point.label),
                        y: .value("Avg Basket", point.avgBasketSize)
                    )
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.monotone)

                    PointMark(
                        x: .value("Period", point.label),
                        y: .value("Avg Basket", point.avgBasketSize)
                    )
                    .foregroundStyle(trendColor(point.trend))
                    .symbolSize(40)
                }
            }
            .chartYScale(domain: .automatic(includesZero: true))
            .chartYAxisLabel("Items")
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 9))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(RSMSTheme.Colors.borderLight)
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
            .frame(height: 220)
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }

    // MARK: - Trend Table
    private var trendTable: some View {
        let data = viewModel.activeTrendData
        let visibleData = showAllBasketRows ? data : Array(data.prefix(5))

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Period")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Avg Items")
                    .frame(width: 70, alignment: .trailing)
                Text("Avg ₹")
                    .frame(width: 70, alignment: .trailing)
                Text("Txns")
                    .frame(width: 45, alignment: .trailing)
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(RSMSTheme.Colors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RSMSTheme.Colors.backgroundElevated)

            // Rows
            ForEach(Array(visibleData.enumerated()), id: \.element.id) { index, point in
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: trendIcon(point.trend))
                                .font(.system(size: 10))
                                .foregroundStyle(trendColor(point.trend))
                            Text(point.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "%.1f", point.avgBasketSize))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(trendColor(point.trend))
                            .frame(width: 70, alignment: .trailing)

                        Text("₹\(String(format: "%.0f", point.avgTransactionValue))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .frame(width: 70, alignment: .trailing)

                        Text("\(point.transactionCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            .frame(width: 45, alignment: .trailing)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if index < visibleData.count - 1 {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 14)
                    }
                }
            }

            // See More / See Less
            if data.count > 5 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showAllBasketRows.toggle() }
//                     withAnimation(.easeInOut(duration: 0.25)) {
//                         showAllBasketRows.toggle()
//                     }
                } label: {
                    HStack {
                        Spacer()
                        Text(showAllBasketRows ? "Show Less" : "See More (\(data.count - 5) more)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        Image(systemName: showAllBasketRows ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    private func trendColor(_ trend: BasketTrendsViewModel.Trend) -> Color {
        switch trend {
        case .up: return RSMSTheme.Colors.success
        case .down: return RSMSTheme.Colors.error
        case .flat: return RSMSTheme.Colors.textSecondary
        }
    }

    private func trendIcon(_ trend: BasketTrendsViewModel.Trend) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
}

#Preview {
    NavigationStack {
        BasketTrendsView()
            .environment(AppState())
    }
}
