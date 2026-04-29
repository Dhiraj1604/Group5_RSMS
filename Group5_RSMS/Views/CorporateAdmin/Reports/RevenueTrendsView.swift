//
//  RevenueTrendsView.swift
//  Group5_RSMS
//
//  Corporate Admin — Revenue Trends report.
//  Trend line chart (daily/weekly/monthly), date range picker,
//  current-vs-previous period comparison, store filter dropdown,
//  and CSV export.
//

import SwiftUI
import Charts

struct RevenueTrendsView: View {
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = RevenueTrendsViewModel()

    @State private var showDatePicker = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showExportOptions = false
    @State private var showAllRevenueRows = false

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
                            revenueTable
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
        .navigationTitle("Revenue Trends")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if let csvURL = viewModel.csvFileURL() {
                        ShareLink(item: csvURL) {
                            Label("Export as CSV", systemImage: "tablecells")
                        }
                    }
                    if let xlsURL = viewModel.excelFileURL() {
                        ShareLink(item: xlsURL) {
                            Label("Export as Excel", systemImage: "doc.text")
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .task { await viewModel.fetchRevenue() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ProgressView().tint(RSMSTheme.Colors.accentGold).scaleEffect(1.2)
            Text("Loading revenue data…")
                .font(.subheadline).foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.3))
            Text("No Revenue Data")
                .font(.title3).fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text("Revenue data will appear here once sales transactions are recorded.")
                .font(.subheadline).foregroundStyle(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, RSMSTheme.Spacing.xxl)
    }

    /// Inline placeholder shown below filters when selected store has no data.
    private var inlineEmptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.25))
            Text("No Revenue Data")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text("No transactions found for the selected store and date range.\nTry selecting a different store or adjusting the date range.")
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
        VStack(spacing: RSMSTheme.Spacing.sm) {
            // Top row — Revenue + Growth
            HStack(spacing: RSMSTheme.Spacing.sm) {
                metricCard(
                    title: "Total Revenue",
                    value: formatCurrency(viewModel.totalRevenue),
                    subtitle: "\(viewModel.rangeDays)-day period",
                    icon: "indianrupeesign.circle.fill",
                    color: RSMSTheme.Colors.accentGold
                )

                if let growth = viewModel.revenueGrowthPercent {
                    metricCard(
                        title: "Growth",
                        value: "\(growth >= 0 ? "+" : "")\(String(format: "%.1f", growth))%",
                        subtitle: "vs previous period",
                        icon: growth >= 0 ? "arrow.up.right" : "arrow.down.right",
                        color: growth >= 0 ? RSMSTheme.Colors.success : RSMSTheme.Colors.error
                    )
                } else {
                    metricCard(
                        title: "Growth",
                        value: "—",
                        subtitle: "no prior data",
                        icon: "arrow.left.arrow.right",
                        color: RSMSTheme.Colors.accentGold
                    )
                }
            }

            // Bottom row — Transactions + AOV
            HStack(spacing: RSMSTheme.Spacing.sm) {
                metricCard(
                    title: "Transactions",
                    value: "\(viewModel.totalTransactions)",
                    subtitle: "total orders",
                    icon: "receipt.fill",
                    color: RSMSTheme.Colors.accentGold
                )
                metricCard(
                    title: "Avg Order",
                    value: formatCurrency(viewModel.avgOrderValue),
                    subtitle: "per transaction",
                    icon: "basket.fill",
                    color: RSMSTheme.Colors.accentGold
                )
            }
        }
    }

    private func metricCard(title: String, value: String, subtitle: String,
                             icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(subtitle).font(.system(size: 9)).foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
            .stroke(color.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Date Range Bar

    private var dateRangeBar: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
            // Quick range buttons
            HStack(spacing: RSMSTheme.Spacing.sm) {
                ForEach(RevenueTrendsViewModel.QuickRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.applyQuickRange(range)
                        }
                        Task { await viewModel.fetchRevenue() }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .foregroundStyle(isQuickRangeActive(range)
                                             ? .black : RSMSTheme.Colors.textSecondary)
                            .background(isQuickRangeActive(range)
                                        ? RSMSTheme.Colors.accentGold
                                        : RSMSTheme.Colors.backgroundElevated)
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(isQuickRangeActive(range)
                                        ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1))
                    }
                }

                Spacer()

                // Custom date range toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDatePicker.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dateRangeLabel)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.Colors.accentGold.opacity(0.3), lineWidth: 0.5))
                }
            }
        }
    }

    private var dateRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return "\(f.string(from: viewModel.startDate)) – \(f.string(from: viewModel.endDate))"
    }

    private func isQuickRangeActive(_ range: RevenueTrendsViewModel.QuickRange) -> Bool {
        let expected = Calendar.current.date(byAdding: .day, value: -range.days, to: Date())!
        let diff = abs(viewModel.startDate.timeIntervalSince(expected))
        return diff < 86400 // within 1 day tolerance
    }

    // MARK: - Consolidated Filters

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            // Row 1: Store dropdown
            storeDropdown

            // Row 2: Date range quick buttons + custom date
            dateRangeBar

            // Inline date pickers (expandable)
            if showDatePicker {
                inlineDatePickers
            }

        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Chart

    /// Warm copper/rose color for previous-period — matches the dark/gold theme
    private let previousPeriodColor = Color(red: 0.76, green: 0.48, blue: 0.36)

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            chartHeader
            revenueChart
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    private var chartHeader: some View {
        VStack(spacing: RSMSTheme.Spacing.sm) {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                Text("Revenue Over Time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()

                // Compare toggle
                HStack(spacing: 6) {
                    Text("Compare")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Toggle("", isOn: $viewModel.showComparison)
                        .tint(RSMSTheme.Colors.accentGold)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }

                periodDropdown
            }
            if viewModel.showComparison {
                HStack {
                    Spacer()
                    HStack(spacing: RSMSTheme.Spacing.lg) {
                        legendItem(color: RSMSTheme.Colors.accentGold, label: "Current Period", dashed: false)
                        legendItem(color: previousPeriodColor, label: "Previous Period", dashed: true)
                    }
                }
            }
        }
    }

    private var periodDropdown: some View {
        Menu {
            ForEach(RevenueTrendsViewModel.Period.allCases, id: \.self) { period in
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

    private var revenueChart: some View {
        Chart {
            // Current period
            ForEach(viewModel.activeTrendData) { point in
                AreaMark(
                    x: .value("Period", point.label),
                    y: .value("Revenue", point.revenue)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            RSMSTheme.Colors.accentGold.opacity(0.3),
                            RSMSTheme.Colors.accentGold.opacity(0.02)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("Period", point.label),
                    y: .value("Revenue", point.revenue)
                )
                .foregroundStyle(by: .value("Type", "Current Period"))
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Period", point.label),
                    y: .value("Revenue", point.revenue)
                )
                .foregroundStyle(trendColor(point.trend))
                .symbolSize(40)
            }

            // Previous period overlay
            if viewModel.showComparison {
                ForEach(
                    Array(
                        viewModel.prevTrendData
                            .prefix(viewModel.activeTrendData.count)
                            .enumerated()
                    ),
                    id: \.offset
                ) { index, point in
                    if index < viewModel.activeTrendData.count {
                        LineMark(
                            x: .value("Period", viewModel.activeTrendData[index].label),
                            y: .value("Revenue", point.revenue)
                        )
                        .foregroundStyle(by: .value("Type", "Previous Period"))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .interpolationMethod(.monotone)

                        PointMark(
                            x: .value("Period", viewModel.activeTrendData[index].label),
                            y: .value("Revenue", point.revenue)
                        )
                        .foregroundStyle(previousPeriodColor.opacity(0.8))
                        .symbolSize(24)
                    }
                }
            }
        }
        .chartForegroundStyleScale([
            "Current Period": RSMSTheme.Colors.accentGold,
            "Previous Period": previousPeriodColor
        ])
        .chartLegend(.hidden)
        .chartYScale(domain: .automatic(includesZero: true))
        .chartYAxisLabel("₹")
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
        .frame(height: 240)
    }

    /// Legend item showing a line sample + label
    private func legendItem(color: Color, label: String, dashed: Bool) -> some View {
        HStack(spacing: 5) {
            // Line sample
            ZStack {
                if dashed {
                    Line()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                        .foregroundStyle(color)
                        .frame(width: 16, height: 2)
                } else {
                    Rectangle()
                        .fill(color)
                        .frame(width: 16, height: 2)
                        .cornerRadius(1)
                }
            }
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
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
                Task { await viewModel.fetchRevenue() }
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
                    Task { await viewModel.fetchRevenue() }
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

    // (comparisonToggle moved inline into filtersSection)

    // MARK: - Revenue Table

    private var revenueTable: some View {
        let data = viewModel.activeTrendData
        let visibleData = showAllRevenueRows ? data : Array(data.prefix(5))

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Period").frame(maxWidth: .infinity, alignment: .leading)
                Text("Revenue").frame(width: 80, alignment: .trailing)
                Text("Orders").frame(width: 55, alignment: .trailing)
                Text("AOV").frame(width: 65, alignment: .trailing)
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(RSMSTheme.Colors.textSecondary)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RSMSTheme.Colors.backgroundElevated)

            // Rows
            ForEach(Array(visibleData.enumerated()), id: \.element.id) { index, point in
                VStack(spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: trendIcon(point.trend))
                                .font(.system(size: 10)).foregroundStyle(trendColor(point.trend))
                            Text(point.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(formatCurrencyShort(point.revenue))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(trendColor(point.trend))
                            .frame(width: 80, alignment: .trailing)

                        Text("\(point.transactionCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            .frame(width: 55, alignment: .trailing)

                        Text(formatCurrencyShort(point.avgOrderValue))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            .frame(width: 65, alignment: .trailing)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)

                    if index < visibleData.count - 1 {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 14)
                    }
                }
            }

            // See More / See Less
            if data.count > 5 {
                Button {
//                     withAnimation(.easeInOut(duration: 0.25)) { showAllRevenueRows.toggle() }
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAllRevenueRows.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(showAllRevenueRows ? "Show Less" : "See More (\(data.count - 5) more)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        Image(systemName: showAllRevenueRows ? "chevron.up" : "chevron.down")
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
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Inline Date Pickers

    private var inlineDatePickers: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            HStack(spacing: RSMSTheme.Spacing.md) {
                // Start date
                VStack(alignment: .leading, spacing: 4) {
                    Text("FROM")
                        .font(.system(size: 9, weight: .bold)).tracking(1)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(RSMSTheme.Colors.accentGold)
                        .colorScheme(.dark)
                        .labelsHidden()
                }

                // End date (max 30 days from start)
                VStack(alignment: .leading, spacing: 4) {
                    Text("TO (max 30 days)")
                        .font(.system(size: 9, weight: .bold)).tracking(1)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    let maxEnd = Calendar.current.date(byAdding: .day, value: 30, to: viewModel.startDate) ?? viewModel.startDate
                    DatePicker("", selection: $viewModel.endDate,
                               in: viewModel.startDate...maxEnd, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(RSMSTheme.Colors.accentGold)
                        .colorScheme(.dark)
                        .labelsHidden()
                }

                Spacer()

                // Apply button
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showDatePicker = false
                    }
                    Task { await viewModel.fetchRevenue() }
                } label: {
                    Text("Apply")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(RSMSTheme.Colors.accentGold)
                        .cornerRadius(16)
                }
            }
        }
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(RSMSTheme.Radius.md)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Helpers

    private func trendColor(_ trend: RevenueTrendsViewModel.Trend) -> Color {
        switch trend {
        case .up:   return RSMSTheme.Colors.success
        case .down: return RSMSTheme.Colors.error
        case .flat: return RSMSTheme.Colors.textSecondary
        }
    }

    private func trendIcon(_ trend: RevenueTrendsViewModel.Trend) -> String {
        switch trend {
        case .up:   return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100_000 {
            return "₹\(String(format: "%.1f", value / 100_000))L"
        } else if value >= 1_000 {
            return "₹\(String(format: "%.1f", value / 1_000))K"
        }
        return "₹\(String(format: "%.0f", value))"
    }

    private func formatCurrencyShort(_ value: Double) -> String {
        if value >= 100_000 {
            return "₹\(String(format: "%.1f", value / 100_000))L"
        } else if value >= 1_000 {
            return "₹\(String(format: "%.0f", value / 1_000))K"
        }
        return "₹\(String(format: "%.0f", value))"
    }
}


// MARK: - Line Shape (for legend dashed line indicator)

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { RevenueTrendsView().environment(AppState()) }
}
