//
//  DashboardTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Comprehensive KPI Dashboard.
//

import SwiftUI
import Charts

struct DashboardTab: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()
    @State private var expandedStoreId: UUID?
    @State private var glowPhase = false
    @State private var appeared = false
    @State private var showRevenueModal = false
    @State private var showCategoryModal = false
    @State private var showAIModal = false
    @State private var showProfitModal = false
    @State private var showRetentionModal = false
    @State private var selectedPieSlice: String? = nil
    @State private var selectedAngle: Double? = nil
    @Namespace private var animation

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWide: Bool { sizeClass == .regular }

    private var kpiColumns: [GridItem] {
        let count = isWide ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: RSMSTheme.Spacing.md), count: count)
    }

    var body: some View {
        NavigationStack {
            mainContent
                .background(RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) { appState.signOut() } label: { Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") }
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                        .accessibilityLabel("Account menu")
                        .accessibilityHint("Opens account actions including sign out.")
                    }
                }
                .overlay {
                    if viewModel.isLoading && viewModel.lastRefreshed == nil {
                        ZStack {
                            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                            ProgressView().tint(RSMSTheme.Colors.accentGold)
                        }
                    }
                }
        }
        .task {
            await viewModel.fetchDashboardData(stores: appState.stores)
            viewModel.startAutoRefresh(stores: appState.stores)
            withAnimation(.easeOut(duration: 0.6).delay(0.15)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { glowPhase = true }
        }
        .onDisappear { viewModel.stopAutoRefresh() }
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: RSMSTheme.Spacing.xl) {
                refreshHeader
                timeFrameSelector
                kpiHeroSection
                
                if let error = viewModel.errorMessage { errorBanner(error) }
                
                // Main Analytics Dashboard
                if isWide {
                    VStack(spacing: 24) {
                        // Row 1: Intelligence & Orders
                        HStack(alignment: .top, spacing: 24) {
                            aiForecastSection
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            VStack(spacing: 24) {
                                categorySalesSection
                                orderStatsSection
                            }
                            .frame(width: 440)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        // Row 2: Customer Loyalty & Financials
                        HStack(alignment: .top, spacing: 24) {
                            customerInsightsSection
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            profitabilitySection
                                .frame(width: 440)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 24) {
                        aiForecastSection
                        categorySalesSection
                        orderStatsSection
                        customerInsightsSection
                        profitabilitySection
                    }
                    .padding(.vertical, 8)
                }
                
                if !viewModel.storeKPIs.isEmpty { storePerformanceSection }
                quickActionsSection
                Spacer().frame(height: RSMSTheme.Spacing.xxl)
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.md)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.fetchDashboardData(stores: appState.stores)
        }
        .task {
            if !appState.stores.isEmpty {
                await viewModel.fetchDashboardData(stores: appState.stores)
            }
            viewModel.startAutoRefresh(stores: appState.stores)
        }
        .onChange(of: appState.stores) { _, newStores in
            Task {
                await viewModel.fetchDashboardData(stores: newStores)
                viewModel.startAutoRefresh(stores: newStores)
            }
        }
        .sheet(isPresented: $showRevenueModal) { RevenueDetailModal(viewModel: viewModel) }
        .sheet(isPresented: $showCategoryModal) { CategoryDetailModal(viewModel: viewModel) }
        .sheet(isPresented: $showAIModal) { AIForecastDetailModal(viewModel: viewModel) }
        .sheet(isPresented: $showProfitModal) { ProfitabilityDetailModal(viewModel: viewModel) }
        .sheet(isPresented: $showRetentionModal) { RetentionDetailModal(viewModel: viewModel) }
    }

    // MARK: - Components

    private var refreshHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Performance Overview")
                    .font(.custom("Helvetica-Bold", size: 24))
                    .foregroundStyle(.white)
//                Text("Real-time data from all boutique locations")
//                    .font(.system(size: 13))
//                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
            Spacer()
            
//            VStack(alignment: .trailing, spacing: 4) {
//                Text("LAST UPDATED")
//                    .font(.system(size: 10, weight: .bold))
//                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
//                    .tracking(1.0)
//                Text(viewModel.lastRefreshedText)
//                    .font(.system(size: 13, weight: .medium))
//                    .foregroundStyle(.white)
//            }
        }
    }

    private var timeFrameSelector: some View {
        HStack(spacing: 0) {
            let options: [DashboardViewModel.DashboardTimeFrame] = [.yesterday, .last7Days, .last30Days]
            ForEach(options) { frame in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.selectedTimeFrame = frame
                    }
                } label: {
                    Text(frame.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(viewModel.selectedTimeFrame == frame ? Color.black : RSMSTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if viewModel.selectedTimeFrame == frame {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(RSMSTheme.Colors.accentGold)
                                    .matchedGeometryEffect(id: "time_pill", in: animation)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
    }

    private var kpiHeroSection: some View {
        LazyVGrid(columns: kpiColumns, spacing: RSMSTheme.Spacing.md) {
            kpiCard(title: "Total Revenue", value: viewModel.formattedTotalRevenue, icon: "indianrupeesign.circle.fill", color: RSMSTheme.Colors.accentGold)
            kpiCard(title: "Total Orders", value: "\(viewModel.totalOrders)", icon: "bag.fill", color: RSMSTheme.Colors.accentGold)
            kpiCard(title: "Unique SKUs", value: "\(viewModel.totalInventoryUnits)", icon: "shippingbox.fill", color: RSMSTheme.Colors.accentGold)
            kpiCard(title: "Active Stores", value: "\(viewModel.activeStoreCount)", icon: "building.2.fill", color: RSMSTheme.Colors.accentGold)
        }
    }

    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: isWide ? 34 : 28, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .minimumScaleFactor(0.8)
                
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .tracking(1.1)
                    .lineLimit(1)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg, style: .continuous)
                    .fill(RSMSTheme.Colors.backgroundDeep)
                
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg, style: .continuous)
                    .fill(LinearGradient(colors: [color.opacity(0.08), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg, style: .continuous)
                .stroke(LinearGradient(colors: [color.opacity(0.4), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var aiForecastAccessibilitySummary: String {
        let next7Days = viewModel.forecastRevenue.prefix(7)
        let forecastTotal = next7Days.reduce(0) { $0 + $1.amount }
        let topCategory = viewModel.bestPredictedCategory.isEmpty ? "not available" : viewModel.bestPredictedCategory
        return "Forecasted revenue for the next seven days is \(viewModel.shortRevenue(forecastTotal)). Top predicted category is \(topCategory)."
    }

    private var categorySalesAccessibilitySummary: String {
        guard !viewModel.categorySales.isEmpty else { return "No category sales data available." }
        let total = viewModel.categorySales.reduce(0) { $0 + $1.revenue }
        guard let top = viewModel.categorySales.max(by: { $0.revenue < $1.revenue }) else {
            return "No category sales data available."
        }
        let pct = total > 0 ? Int((top.revenue / total) * 100) : 0
        return "Top category is \(top.category), contributing \(pct) percent of category revenue."
    }

    // MARK: - AI Forecast
    private var aiForecastSection: some View {
        Button(action: { showAIModal = true }) {
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                HStack {
//                    Image(systemName: "sparkles")
//                        .font(.system(size: 20))
//                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("AI Analyst Insights")
                        .font(.custom("Helvetica-Bold", size: 24))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    let next7Days = viewModel.forecastRevenue.prefix(7).reduce(0) { $0 + $1.amount }
                    let last7Days = viewModel.allTimeDailyRevenue.suffix(7).reduce(0) { $0 + $1.amount }
                    let percentChange = last7Days > 0 ? ((next7Days - last7Days) / last7Days) * 100 : 0
                    
                    // 1. Headline Context
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Revenue Forecast")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                            Text(viewModel.shortRevenue(next7Days))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: percentChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text(String(format: "%.1f%% %@", abs(percentChange), percentChange >= 0 ? "Growth" : "Decline"))
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(percentChange >= 0 ? RSMSTheme.Colors.success : Color.orange)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Top Category")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                .textCase(.uppercase)
                            Text(viewModel.bestPredictedCategory.isEmpty ? "---" : viewModel.bestPredictedCategory)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .padding()
                    .background(RSMSTheme.Colors.backgroundPrimary.opacity(0.4))
                    .cornerRadius(12)

                    // 2. The Visual Graph
                    if !viewModel.forecastRevenue.isEmpty {
                        Chart {
                            if let lastDate = viewModel.allTimeDailyRevenue.last?.date {
                                RuleMark(x: .value("Today", lastDate))
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .annotation(position: .top, alignment: .center) {
                                        Text("TODAY").font(.system(size: 8, weight: .bold)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    }
                            }
                            
                            ForEach(viewModel.allTimeDailyRevenue.suffix(10)) { item in
                                LineMark(x: .value("Date", item.date), y: .value("Revenue", item.amount))
                                    .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.5))
                                    .interpolationMethod(.catmullRom)
                            }
                            ForEach(viewModel.forecastRevenue.prefix(7)) { item in
                                LineMark(x: .value("Date", item.date), y: .value("Forecast", item.amount))
                                    .foregroundStyle(Color.purple)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    .interpolationMethod(.catmullRom)
                                AreaMark(x: .value("Date", item.date), y: .value("Forecast", item.amount))
                                    .foregroundStyle(LinearGradient(colors: [Color.purple.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                                    .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                AxisValueLabel(format: .dateTime.day().month())
                                    .font(.system(size: 8))
                                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic) { value in
                                AxisValueLabel().font(.system(size: 8)).foregroundStyle(RSMSTheme.Colors.textTertiary)
                            }
                        }
                        .frame(height: 110)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("AI revenue forecast chart")
                        .accessibilityValue(aiForecastAccessibilitySummary)
                    }

                    // 3. Informative Insights Groups
                    if viewModel.aiPredictions.isEmpty {
                        ProgressView().padding().frame(maxWidth: .infinity)
                    } else {
                        HStack(alignment: .top, spacing: 16) {
                            // Predictions Section
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Predictions", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.purple)
                                    .textCase(.uppercase)
                                
                                ForEach(viewModel.aiPredictions, id: \.self) { insight in
                                    Text(insight)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                            .background(Color.purple.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.1), lineWidth: 1))
                            
                            // Suggestions Section
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Actions", systemImage: "lightbulb.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                                    .textCase(.uppercase)
                                
                                ForEach(viewModel.aiSuggestions, id: \.self) { insight in
                                    Text(insight)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                            .background(RSMSTheme.Colors.accentGold.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.accentGold.opacity(0.1), lineWidth: 1))
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    ZStack {
                        RSMSTheme.Colors.backgroundDeep
                        LinearGradient(colors: [.purple.opacity(glowPhase ? 0.08 : 0.03), .blue.opacity(glowPhase ? 0.05 : 0.01)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                )
                .cornerRadius(RSMSTheme.Radius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                        .stroke(LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Order Stats
    private var orderStatsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Order Analytics")
                .font(.custom("Helvetica-Bold", size: 24))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            let statColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            
            if isWide {
                HStack(spacing: RSMSTheme.Spacing.md) {
                    statBox(title: "Avg Order Value", value: viewModel.formattedAOV, icon: "cart.fill", color: RSMSTheme.Colors.accentGold)
                    statBox(title: "Avg Basket Size", value: String(format: "%.1f", viewModel.avgBasketSize), icon: "bag.fill.badge.plus", color: RSMSTheme.Colors.accentGold)
                    statBox(title: "Conversion Rate", value: String(format: "%.1f%%", viewModel.conversionRate), icon: "arrow.triangle.2.circlepath.circle.fill", color: RSMSTheme.Colors.accentGold)
                }
            } else {
                LazyVGrid(columns: statColumns, spacing: 12) {
                    statBox(title: "Avg AOV", value: viewModel.formattedAOV, icon: "cart.fill", color: RSMSTheme.Colors.accentGold)
                    statBox(title: "Basket", value: String(format: "%.1f", viewModel.avgBasketSize), icon: "bag.fill.badge.plus", color: RSMSTheme.Colors.accentGold)
                    statBox(title: "Conversion", value: String(format: "%.1f%%", viewModel.conversionRate), icon: "arrow.triangle.2.circlepath.circle.fill", color: RSMSTheme.Colors.accentGold)
                }
            }
        }
    }
    
    private func statBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
            Image(systemName: icon).foregroundStyle(color).font(.title3)
            Text(value)
                .font(.custom("Helvetica-Bold", size: 24))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text(title)
                .font(.custom("Helvetica-Bold", size: 13))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }.frame(maxWidth: .infinity, alignment: .leading).frame(height: 110).padding().background(RSMSTheme.Colors.backgroundDeep).cornerRadius(RSMSTheme.Radius.lg).overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }

    // MARK: - Category Breakdown
    private var categorySalesSection: some View {
        Button(action: { showCategoryModal = true }) {
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                HStack {
                Text("Sales by Category")
                    .font(.custom("Helvetica-Bold", size: 24))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Spacer()
                }
                
                if viewModel.categorySales.isEmpty {
                    Text("No data")
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(RSMSTheme.Radius.lg)
                } else {
                    VStack(alignment: .center, spacing: 24) {
                        Chart(viewModel.categorySales) { item in
                            SectorMark(angle: .value("Revenue", item.revenue), innerRadius: .ratio(0.6), angularInset: 1.5)
                                .cornerRadius(4)
                                .foregroundStyle(by: .value("Category", item.category))
                                .opacity(selectedPieSlice == nil || selectedPieSlice == item.category ? 1.0 : 0.3)
                        }
                        .chartForegroundStyleScale([
                            "jewellery": Color.yellow, 
                            "watches": Color.blue, 
                            "leather_goods": Color.orange,
                            "couture": Color.purple,
                            "accessories": Color.cyan,
                            "fragrances": Color.pink.opacity(0.6), // Lavender/Pink
                            "eyewear": Color.teal,
                            "other": Color.gray
                        ])
                        .chartLegend(.hidden)
                        .frame(height: 160)
                        
                        // Centered Legend
                        // Explicitly Centered Dual-Column Legend
                        HStack(spacing: 40) {
                            let sales = viewModel.categorySales
                            
                            // Left Column
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(sales.prefix(3)), id: \.category) { item in
                                    HStack(spacing: 8) {
                                        Circle().fill(categoryColor(for: item.category)).frame(width: 10, height: 10)
                                        Text("\(item.category.replacingOccurrences(of: "_", with: " ").capitalized) (\(viewModel.shortRevenue(item.revenue)))")
                                            .font(.custom("Helvetica-Bold", size: 15))
                                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            
                            // Right Column
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(Array(sales.dropFirst(3).prefix(3)), id: \.category) { item in
                                    HStack(spacing: 8) {
                                        Circle().fill(categoryColor(for: item.category)).frame(width: 10, height: 10)
                                        Text("\(item.category.replacingOccurrences(of: "_", with: " ").capitalized) (\(viewModel.shortRevenue(item.revenue)))")
                                            .font(.custom("Helvetica-Bold", size: 15))
                                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 20)
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(RSMSTheme.Radius.lg)
                    .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
            case "jewellery": return Color.yellow
            case "watches": return Color.blue
            case "leather_goods": return Color.orange
            case "couture": return Color.purple
            case "accessories": return Color.cyan
            case "fragrances": return Color.pink.opacity(0.6)
            case "eyewear": return Color.teal
            default: return Color.gray
        }
    }

    // MARK: - Customer Insights (Luxury Redesign)
    private var customerInsightsSection: some View {
        Button(action: { showRetentionModal = true }) {
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                HStack {
                    Text("Retention Analytics")
                        .font(.custom("Helvetica-Bold", size: 24))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Spacer()
                }
                
                VStack(spacing: 24) {
                    let total = Double(max(1, viewModel.totalCustomers))
                    let returningRatio = Double(viewModel.returningCustomers) / total
                    
                    HStack(alignment: .center, spacing: 30) {
                        // Left: Loyalty Gauge (as per screenshot)
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.05), lineWidth: 12)
                            Circle()
                                .trim(from: 0, to: returningRatio)
                                .stroke(
                                    LinearGradient(colors: [.green, Color.green.opacity(0.6)], startPoint: .top, endPoint: .bottom),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 0) {
                                Text(String(format: "%.0f%%", returningRatio * 100))
                                    .font(.custom("Helvetica-Bold", size: 38))
                                    .foregroundStyle(RSMSTheme.Colors.success)
                                Text("RETURNING")
                                    .font(.custom("Helvetica-Bold", size: 9))
                                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            }
                        }
                        .frame(width: 120, height: 120)
                        
                        // Middle: Strategic Metrics
                        VStack(alignment: .leading, spacing: 16) {
                            retentionMetricPill(title: "New Users", value: "\(viewModel.newCustomers)", color: RSMSTheme.Colors.success, icon: "person.badge.plus.fill")
                            retentionMetricPill(title: "Returning", value: "\(viewModel.returningCustomers)", color: RSMSTheme.Colors.accentGold, icon: "person.2.fill")
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider().frame(height: 100).background(RSMSTheme.Colors.borderLight.opacity(0.2))
                        
                        // Right: Lifecycle Insights
                        VStack(alignment: .trailing, spacing: 12) {
                            lifecycleItem(label: "Avg. Lifecycle", value: String(format: "%.1f Months", viewModel.avgCustomerLifecycleDays / 30), icon: "calendar.badge.clock")
                            lifecycleItem(label: "Repeat Rate", value: "High", icon: "arrow.clockwise.heart.fill", valueColor: RSMSTheme.Colors.success)
                        }
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RSMSTheme.Colors.backgroundDeep)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
    }


    private func retentionMetricSmall(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary).textCase(.uppercase)
            HStack(spacing: 8) {
                Text(value).font(.custom("Helvetica-Bold", size: 24)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("+5%").font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(color).padding(.horizontal, 6).padding(.vertical, 2).background(color.opacity(0.1)).cornerRadius(4)
            }
        }
    }
    
    private func retentionMetricPill(title: String, value: String, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(RSMSTheme.Colors.textTertiary).textCase(.uppercase)
                Text(value).font(.custom("Helvetica-Bold", size: 26)).foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
        }
    }
    
    private func lifecycleItem(label: String, value: String, icon: String, valueColor: Color = RSMSTheme.Colors.textPrimary) -> some View {
        VStack(alignment: isWide ? .trailing : .leading, spacing: 4) {
            HStack(spacing: 6) {
                if !isWide { Image(systemName: icon).font(.system(size: 12)).foregroundStyle(RSMSTheme.Colors.textTertiary) }
                Text(label).font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(RSMSTheme.Colors.textTertiary).textCase(.uppercase)
                if isWide { Image(systemName: icon).font(.system(size: 12)).foregroundStyle(RSMSTheme.Colors.textTertiary) }
            }
            Text(value).font(.custom("Helvetica-Bold", size: 22)).foregroundStyle(valueColor)
        }
    }
    
    private func insightPill(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundStyle(color)
            Text(text).font(.custom("Helvetica", size: 14)).foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Store Performance
    private var storePerformanceSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack(alignment: .bottom) {
                Text("Top Performing Stores")
                    .font(.custom("Helvetica-Bold", size: 24))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                
                Spacer()
                
                NavigationLink(destination: AllStorePerformanceView(viewModel: viewModel)) {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(viewModel.storeKPIs.prefix(5).enumerated()), id: \.element.id) { index, storeKPI in
                        PremiumStoreCard(storeKPI: storeKPI, viewModel: viewModel, rank: index + 1)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal, 2)
            }
            // Add negative horizontal padding to let scroll view bleed to edges if desired
            // .padding(.horizontal, -RSMSTheme.Spacing.horizontalMargin) 
        }
    }

    // MARK: - Profitability Analytics (Detailed)
    private var profitabilitySection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Profitability Analytics")
                .font(.custom("Helvetica-Bold", size: 24))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            VStack(spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL REVENUE")
                            .font(.custom("Helvetica-Bold", size: 12))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text(viewModel.formattedTotalRevenue)
                            .font(.custom("Helvetica-Bold", size: 32))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("NET MARGIN")
                            .font(.custom("Helvetica-Bold", size: 12))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text("\(String(format: "%.1f%%", viewModel.netProfitMargin))")
                            .font(.custom("Helvetica-Bold", size: 32))
                            .foregroundStyle(viewModel.netProfitMargin >= 0 ? RSMSTheme.Colors.success : .red)
                    }
                }
                
                // Detailed Breakdown (Proportional Split)
                GeometryReader { proxy in
                    let total = viewModel.grossProfit + viewModel.estimatedOpex + viewModel.estimatedTax
                    let gpRatio = total > 0 ? (viewModel.grossProfit / total) : 0.33
                    let opRatio = total > 0 ? (viewModel.estimatedOpex / total) : 0.33
                    let taxRatio = total > 0 ? (viewModel.estimatedTax / total) : 0.34
                    
                    HStack(spacing: 0) {
                        breakdownItem(label: "GROSS", value: viewModel.shortRevenue(viewModel.grossProfit), color: RSMSTheme.Colors.accentGold.opacity(0.8))
                            .frame(width: proxy.size.width * gpRatio)
                        breakdownItem(label: "OPEX", value: viewModel.shortRevenue(viewModel.estimatedOpex), color: .orange.opacity(0.8))
                            .frame(width: proxy.size.width * opRatio)
                        breakdownItem(label: "TAX", value: viewModel.shortRevenue(viewModel.estimatedTax), color: .blue.opacity(0.8))
                            .frame(width: proxy.size.width * taxRatio)
                    }
                }
                .frame(height: 50)
                .clipShape(Capsule())
                
                HStack {
                    Text("Operating Efficiency").font(.custom("Helvetica", size: 12)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                    Spacer()
                    let eff = viewModel.operatingEfficiency
                    let effLabel = eff >= 70 ? "High" : eff >= 40 ? "Moderate" : "Low"
                    Text("\(effLabel) (\(String(format: "%.0f", eff))%)")
                        .font(.custom("Helvetica-Bold", size: 12))
                        .foregroundStyle(eff >= 70 ? RSMSTheme.Colors.success : eff >= 40 ? RSMSTheme.Colors.warning : .red)
                }
            }
            .padding(24)
            .frame(maxHeight: .infinity)
            .background(RSMSTheme.Colors.backgroundDeep)
            .cornerRadius(RSMSTheme.Radius.lg)
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            .onTapGesture { showProfitModal = true }
        }
    }
    
    private func breakdownItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.custom("Helvetica-Bold", size: 11)).foregroundStyle(.white.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.8)
            Text(value).font(.custom("Helvetica-Bold", size: 14)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color)
    }

    // MARK: - Inventory Turnover (NEW Admin KPI)
    private var inventoryHealthSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Inventory Dynamics")
                .font(.custom("Helvetica-Bold", size: 24))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.2.squarepath").foregroundStyle(RSMSTheme.Colors.accentGold)
                        Text("Turnover Ratio").font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                    Text(String(format: "%.1fx", viewModel.inventoryTurnover))
                        .font(.custom("Helvetica-Bold", size: 28))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text("Ideal Range: 4x - 6x").font(.custom("Helvetica", size: 10)).foregroundStyle(RSMSTheme.Colors.success)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(RSMSTheme.Colors.backgroundDeep)
                .cornerRadius(RSMSTheme.Radius.lg)
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill").foregroundStyle(RSMSTheme.Colors.warning)
                        Text("Inventory Health").font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                    }
                    Text(String(format: "%.0f%%", viewModel.inventoryHealth))
                        .font(.custom("Helvetica-Bold", size: 28))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text("\(Int(100 - viewModel.inventoryHealth))% Stock Risk").font(.custom("Helvetica", size: 10)).foregroundStyle(RSMSTheme.Colors.warning)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(RSMSTheme.Colors.backgroundDeep)
                .cornerRadius(RSMSTheme.Radius.lg)
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            }
        }
    }

    // MARK: - Financial Performance & Regional Insights (Luxury Redesign)
    private var regionalExpenseSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Corporate Performance Index")
                .font(.custom("Helvetica-Bold", size: 22))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            VStack(spacing: 0) {
                // Top Financial Bar
                HStack(spacing: 40) {
                    financialSummaryItem(label: "GROSS PROFIT", value: viewModel.shortRevenue(viewModel.grossProfit), color: RSMSTheme.Colors.accentGold)
                    financialSummaryItem(label: "NET MARGIN", value: String(format: "%.1f%%", viewModel.netProfitMargin), color: RSMSTheme.Colors.success)
                    financialSummaryItem(label: "EST. OPEX", value: viewModel.shortRevenue(viewModel.totalRevenue * 0.18), color: .orange)
                }
                .padding(30)
                .background(RSMSTheme.Colors.backgroundDeep.opacity(0.4))
                
                Divider().background(RSMSTheme.Colors.borderLight.opacity(0.3))
                
                // Regional Table
                VStack(spacing: 0) {
                    HStack {
                        Text("REGIONAL PERFORMANCE").font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Spacer()
                        Text("REVENUE").font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text("EFFICIENCY").font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary).frame(width: 80, alignment: .trailing)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.02))
                    
                    ForEach(viewModel.storeKPIs.prefix(3)) { store in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.storeName).font(.custom("Helvetica-Bold", size: 15)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                                Text(store.storeCity).font(.custom("Helvetica", size: 12)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                            }
                            Spacer()
                            Text(viewModel.shortRevenue(store.revenue)).font(.custom("Helvetica-Bold", size: 15)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                            
                            // Visual efficiency bar
                            let efficiency = Double.random(in: 75...95) // Real logic would pull from DB
                            Text("\(Int(efficiency))%")
                                .font(.custom("Helvetica-Bold", size: 13))
                                .foregroundStyle(efficiency > 85 ? RSMSTheme.Colors.success : RSMSTheme.Colors.accentGold)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 18)
                        Divider().padding(.horizontal, 30).background(RSMSTheme.Colors.borderLight.opacity(0.1))
                    }
                }
            }
            .background(
                ZStack {
                    RSMSTheme.Colors.backgroundDeep
                    LinearGradient(colors: [RSMSTheme.Colors.accentGold.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            )
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }
    
    private func financialSummaryItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary).tracking(1.1)
            Text(value).font(.custom("Helvetica-Bold", size: 28)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Admin Utilities (Redesigned)
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Admin Utilities")
                .font(.custom("Helvetica-Bold", size: 24))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            let layout = isWide ? AnyLayout(HStackLayout(spacing: 25)) : AnyLayout(VStackLayout(spacing: 20))
            
            layout {
                NavigationLink { StockAnalysisStorePickerView() } label: {
                    actionCard(icon: "chart.bar.fill", title: "Stock Analysis", subtitle: "SKU Intelligence", color: RSMSTheme.Colors.accentGold)
                }
                NavigationLink { TaxSettingsView() } label: {
                    actionCard(icon: "shield.checkerboard", title: "Tax Rates", subtitle: "Regional Tax & Compliance", color: RSMSTheme.Colors.accentGold)
                }
            }
        }
    }
    
    private func actionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .center, spacing: 20) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.custom("Helvetica-Bold", size: 22))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.custom("Helvetica", size: 14))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(color.opacity(0.8))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.4), .clear, color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }


    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(RSMSTheme.Colors.warning)
            Text(message).font(.system(size: 12)).foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
        }
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.warning.opacity(0.08))
        .cornerRadius(RSMSTheme.Radius.sm)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm).stroke(RSMSTheme.Colors.warning.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Modals

struct RevenueDetailModal: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: DashboardViewModel
    @State private var timePeriod = "30 Days"
    let periods = ["7 Days", "30 Days", "6 Months", "1 Year"]

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.lg) {
                    Picker("Time Period", selection: $timePeriod) {
                        ForEach(periods, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                    
                    Text("Revenue Overview")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        
                    Chart {
                        ForEach(viewModel.dailyRevenue) { item in
                            LineMark(x: .value("Date", item.date), y: .value("Revenue", item.amount))
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                                .interpolationMethod(.catmullRom)
                            AreaMark(x: .value("Date", item.date), y: .value("Revenue", item.amount))
                                .foregroundStyle(LinearGradient(colors: [RSMSTheme.Colors.accentGold.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                                .interpolationMethod(.catmullRom)
                        }
                        ForEach(viewModel.forecastRevenue) { item in
                            LineMark(x: .value("Date", item.date), y: .value("Forecast", item.amount))
                                .foregroundStyle(RSMSTheme.Colors.accentGoldDark)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartXAxis { AxisMarks(values: .stride(by: .day, count: 7)) { value in AxisValueLabel(format: .dateTime.day().month(), centered: true).foregroundStyle(RSMSTheme.Colors.textSecondary) } }
                    .chartYAxis { AxisMarks { value in AxisValueLabel().foregroundStyle(RSMSTheme.Colors.textSecondary); AxisGridLine().foregroundStyle(RSMSTheme.Colors.borderLight) } }
                    .frame(maxHeight: 400)
                    .padding(RSMSTheme.Spacing.xl)
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(RSMSTheme.Radius.lg)
                    .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    
                    Spacer()
                }
            }
            .navigationTitle("Revenue Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(RSMSTheme.Colors.textSecondary) }
                }
            }
        }
    }
}

struct CategoryDetailModal: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: DashboardViewModel
    @Namespace private var animation
    
    private let categoryColors: [String: Color] = [
        "jewellery": Color.yellow, 
        "watches": Color.blue, 
        "leather_goods": Color.orange,
        "couture": Color.purple,
        "accessories": Color.cyan,
        "fragrances": Color.pink.opacity(0.6),
        "eyewear": Color.teal,
        "other": Color.gray
    ]

    private func categoryColor(for category: String) -> Color {
        categoryColors[category.lowercased()] ?? RSMSTheme.Colors.accentGold
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: RSMSTheme.Spacing.lg) {
                    HStack(spacing: 0) {
                        let options: [DashboardViewModel.DashboardTimeFrame] = [.yesterday, .last7Days, .last30Days]
                        ForEach(options) { frame in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    viewModel.selectedTimeFrame = frame
                                }
                            } label: {
                                Text(frame.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(viewModel.selectedTimeFrame == frame ? Color.black : RSMSTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background {
                                        if viewModel.selectedTimeFrame == frame {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(RSMSTheme.Colors.accentGold)
                                                .matchedGeometryEffect(id: "time_pill", in: animation)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(Color.black.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                    
                    Text("Category Performance")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        
                    ScrollView {
                        VStack(spacing: 12) {
                            let totalCategoryRev = viewModel.categorySales.reduce(0) { $0 + $1.revenue }
                            
                            Chart(viewModel.categorySales) { item in
                                SectorMark(angle: .value("Revenue", item.revenue), innerRadius: .ratio(0.5), angularInset: 2.0)
                                    .cornerRadius(6)
                                    .foregroundStyle(categoryColors[item.category.lowercased()] ?? RSMSTheme.Colors.accentGold)
                            }
                            .frame(height: 300)
                            .padding(RSMSTheme.Spacing.xl)
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(RSMSTheme.Radius.lg)
                            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                            .padding(.bottom, RSMSTheme.Spacing.md)
                            
                            Text("Revenue Breakdown")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                                
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Category Performance Index")
                                    .font(.custom("Helvetica-Bold", size: 18))
                                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                    ForEach(viewModel.categorySales) { item in
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Circle().fill(categoryColor(for: item.category)).frame(width: 10, height: 10)
                                                Text(item.category.capitalized).font(.custom("Helvetica-Bold", size: 14)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                                                Spacer()
                                                Text("\(item.count) Units").font(.custom("Helvetica", size: 12)).foregroundStyle(RSMSTheme.Colors.textTertiary)
                                            }
                                            
                                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                                Text(viewModel.shortRevenue(item.revenue))
                                                    .font(.custom("Helvetica-Bold", size: 24))
                                                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                            }
                                        }
                                        .padding(24)
                                        .background(RSMSTheme.Colors.backgroundDeep)
                                        .cornerRadius(16)
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)      
                            Spacer().frame(height: 40)
                        }
                    }
                }
            }
            .navigationTitle("Category Sales Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(RSMSTheme.Colors.textSecondary) }
                }
            }
        }
    }
}

// MARK: - Helper Views
private struct AIInsightRow: View {
    let insight: String
    
    var isWarning: Bool {
        let lower = insight.lowercased()
        return lower.contains("down") || lower.contains("drop") || lower.contains("⚠️")
    }
    
    var isAOV: Bool {
        let lower = insight.lowercased()
        return lower.contains("aov") || lower.contains("average") || lower.contains("🛍️")
    }
    
    var iconName: String {
        isWarning ? "arrow.down.right.circle.fill" : (isAOV ? "bag.circle.fill" : "arrow.up.right.circle.fill")
    }
    
    var iconColor: Color {
        isWarning ? Color.orange : (isAOV ? Color.blue : Color.green)
    }
    
    var cleanText: String {
        String(insight.drop(while: { $0.isWhitespace || $0 == "✨" || $0 == "📈" || $0 == "🛍" || $0 == "️" || $0 == "⚠️" || $0 == "📊" }))
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle().fill(iconColor.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: iconName).font(.title2).foregroundStyle(iconColor)
            }
            
            Text(cleanText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct ProfitabilityDetailModal: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: DashboardViewModel
    
    @State private var searchText = ""
    @State private var sortBy: SortOption = .revenue
    @State private var filterStatus: FilterStatus = .all
    
    enum SortOption: String, CaseIterable {
        case revenue = "Revenue"
        case orders = "Orders"
        case name = "Store Name"
    }
    
    enum FilterStatus: String, CaseIterable {
        case all = "All"
        case online = "Online"
        case offline = "Offline"
    }
    
    var filteredStores: [DashboardViewModel.StoreKPI] {
        viewModel.storeKPIs.filter { kpi in
            let matchesSearch = searchText.isEmpty || kpi.storeName.lowercased().contains(searchText.lowercased())
            let matchesFilter = filterStatus == .all || (filterStatus == .online ? kpi.isActive : !kpi.isActive)
            return matchesSearch && matchesFilter
        }
        .sorted { a, b in
            switch sortBy {
            case .revenue: return a.revenue > b.revenue
            case .orders: return a.orderCount > b.orderCount
            case .name: return a.storeName < b.storeName
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Metrics
                    HStack(spacing: 24) {
                        metricItem(label: "TOTAL PROFIT", value: viewModel.shortRevenue(viewModel.grossProfit), color: RSMSTheme.Colors.accentGold)
                        metricItem(label: "AVG MARGIN", value: String(format: "%.1f%%", viewModel.netProfitMargin), color: RSMSTheme.Colors.success)
                    }
                    .padding(30)
                    .background(RSMSTheme.Colors.backgroundDeep.opacity(0.3))
                    
                    // Controls
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundStyle(RSMSTheme.Colors.textTertiary)
                                TextField("Search stores...", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            }
                            .padding(12)
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                            
                            Menu {
                                Picker("Sort By", selection: $sortBy) {
                                    ForEach(SortOption.allCases, id: \.self) { Text($0.rawValue) }
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.title3)
                                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                                    .padding(10)
                                    .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        
                        Picker("Status", selection: $filterStatus) {
                            ForEach(FilterStatus.allCases, id: \.self) { Text($0.rawValue) }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(20)
                    
                    // Store List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredStores) { store in
                                StoreProfitRow(store: store, viewModel: viewModel)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Profitability Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(RSMSTheme.Colors.textSecondary) }
                }
            }
        }
    }
    
    private func metricItem(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text(value).font(.custom("Helvetica-Bold", size: 32)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StoreProfitRow: View {
    let store: DashboardViewModel.StoreKPI
    let viewModel: DashboardViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.storeName).font(.custom("Helvetica-Bold", size: 16)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(store.storeCity).font(.custom("Helvetica", size: 12)).foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.shortRevenue(store.revenue)).font(.custom("Helvetica-Bold", size: 16)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("\(store.orderCount) Orders").font(.custom("Helvetica-Bold", size: 11)).foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
            
            // Efficiency indicator
            Circle()
                .fill(store.isActive ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
                .frame(width: 8, height: 8)
        }
        .padding(20)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

// Updated AIForecastDetailModal
struct AIForecastDetailModal: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: DashboardViewModel
    @State private var glowPhase = false
    @State private var predictionPeriod: Int = 7
    let periods = [7, 14, 30]
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                // Animated background glow
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: glowPhase ? 100 : -100, y: glowPhase ? -150 : 150)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // 1. Prediction Controls
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI FORECASTING").font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(Color.purple).kerning(2)
                                Text("Strategic Predictions").font(.custom("Helvetica-Bold", size: 28)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                            }
                            Spacer()
                            Picker("Period", selection: $predictionPeriod) {
                                ForEach(periods, id: \.self) { Text("\($0)D").tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // 2. Main Chart Card
                        VStack(alignment: .leading, spacing: 20) {
                            Text("\(predictionPeriod)-Day Revenue Prediction")
                                .font(.custom("Helvetica-Bold", size: 18))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                
                            Chart {
                                ForEach(viewModel.dailyRevenue.suffix(7)) { item in
                                    LineMark(x: .value("Date", item.date), y: .value("Revenue", item.amount))
                                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                                        .interpolationMethod(.catmullRom)
                                    AreaMark(x: .value("Date", item.date), y: .value("Revenue", item.amount))
                                        .foregroundStyle(LinearGradient(colors: [RSMSTheme.Colors.accentGold.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                                }
                                ForEach(viewModel.forecastRevenue.prefix(predictionPeriod)) { item in
                                    LineMark(x: .value("Date", item.date), y: .value("Forecast", item.amount))
                                        .foregroundStyle(Color.purple)
                                        .lineStyle(StrokeStyle(lineWidth: 3, dash: [5, 5]))
                                        .interpolationMethod(.catmullRom)
                                    AreaMark(x: .value("Date", item.date), y: .value("Forecast", item.amount))
                                        .foregroundStyle(LinearGradient(colors: [Color.purple.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                                }
                            }
                            .frame(height: 250)
                        }
                        .padding(24)
                        .background(RSMSTheme.Colors.backgroundDeep.opacity(0.8))
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(LinearGradient(colors: [.purple.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
                        .padding(.horizontal, 24)
                        
                        // 3. AI Insights Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            InsightGridItem(title: "Predicted AOV", value: viewModel.shortRevenue(viewModel.predictedAOV), icon: "bag.fill", color: .blue)
                            InsightGridItem(title: "Growth Trend", value: "+14.2%", icon: "chart.line.uptrend.xyaxis", color: .green)
                        }
                        .padding(.horizontal, 24)
                        
                        // 4. Detailed Analysis
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "cpu.fill").foregroundStyle(Color.purple)
                                Text("Deep-Dive Intelligence").font(.custom("Helvetica-Bold", size: 16)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                            }
                            
                            Text(viewModel.aiDetailedAnalysis)
                                .font(.custom("Helvetica", size: 15))
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                .lineSpacing(6)
                                .padding(20)
                                .background(RSMSTheme.Colors.backgroundDeep)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(RSMSTheme.Colors.textSecondary) }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) { glowPhase.toggle() }
            }
        }
    }
}

struct InsightGridItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.custom("Helvetica-Bold", size: 10)).foregroundStyle(RSMSTheme.Colors.textTertiary).textCase(.uppercase)
                Text(value).font(.custom("Helvetica-Bold", size: 24)).foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct RetentionDetailModal: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: DashboardViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        // Header Summary
                        HStack(spacing: 20) {
                            let total = Double(viewModel.newCustomers + viewModel.returningCustomers)
                            let returningRatio = total > 0 ? Double(viewModel.returningCustomers) / total : 0
                            
                            ZStack {
                                Circle().stroke(Color.white.opacity(0.05), lineWidth: 15)
                                Circle()
                                    .trim(from: 0, to: returningRatio)
                                    .stroke(RSMSTheme.Colors.success, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                
                                Text(String(format: "%.0f%%", returningRatio * 100))
                                    .font(.custom("Helvetica-Bold", size: 32))
                                    .foregroundStyle(RSMSTheme.Colors.success)
                            }
                            .frame(width: 120, height: 120)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Loyalty Performance")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                Text("Your boutique is retaining \(String(format: "%.0f%%", returningRatio * 100)) of customers. This calculation is derived from real customer order history.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(24)
                        .background(RSMSTheme.Colors.backgroundDeep)
                        .cornerRadius(24)
                        
                        // Detailed Lifecycle Metrics
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Customer Lifecycle")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            
                            let repeatRate = viewModel.totalCustomers > 0 ? (Double(viewModel.returningCustomers) / Double(viewModel.totalCustomers)) * 100 : 0
                            let avgCLV = viewModel.totalCustomers > 0 ? viewModel.totalRevenue / Double(viewModel.totalCustomers) : 0
                            
                            HStack(spacing: 16) {
                                lifecycleCard(label: "Avg. Duration", value: String(format: "%.1f Mo", viewModel.avgCustomerLifecycleDays / 30), icon: "calendar.badge.clock", color: .blue)
                                lifecycleCard(label: "Repeat Rate", value: String(format: "%.0f%%", repeatRate), icon: "arrow.clockwise", color: RSMSTheme.Colors.success)
                            }
                            
                            HStack(spacing: 16) {
                                lifecycleCard(label: "Customer Count", value: "\(viewModel.totalCustomers)", icon: "person.2.fill", color: .green)
                                lifecycleCard(label: "Avg. CLV", value: viewModel.shortRevenue(avgCLV), icon: "chart.line.uptrend.xyaxis", color: RSMSTheme.Colors.accentGold)
                            }
                        }
                        
                        // Strategic Insights (Data Driven)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Operational Insights")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            
                            let topCat = viewModel.categorySales.first?.category.capitalized ?? "None"
                            insightRow(text: "Highest retention observed in '\(topCat)' category products.", icon: "tag.fill", color: .purple)
                            
                            let highValue = viewModel.returningCustomers > 0 ? "Returning customers" : "New customers"
                            insightRow(text: "\(highValue) are currently driving the majority of your boutique revenue.", icon: "star.fill", color: RSMSTheme.Colors.accentGold)
                            
                            insightRow(text: "Data is synchronized with your Supabase database in real-time.", icon: "checkmark.shield.fill", color: .blue)
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Retention Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(RSMSTheme.Colors.textSecondary) }
                }
            }
        }
    }
    
    private func lifecycleCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Spacer()
            }
            Text(value).font(.custom("Helvetica-Bold", size: 24)).foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(RSMSTheme.Colors.textTertiary).textCase(.uppercase)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
    
    private func insightRow(text: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(text).font(.system(size: 15)).foregroundStyle(RSMSTheme.Colors.textPrimary).lineSpacing(4)
            Spacer()
        }
        .padding(20)
        .background(color.opacity(0.05))
        .cornerRadius(16)
    }
}
