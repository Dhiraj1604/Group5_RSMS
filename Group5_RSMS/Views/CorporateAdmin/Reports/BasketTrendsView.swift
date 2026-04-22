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

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: RSMSTheme.Spacing.lg) {
                    // Filters always on top
                    filterSection
                    // Summary cards, period picker
                    summaryCards
                    periodPicker
                    chartSection
                    // Content area based on state
                    if viewModel.isLoading && viewModel.activeTrendData.isEmpty {
                        loadingView
                    } else if viewModel.activeTrendData.isEmpty {
                        emptyState
                    } else {
                        trendTable
                    }
                }
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.top, RSMSTheme.Spacing.md)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Basket Trends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
                color: RSMSTheme.Colors.success
            )
            metricCard(
                title: "Total Txns",
                value: "\(viewModel.totalTransactions)",
                subtitle: "recorded",
                icon: "receipt.fill",
                color: .blue
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

    // MARK: - Period Picker
    private var periodPicker: some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            ForEach(BasketTrendsViewModel.Period.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .foregroundStyle(viewModel.selectedPeriod == period ? .black : RSMSTheme.Colors.textSecondary)
                        .background(viewModel.selectedPeriod == period
                            ? RSMSTheme.Colors.accentGold
                            : RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(viewModel.selectedPeriod == period
                                    ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1)
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - Chart
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Avg Items per Transaction")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)

            Chart {
                ForEach(viewModel.activeTrendData) { point in
                    // Area fill
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
                    .interpolationMethod(.catmullRom)

                    // Line
                    LineMark(
                        x: .value("Period", point.label),
                        y: .value("Avg Basket", point.avgBasketSize)
                    )
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    // Data points
                    PointMark(
                        x: .value("Period", point.label),
                        y: .value("Avg Basket", point.avgBasketSize)
                    )
                    .foregroundStyle(trendColor(point.trend))
                    .symbolSize(40)
                }
            }
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

    // MARK: - Filters
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
            Text("FILTERS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(RSMSTheme.Colors.accentGold)

            // Store filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    filterChip(label: "All Stores", isSelected: viewModel.selectedStoreId == nil) {
                        viewModel.selectedStoreId = nil
                        Task { await viewModel.fetchTrends() }
                    }
                    ForEach(appState.stores) { store in
                        filterChip(label: store.name, isSelected: viewModel.selectedStoreId == store.id) {
                            viewModel.selectedStoreId = store.id
                            Task { await viewModel.fetchTrends() }
                        }
                    }
                }
            }

            // Category filter
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

    // MARK: - Trend Table
    private var trendTable: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(RSMSTheme.Colors.textTertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RSMSTheme.Colors.backgroundElevated)

            // Rows
            ForEach(Array(viewModel.activeTrendData.enumerated()), id: \.element.id) { index, point in
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

                    if index < viewModel.activeTrendData.count - 1 {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 14)
                    }
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
