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
    @State private var selectedPieSlice: String? = nil
    @State private var selectedAngle: Double? = nil

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWide: Bool { sizeClass == .regular }

    private var kpiColumns: [GridItem] {
        let count = isWide ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: RSMSTheme.Spacing.md), count: count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if viewModel.isLoading && viewModel.lastRefreshed == nil {
                    ProgressView().tint(RSMSTheme.Colors.accentGold)
                } else {
                    mainContent
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) { appState.signOut() } label: { Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") }
                    } label: {
                        Image(systemName: "person.circle.fill").font(.title3).foregroundStyle(RSMSTheme.Colors.accentGold)
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
                kpiHeroSection
                
                if let error = viewModel.errorMessage { errorBanner(error) }
                
                // Main Analytics Dashboard
                if isWide {
                    HStack(alignment: .top, spacing: 24) {
                        // Left Column: Strategic Insights & Retention
                        VStack(spacing: 24) {
                            aiForecastSection
                            customerInsightsSection
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right Column: Operational Metrics & Profitability
                        VStack(spacing: 24) {
                            categorySalesSection
                            orderStatsSection
                            inventoryHealthSection
                            profitabilitySection
                        }
                        .frame(width: 420)
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 24) {
                        aiForecastSection
                        customerInsightsSection
                        categorySalesSection
                        orderStatsSection
                        inventoryHealthSection
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
    }

    // MARK: - Components

    private var refreshHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Performance Overview")
                    .font(.custom("Helvetica-Bold", size: 24))
                    .foregroundStyle(.white)
                    .tracking(1.5)
                Text("Updated \(viewModel.lastRefreshedText)").font(.system(size: 13)).foregroundStyle(RSMSTheme.Colors.textTertiary)
            }
            Spacer()
            Button { Task { await viewModel.fetchDashboardData(stores: appState.stores) } } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 12, weight: .semibold))
                    if viewModel.isLoading { ProgressView().controlSize(.mini).tint(RSMSTheme.Colors.accentGold) }
                }
                .foregroundStyle(RSMSTheme.Colors.accentGold).padding(.horizontal, 12).padding(.vertical, 6)
                .background(RSMSTheme.Colors.accentGold.opacity(0.1)).clipShape(Capsule())
                .overlay(Capsule().stroke(RSMSTheme.Colors.accentGold.opacity(0.25), lineWidth: 1))
            }.disabled(viewModel.isLoading)
        }
    }

    private var kpiHeroSection: some View {
        LazyVGrid(columns: kpiColumns, spacing: RSMSTheme.Spacing.md) {
            kpiCard(title: "Total Revenue", value: viewModel.formattedTotalRevenue, icon: "indianrupeesign.circle.fill", color: RSMSTheme.Colors.success)
            kpiCard(title: "Total Orders", value: "\(viewModel.totalOrders)", icon: "bag.fill", color: RSMSTheme.Colors.accentGold)
            kpiCard(title: "Unique SKUs", value: "\(viewModel.totalInventoryUnits)", icon: "shippingbox.fill", color: RSMSTheme.Colors.accentGoldDark)
            kpiCard(title: "Active Stores", value: "\(viewModel.activeStoreCount)", icon: "building.2.fill", color: RSMSTheme.Colors.accentGoldLight)
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
    }

    // MARK: - AI Forecast
    private var aiForecastSection: some View {
        Button(action: { showAIModal = true }) {
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("AI Analyst Insights")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    let next7Days = viewModel.forecastRevenue.prefix(7).reduce(0) { $0 + $1.amount }
                    let last7Days = viewModel.dailyRevenue.suffix(7).reduce(0) { $0 + $1.amount }
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
                            if let lastDate = viewModel.dailyRevenue.last?.date {
                                RuleMark(x: .value("Today", lastDate))
                                    .foregroundStyle(RSMSTheme.Colors.textSecondary.opacity(0.5))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    .annotation(position: .top, alignment: .center) {
                                        Text("TODAY").font(.system(size: 8, weight: .bold)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    }
                            }
                            
                            ForEach(viewModel.dailyRevenue.suffix(10)) { item in
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
                    }

                    // 3. Informative Insights Groups
                    if viewModel.aiPredictions.isEmpty {
                        ProgressView().padding().frame(maxWidth: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            // Predictions Section
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Market Predictions", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.purple)
                                    .textCase(.uppercase)
                                
                                ForEach(viewModel.aiPredictions, id: \.self) { insight in
                                    Text(insight)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.1), lineWidth: 1))
                            
                            // Suggestions Section
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Suggested Actions", systemImage: "lightbulb.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                                    .textCase(.uppercase)
                                
                                ForEach(viewModel.aiSuggestions, id: \.self) { insight in
                                    Text(insight)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RSMSTheme.Colors.accentGold.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.accentGold.opacity(0.1), lineWidth: 1))
                        }
                    }
                }
                .padding()
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
                .font(.custom("Helvetica-Bold", size: 18))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            let statColumns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            
            if isWide {
                HStack(spacing: RSMSTheme.Spacing.md) {
                    statBox(title: "Avg Order Value", value: viewModel.formattedAOV, icon: "cart.fill", color: .blue)
                    statBox(title: "Avg Basket Size", value: String(format: "%.1f", viewModel.avgBasketSize), icon: "bag.fill.badge.plus", color: .purple)
                    statBox(title: "Conversion Rate", value: String(format: "%.1f%%", viewModel.conversionRate), icon: "arrow.triangle.2.circlepath.circle.fill", color: RSMSTheme.Colors.accentGold)
                }
            } else {
                LazyVGrid(columns: statColumns, spacing: 12) {
                    statBox(title: "Avg AOV", value: viewModel.formattedAOV, icon: "cart.fill", color: .blue)
                    statBox(title: "Basket", value: String(format: "%.1f", viewModel.avgBasketSize), icon: "bag.fill.badge.plus", color: .purple)
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
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Text("Sales by Category")
                    .font(.custom("Helvetica-Bold", size: 18))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Spacer()
                Button { showCategoryModal = true } label: { Image(systemName: "arrow.up.left.and.arrow.down.right").foregroundStyle(RSMSTheme.Colors.accentGold).font(.system(size: 14, weight: .bold)) }
            }
            if viewModel.categorySales.isEmpty {
                Text("No data").foregroundStyle(RSMSTheme.Colors.textSecondary).frame(height: 150)
            } else {
                let layout = isWide ? AnyLayout(HStackLayout(spacing: 20)) : AnyLayout(VStackLayout(spacing: 20))
                layout {
                    Chart(viewModel.categorySales) { item in
                        SectorMark(angle: .value("Revenue", item.revenue), innerRadius: .ratio(0.6), angularInset: 1.5)
                            .cornerRadius(4)
                            .foregroundStyle(by: .value("Category", item.category))
                            .opacity(selectedPieSlice == nil || selectedPieSlice == item.category ? 1.0 : 0.3)
                    }
                    .chartForegroundStyleScale([
                        "jewellery": RSMSTheme.Colors.accentGold, 
                        "watches": RSMSTheme.Colors.accentGoldLight, 
                        "leather_goods": Color(red: 0.55, green: 0.45, blue: 0.35), // Burnished Copper
                        "couture": Color(red: 0.85, green: 0.75, blue: 0.65),       // Warm Ivory
                        "accessories": Color(red: 0.40, green: 0.30, blue: 0.20),   // Rich Umber
                        "fragrances": Color(red: 0.70, green: 0.60, blue: 0.40),    // Satin Bronze
                        "other": RSMSTheme.Colors.textSecondary                    // Soft Taupe
                    ])
                    .chartLegend(.hidden)
                    .chartAngleSelection(value: $selectedAngle)
                    .onChange(of: selectedAngle) { oldValue, newValue in
                        if let newValue = newValue {
                            var cumulativeSum: Double = 0
                            for item in viewModel.categorySales {
                                cumulativeSum += item.revenue
                                if newValue <= cumulativeSum {
                                    selectedPieSlice = item.category
                                    break
                                }
                            }
                        } else {
                            selectedPieSlice = nil
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.categorySales.prefix(6)) { item in
                            Button(action: { 
                                withAnimation { selectedPieSlice = selectedPieSlice == item.category ? nil : item.category }
                            }) {
                                HStack(spacing: 8) {
                                    Circle().fill(categoryColor(for: item.category)).frame(width: 8, height: 8)
                                    Text(item.category.capitalized)
                                        .font(.custom("Helvetica-Bold", size: 13))
                                        .foregroundStyle(selectedPieSlice == item.category ? RSMSTheme.Colors.textPrimary : RSMSTheme.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.leading, isWide ? RSMSTheme.Spacing.md : 0)
                    .frame(maxWidth: isWide ? 200 : .infinity, alignment: .leading)
                }
                .padding().background(RSMSTheme.Colors.backgroundDeep).cornerRadius(RSMSTheme.Radius.lg).overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            }
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
            case "jewellery": return RSMSTheme.Colors.accentGold
            case "watches": return RSMSTheme.Colors.accentGoldLight
            case "leather_goods": return Color(red: 0.55, green: 0.45, blue: 0.35)
            case "couture": return Color(red: 0.85, green: 0.75, blue: 0.65)
            case "accessories": return Color(red: 0.40, green: 0.30, blue: 0.20)
            case "fragrances": return Color(red: 0.70, green: 0.60, blue: 0.40)
            default: return RSMSTheme.Colors.textSecondary
        }
    }

    // MARK: - Customer Insights (Luxury Redesign)
    private var customerInsightsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Text("Retention Analytics")
                    .font(.custom("Helvetica-Bold", size: 24))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: 24) {
                let total = Double(viewModel.newCustomers + viewModel.returningCustomers)
                let returningRatio = total > 0 ? Double(viewModel.returningCustomers) / total : 0
                
                let innerLayout = isWide ? AnyLayout(HStackLayout(alignment: .center, spacing: 30)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 30))
                
                innerLayout {
                    // Left: Dynamic Loyalty Gauge
                    ZStack {
                        // Outer Glow
                        Circle().stroke(RSMSTheme.Colors.accentGold.opacity(0.05), lineWidth: 20).blur(radius: 10)
                        
                        // Background Track
                        Circle().stroke(Color.white.opacity(0.05), lineWidth: 12)
                        
                        // Progress Track
                        Circle()
                            .trim(from: 0, to: returningRatio)
                            .stroke(
                                LinearGradient(colors: [RSMSTheme.Colors.accentGold, .orange], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.3), radius: 10)
                        
                        VStack(spacing: 0) {
                            Text(String(format: "%.0f%%", returningRatio * 100))
                                .font(.custom("Helvetica-Bold", size: 38))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            Text("RETURNING")
                                .font(.custom("Helvetica-Bold", size: 9))
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                                .kerning(1.2)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .padding(.leading, isWide ? 10 : 0)
                    
                    // Middle: Strategic Metrics Grid
                    VStack(alignment: .leading, spacing: 16) {
                        retentionMetricPill(title: "New Users", value: "\(viewModel.newCustomers)", trend: "+12%", color: RSMSTheme.Colors.success, icon: "person.badge.plus.fill")
                        retentionMetricPill(title: "Returning", value: "\(viewModel.returningCustomers)", trend: "+5%", color: RSMSTheme.Colors.accentGold, icon: "person.2.fill")
                    }
                    .frame(maxWidth: .infinity)
                    
                    if isWide {
                        Divider().frame(height: 100).background(RSMSTheme.Colors.borderLight.opacity(0.2))
                    }
                    
                    // Right: Lifecycle Insights
                    VStack(alignment: isWide ? .trailing : .leading, spacing: 12) {
                        lifecycleItem(label: "Avg. Lifecycle", value: "4.2 Months", icon: "calendar.badge.clock")
                        lifecycleItem(label: "Repeat Rate", value: "High", icon: "arrow.clockwise.heart.fill", valueColor: RSMSTheme.Colors.success)
                    }
                }
                
                Divider().background(RSMSTheme.Colors.borderLight.opacity(0.3))
                
                // Bottom Insight Banner
                let insightLayout = isWide ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                
                insightLayout {
                    insightPill(text: "Loyalty up 4% vs last month", icon: "arrow.up.heart.fill", color: RSMSTheme.Colors.accentGold)
                    insightPill(text: "High retention in Watches", icon: "sparkles", color: .purple)
                }
            }
            .padding(28)
            .background(
                ZStack {
                    RSMSTheme.Colors.backgroundDeep
                    LinearGradient(colors: [RSMSTheme.Colors.accentGold.opacity(0.03), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            )
            .cornerRadius(24)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }
    
    private func retentionMetricPill(title: String, value: String, trend: String, color: Color, icon: String) -> some View {
        HStack {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(RSMSTheme.Colors.textTertiary).textCase(.uppercase)
                Text(value).font(.custom("Helvetica-Bold", size: 26)).foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
            Spacer()
            Text(trend).font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(color).padding(.horizontal, 8).padding(.vertical, 4).background(color.opacity(0.1)).cornerRadius(6)
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
                    .font(.system(size: 20, weight: .bold))
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
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 20)], spacing: 24) {
                ForEach(Array(viewModel.storeKPIs.prefix(3).enumerated()), id: \.element.id) { index, storeKPI in
                    PremiumStoreCard(storeKPI: storeKPI, viewModel: viewModel, rank: index + 1)
                }
            }
            // Add negative horizontal padding to let scroll view bleed to edges if desired
            // .padding(.horizontal, -RSMSTheme.Spacing.horizontalMargin) 
        }
    }

    // MARK: - Profitability Analytics (Detailed)
    private var profitabilitySection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Profitability Analytics")
                .font(.custom("Helvetica-Bold", size: 20))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            VStack(spacing: 24) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL REVENUE")
                            .font(.custom("Helvetica-Bold", size: 9))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text(viewModel.formattedTotalRevenue)
                            .font(.custom("Helvetica-Bold", size: 24))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("NET MARGIN")
                            .font(.custom("Helvetica-Bold", size: 9))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text("\(String(format: "%.1f%%", viewModel.netProfitMargin))")
                            .font(.custom("Helvetica-Bold", size: 24))
                            .foregroundStyle(RSMSTheme.Colors.success)
                    }
                }
                
                // Detailed Breakdown
                HStack(spacing: 0) {
                    breakdownItem(label: "GROSS PROFIT", value: viewModel.shortRevenue(viewModel.grossProfit), color: RSMSTheme.Colors.accentGold.opacity(0.8))
                    breakdownItem(label: "EST. OPEX", value: viewModel.shortRevenue(viewModel.estimatedOpex), color: .orange.opacity(0.8))
                    breakdownItem(label: "EST. TAX", value: viewModel.shortRevenue(viewModel.estimatedTax), color: .blue.opacity(0.8))
                }
                .clipShape(Capsule())
                
                HStack {
                    Text("Operating Efficiency").font(.custom("Helvetica", size: 12)).foregroundStyle(RSMSTheme.Colors.textSecondary)
                    Spacer()
                    Text("High (82%)").font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(RSMSTheme.Colors.success)
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
        VStack(spacing: 4) {
            Text(label).font(.custom("Helvetica-Bold", size: 8)).foregroundStyle(.white.opacity(0.8))
            Text(value).font(.custom("Helvetica-Bold", size: 11)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color)
    }

    // MARK: - Inventory Turnover (NEW Admin KPI)
    private var inventoryHealthSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Inventory Dynamics")
                .font(.custom("Helvetica-Bold", size: 20))
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
                .font(.custom("Helvetica-Bold", size: 22))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            let layout = isWide ? AnyLayout(HStackLayout(spacing: 25)) : AnyLayout(VStackLayout(spacing: 20))
            
            layout {
                NavigationLink { StockAnalysisStorePickerView() } label: {
                    actionCard(icon: "chart.bar.fill", title: "Stock Analysis", subtitle: "SKU Intelligence", color: .blue)
                }
                NavigationLink { TaxSettingsView() } label: {
                    actionCard(icon: "shield.checkerboard", title: "Tax Rates", subtitle: "Regional Tax & Compliance", color: RSMSTheme.Colors.accentGold)
                }
            }
        }
    }

    private func actionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(LinearGradient(colors: [color.opacity(0.2), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 80, height: 80)
                Image(systemName: icon).font(.system(size: 34, weight: .bold)).foregroundStyle(color)
            }
            
            VStack(spacing: 8) {
                Text(title).font(.custom("Helvetica-Bold", size: 22)).foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(subtitle).font(.custom("Helvetica", size: 15)).foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            
            HStack(spacing: 8) {
                Text("OPEN MODULE").font(.custom("Helvetica-Bold", size: 12)).foregroundStyle(color).tracking(1.2)
                Image(systemName: "arrow.right.circle.fill").font(.title3).foregroundStyle(color)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 260)
        .padding(35)
        .background(
            ZStack {
                RSMSTheme.Colors.backgroundDeep
                RoundedRectangle(cornerRadius: 30).fill(LinearGradient(colors: [color.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        )
        .cornerRadius(30)
        .overlay(RoundedRectangle(cornerRadius: 30).stroke(LinearGradient(colors: [RSMSTheme.Colors.borderLight, .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
    @State private var timePeriod = "30 Days"
    let periods = ["7 Days", "30 Days", "6 Months", "1 Year"]
    
    private let categoryColors: [String: Color] = [
        "jewellery": RSMSTheme.Colors.accentGold, 
        "watches": Color(red: 0/255, green: 180/255, blue: 216/255), // Cyan
        "leather_goods": Color(red: 220/255, green: 20/255, blue: 60/255), // Crimson
        "couture": Color(red: 0/255, green: 200/255, blue: 120/255), // Emerald
        "accessories": Color(red: 140/255, green: 70/255, blue: 210/255), // Purple
        "fragrances": Color(red: 255/255, green: 140/255, blue: 0/255), // Sunset Orange
        "other": Color(red: 0/255, green: 150/255, blue: 180/255) // Teal
    ]

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
                                
                            ForEach(viewModel.categorySales) { item in
                                let percentage = totalCategoryRev > 0 ? (item.revenue / totalCategoryRev) * 100 : 0
                                
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(categoryColors[item.category.lowercased()] ?? RSMSTheme.Colors.accentGold)
                                        .frame(width: 12, height: 12)
                                        
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.category.capitalized)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                        Text("\(item.count) Units Sold")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(viewModel.shortRevenue(item.revenue))
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                                        Text(String(format: "%.1f%%", percentage))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(categoryColors[item.category.lowercased()] ?? RSMSTheme.Colors.accentGold)
                                    }
                                }
                                .padding(16)
                                .background(RSMSTheme.Colors.backgroundDeep)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                                .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                            }
                            
                            Spacer().frame(height: 40)
                        }
                    }
                }
            }
            .navigationTitle("Category Sales Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
