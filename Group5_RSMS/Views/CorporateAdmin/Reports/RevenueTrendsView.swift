//
import SwiftUI
import Charts
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

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if viewModel.isLoading && viewModel.activeTrendData.isEmpty {
                loadingView
            } else if viewModel.activeTrendData.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: RSMSTheme.Spacing.lg) {
                        // Filters on top
                        dateRangeBar
                        storeDropdown
                        comparisonToggle
                        // Then summary and period picker
                        summaryCards
                        periodPicker
                        chartSection
                        revenueTable
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Revenue Trends")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showExportOptions = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .actionSheet(isPresented: $showExportOptions) {
            ActionSheet(
                title: Text("Export Revenue Data"),
                buttons: [
                    .default(Text("CSV")) {
                        if let url = viewModel.csvFileURL() {
                            exportURL = url
                            showExportSheet = true
                        }
                    },
                    .default(Text("Excel")) {
                        if let url = viewModel.excelFileURL() {
                            exportURL = url
                            showExportSheet = true
                        }
                    },
                    .cancel()
                ]
            )
        }
        .task { await viewModel.fetchRevenue() }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
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
                        color: RSMSTheme.Colors.textTertiary
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
                    color: .blue
                )
                metricCard(
                    title: "Avg Order",
                    value: formatCurrency(viewModel.avgOrderValue),
                    subtitle: "per transaction",
                    icon: "basket.fill",
                    color: RSMSTheme.Colors.success
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

                // Custom date range button
                Button { showDatePicker = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dateRangeLabel)
                            .font(.system(size: 11, weight: .medium))
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

    // MARK: - Period Picker

    private var periodPicker: some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            ForEach(RevenueTrendsViewModel.Period.allCases, id: \.self) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectedPeriod = period }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .foregroundStyle(viewModel.selectedPeriod == period
                                         ? .black : RSMSTheme.Colors.textSecondary)
                        .background(viewModel.selectedPeriod == period
                                    ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.selectedPeriod == period
                                    ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1))
                }
            }
            Spacer()
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Text("Revenue Over Time")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                if viewModel.showComparison {
                    HStack(spacing: RSMSTheme.Spacing.md) {
                        legendDot(color: RSMSTheme.Colors.accentGold, label: "Current")
                        legendDot(color: RSMSTheme.Colors.textTertiary, label: "Previous")
                    }
                }
            }

            Chart {
                // Current period
                ForEach(viewModel.activeTrendData) { point in
                    AreaMark(x: .value("Period", point.label),
                             y: .value("Revenue", point.revenue))
                    .foregroundStyle(LinearGradient(
                        colors: [RSMSTheme.Colors.accentGold.opacity(0.3),
                                 RSMSTheme.Colors.accentGold.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)

                    LineMark(x: .value("Period", point.label),
                             y: .value("Revenue", point.revenue))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(x: .value("Period", point.label),
                              y: .value("Revenue", point.revenue))
                    .foregroundStyle(trendColor(point.trend))
                    .symbolSize(40)
                }

                // Previous period (comparison overlay)
                if viewModel.showComparison {
                    ForEach(Array(viewModel.prevTrendData.prefix(viewModel.activeTrendData.count).enumerated()),
                            id: \.offset) { index, point in
                        if index < viewModel.activeTrendData.count {
                            let matchLabel = viewModel.activeTrendData[index].label
                            LineMark(x: .value("Period", matchLabel),
                                     y: .value("Prev Revenue", point.revenue))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                }
            }
            .chartYAxisLabel("₹")
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel().font(.system(size: 9)).foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(RSMSTheme.Colors.borderLight)
                    AxisValueLabel().font(.system(size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
            }
            .frame(height: 240)
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 9)).foregroundStyle(RSMSTheme.Colors.textTertiary)
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

    // MARK: - Comparison Toggle

    private var comparisonToggle: some View {
        HStack {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 13))
                .foregroundStyle(RSMSTheme.Colors.accentGold)
            VStack(alignment: .leading, spacing: 1) {
                Text("Compare with Previous Period")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("Overlay the previous \(viewModel.rangeDays)-day period on the chart")
                    .font(.system(size: 10))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
            Spacer()
            Toggle("", isOn: $viewModel.showComparison)
                .tint(RSMSTheme.Colors.accentGold)
                .labelsHidden()
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Revenue Table

    private var revenueTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Period").frame(maxWidth: .infinity, alignment: .leading)
                Text("Revenue").frame(width: 80, alignment: .trailing)
                Text("Orders").frame(width: 55, alignment: .trailing)
                Text("AOV").frame(width: 65, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(RSMSTheme.Colors.textTertiary)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(RSMSTheme.Colors.backgroundElevated)

            // Rows
            ForEach(Array(viewModel.activeTrendData.enumerated()), id: \.element.id) { index, point in
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

                    if index < viewModel.activeTrendData.count - 1 {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 14)
                    }
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: RSMSTheme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                        Text("START DATE")
                            .font(.system(size: 11, weight: .semibold)).tracking(1)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(RSMSTheme.Colors.accentGold)
                            .colorScheme(.dark)
                    }

                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                        Text("END DATE")
                            .font(.system(size: 11, weight: .semibold)).tracking(1)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        DatePicker("", selection: $viewModel.endDate,
                                   in: viewModel.startDate..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(RSMSTheme.Colors.accentGold)
                            .colorScheme(.dark)
                    }

                    Spacer()

                    Button {
                        showDatePicker = false
                        Task { await viewModel.fetchRevenue() }
                    } label: {
                        Text("Apply Date Range")
                    }
                    .buttonStyle(GoldButtonStyle())
                }
                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                .padding(.top, RSMSTheme.Spacing.xl)
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showDatePicker = false }
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
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

// MARK: - Share Sheet (UIKit bridge for CSV export)

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack { RevenueTrendsView().environment(AppState()) }
}
