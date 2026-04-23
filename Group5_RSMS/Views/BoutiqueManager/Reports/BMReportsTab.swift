//
//  BMReportsTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Reports tab placeholder.
//

import SwiftUI

import Charts

struct BMReportsTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var viewModel = BMInventoryViewModel()
    
    private var currentStore: Store? {
        guard let storeId = appState.currentStoreID else { return nil }
        return appState.stores.first(where: { $0.id == storeId })
    }

    private var currentStoreName: String {
        currentStore?.name ?? "My Boutique"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Boutique Performance")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            Text("Comprehensive analytics and sales trends for \(currentStoreName).")
                                .font(.system(size: 14))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        .padding(.top, RSMSTheme.Spacing.md)

                        if let error = viewModel.insightsError {
                            errorState(error)
                        }

                        // Sales & Fallback Cards
                        HStack(spacing: 16) {
                            NavigationLink(destination: SoldProductsListView(products: viewModel.soldProducts)) {
                                insightCard(
                                    title: "Total Sale",
                                    value: "\(viewModel.soldProducts.reduce(0, { $0 + $1.quantitySold }))",
                                    subtitle: "This Month",
                                    icon: "cart.fill",
                                    color: RSMSTheme.Colors.accentGold
                                )
                            }

                            NavigationLink(destination: FallbackItemsListView(items: viewModel.fallbackItems)) {
                                insightCard(
                                    title: "Dormant",
                                    value: "\(viewModel.fallbackItems.count)",
                                    subtitle: "> 30 Days",
                                    icon: "exclamationmark.arrow.triangle.2.circlepath",
                                    color: RSMSTheme.Colors.error
                                )
                            }
                        }
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)

                        // Weekly Trend Chart
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Weekly Sales")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                    Text("Revenue trend over last 7 days")
                                        .font(.system(size: 12))
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                }
                                Spacer()
                                
                                let total = viewModel.weeklySalesData.reduce(0, { $0 + $1.amount })
                                Text(String(format: "$%.2f", total))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                            }

                            if viewModel.weeklySalesData.isEmpty {
                                chartPlaceholder
                            } else {
                                salesChart
                            }
                        }
                        .padding(20)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        
                        Spacer(minLength: 40)
                    }
                }
                .refreshable {
                    if let storeId = appState.currentStoreID {
                        await viewModel.loadMerchandisingInsights(forStore: storeId)
                    }
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            if let storeId = appState.currentStoreID {
                await viewModel.loadMerchandisingInsights(forStore: storeId)
            }
        }
    }

    // MARK: - Helper Views

    private func insightCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    private var salesChart: some View {
        Chart {
            ForEach(viewModel.weeklySalesData) { data in
                BarMark(
                    x: .value("Day", data.dayName),
                    y: .value("Sales", data.amount)
                )
                .foregroundStyle(RSMSTheme.Colors.goldGradient)
                .cornerRadius(4)
                
                AreaMark(
                    x: .value("Day", data.dayName),
                    y: .value("Sales", data.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [RSMSTheme.Colors.accentGold.opacity(0.1), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: 180)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic) { value in
                AxisValueLabel()
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .font(.system(size: 10, weight: .medium))
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.05))
            }
        }
    }

    private var chartPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.3))
            Text("No sales data available for this week")
                .font(.system(size: 13))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Spacer()
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(RSMSTheme.Colors.error)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(RSMSTheme.Colors.error.opacity(0.05))
        .cornerRadius(16)
    }
}


#Preview { BMReportsTab() }
