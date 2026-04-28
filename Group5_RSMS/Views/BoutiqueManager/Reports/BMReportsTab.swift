//
//  BMReportsTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Reports tab with weekly performance metrics.
//

import SwiftUI
import Charts

struct BMReportsTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var vm = BMReportsViewModel()

    @State private var chartRange: ChartRange = .yearly
    @State private var showFullReport = false

    private var storeName: String {
        guard let storeId = appState.currentStoreID else { return "My Boutique" }
        return appState.stores.first(where: { $0.id == storeId })?.name ?? "My Boutique"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // MARK: - Yearly Performance Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Yearly Performance")
                                    .font(RSMSTheme.Typography.heading3)
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                                Text("This year's overview")
                                    .font(RSMSTheme.Typography.caption)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                            Spacer()
                        }

                        // MARK: - Metric Cards Row
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                NavigationLink(destination: ProductSalesReportView(soldProducts: vm.soldProducts, unsoldProducts: [], mode: .sold)) {
                                    ReportMetricCard(
                                        title: "Total Sales",
                                        value: "₹\(formatNumber(vm.totalSales))",
                                        icon: "indianrupeesign.circle.fill",
                                        trendText: "",
                                        accentColor: RSMSTheme.Colors.accentGold
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink(destination: ProductSalesReportView(soldProducts: [], unsoldProducts: vm.unsoldProducts, mode: .slowMoving)) {
                                    ReportMetricCard(
                                        title: "Footfall",
                                        value: "\(vm.footfall)",
                                        icon: "figure.walk.circle.fill",
                                        trendText: "",
                                        accentColor: RSMSTheme.Colors.accentGoldLight
                                    )
                                }
                                .buttonStyle(.plain)

                                NavigationLink(destination: DormantStaffReportView(dormantStaff: vm.dormantStaffDetails)) {
                                    ReportMetricCard(
                                        title: "Dormant Staff",
                                        value: "\(vm.dormantEmployees)",
                                        icon: "person.crop.circle.badge.exclamationmark.fill",
                                        trendText: "",
                                        accentColor: RSMSTheme.Colors.warning
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // MARK: - Targets vs Actual Panel
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("Targets vs Actual")
                                    .font(RSMSTheme.Typography.heading4)
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Circle().fill(RSMSTheme.Colors.accentGold).frame(width: 8, height: 8)
                                    Text("Met").font(.caption2).foregroundColor(RSMSTheme.Colors.textSecondary)
                                    Circle().fill(RSMSTheme.Colors.textPrimary).frame(width: 8, height: 8)
                                    Text("Missed").font(.caption2).foregroundColor(RSMSTheme.Colors.textSecondary)
                                }
                            }

                            ForEach(vm.targetMetrics) { metric in
                                TargetRow(metric: metric)
                            }
                        }
                        .padding()
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                        )

                        // MARK: - Weekly Sales Chart
                        VStack(alignment: .leading, spacing: 14) {
                            let data = vm.chartData(for: chartRange)
                            let periodTotal = data.reduce(0) { $0 + $1.amount }

                            // Chart Summary Header
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Sales Trend")
                                    .font(RSMSTheme.Typography.heading4)
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                                
                                Text("Visualizing your boutique's monthly revenue flow for the current year.")
                                    .font(.system(size: 13))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                HStack(spacing: 4) {
                                    Text("Yearly Total:")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    Text("₹\(formatNumber(periodTotal))")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(RSMSTheme.Colors.accentGold)
                                }
                                .padding(.top, 2)
                            }


                            if data.isEmpty || data.allSatisfy({ $0.amount == 0 }) {
                                VStack(spacing: 10) {
                                    Image(systemName: "chart.bar.xaxis")
                                        .font(.system(size: 36))
                                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.4))
                                    Text("No sales data for this period")
                                        .font(RSMSTheme.Typography.bodyCopy2)
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                            } else {
                                Chart(data) { point in
                                    BarMark(
                                        x: .value("Month", point.date, unit: .month),
                                        y: .value("Sales", point.amount)
                                    )

                                    .foregroundStyle(RSMSTheme.Colors.accentGold.gradient)
                                    .cornerRadius(4)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .month)) { _ in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                            .foregroundStyle(RSMSTheme.Colors.border)
                                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                            .offset(x: 0, y: 4)
                                    }
                                }

                                .chartYAxis {
                                    AxisMarks(position: .leading) { _ in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                                            .foregroundStyle(RSMSTheme.Colors.border)
                                        AxisValueLabel()
                                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                                    }
                                }
                                .frame(height: 200)
                                .padding(.top, 10)
                                .animation(.easeInOut, value: chartRange)
                            }

                        }
                        .padding()
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                        )

                        // MARK: - View Full Report CTA (Hidden as requested)
                        /*
                        Button {
                            showFullReport = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("View Full Report")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(GoldButtonStyle())
                        .padding(.top, 4)
                        */
                    }
                    .padding()
                    // Inside the ZStack, after ScrollView closing brace
                    if vm.isLoading {
                        ZStack {
                            RSMSTheme.Colors.backgroundPrimary.opacity(0.85)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: RSMSTheme.Colors.accentGold))
                                    .scaleEffect(1.4)
                                
                                Text("Loading report...")
                                    .font(RSMSTheme.Typography.bodyCopy2)
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: vm.isLoading)
                    }
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if let boutiqueId = appState.currentStoreID {
                                await vm.loadReports(boutiqueId: boutiqueId)
                            }
                        }
                    } label: {
                        Image(systemName: vm.isLoading ? "arrow.clockwise" : "arrow.clockwise")
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                            .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
                            .animation(
                                vm.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: vm.isLoading
                            )
                    }
                    .disabled(vm.isLoading)
                }
            }
            .task {
                if let boutiqueId = appState.currentStoreID {
                    await vm.loadReports(boutiqueId: boutiqueId)
                }
            }
            .sheet(isPresented: $showFullReport) {
                FullReportView(storeName: storeName, vm: vm)
            }
        }
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 100_000 { return String(format: "%.1fL", value / 100_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
}

// MARK: - Report Metric Card
struct ReportMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let trendText: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(accentColor)
                Spacer()
            }
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 4) {
                Text(title)
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Text("·")
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                Text(trendText)
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(accentColor)
            }
        }
        .frame(width: 160)
        .padding()
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}

// MARK: - Target Row
struct TargetRow: View {
    let metric: TargetMetric

    private var barColor: Color {
        metric.isMet ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(metric.label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                Text("\(Int(metric.progress * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(barColor)
            }
            HStack {
                Text("Target: \(shortFormat(metric.target))")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Spacer()
                Text("Actual: \(shortFormat(metric.actual))")
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(RSMSTheme.Colors.surfacePrimary)
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(metric.progress, 1.0), height: 5)
                        .animation(.easeOut(duration: 0.8), value: metric.progress)
                }
            }
            .frame(height: 5)
        }
        .padding(12)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(10)
    }

    private func shortFormat(_ val: Double) -> String {
        if val >= 100_000 { return "₹\(String(format: "%.1fL", val / 100_000))" }
        if val >= 1_000 { return "₹\(String(format: "%.1fK", val / 1_000))" }
        return String(format: "%.0f", val)
    }
}

#Preview {
    BMReportsTab()
        .environment(AppState())
}
