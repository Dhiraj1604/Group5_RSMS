//
//  BMReportsTab.swift
//  Group5_RSMS
//
//  Boutique Manager — Reports. iOS 26 Liquid Glass & Segmented Cards.
//

import SwiftUI
import Charts

struct BMReportsTab: View {
    @Environment(AppState.self) private var appState
    @StateObject private var vm = BMReportsViewModel()

    @State private var chartRange: ChartRange = .oneWeek
    @Namespace private var segmentNamespace

    private var storeName: String {
        guard let storeId = appState.currentStoreID else { return "My Boutique" }
        return appState.stores.first(where: { $0.id == storeId })?.name ?? "My Boutique"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        headerIntelligence
                        metricCardsSection
                        goalTrackingSection
                        revenueTrendSection
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                }

                if vm.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Intelligence Hub")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            if let boutiqueId = appState.currentStoreID {
                                await vm.loadReports(boutiqueId: boutiqueId)
                            }
                        }
                    } label: {
                        LiquidBarButton(icon: "arrow.clockwise")
                    }
                }
            }
            .task {
                if let boutiqueId = appState.currentStoreID {
                    await vm.loadReports(boutiqueId: boutiqueId)
                }
            }
        }
    }

    // MARK: - Subviews

    private var headerIntelligence: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 72, height: 72)
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                Image(systemName: "chart.pie.fill").font(.title).foregroundColor(.accentColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Performance Insight")
                    .font(.custom("Helvetica", size: 28))
                    .fontWeight(.bold)
                Text("Analytical overview for \(storeName)")
                    .font(.custom("Helvetica", size: 16))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(32)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    private var metricCardsSection: some View {
        HStack(spacing: 24) {
            ReportMetricSegmentedCard(title: "TOTAL REVENUE", value: "₹\(formatNumber(vm.totalSales))", icon: "indianrupeesign", color: .green)
            ReportMetricSegmentedCard(title: "STORE TRAFFIC", value: "\(vm.footfall)", icon: "figure.walk", color: .blue)
            ReportMetricSegmentedCard(title: "DORMANT STAFF", value: "\(vm.dormantEmployees)", icon: "person.badge.minus", color: .orange)
        }
    }

    private var goalTrackingSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Strategic Goal Tracking")
                .font(.custom("Helvetica", size: 24))
                .fontWeight(.bold)
                .padding(.horizontal, 8)

            if vm.targetMetrics.isEmpty {
                NoDataIntelligence(icon: "target", message: "Analyzing goal data…")
            } else {
                VStack(spacing: 20) {
                    ForEach(vm.targetMetrics) { metric in
                        TargetIntelligenceRow(metric: metric)
                    }
                }
            }
        }
        .padding(32)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }

    private var revenueTrendSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                Text("Revenue Velocity Trend")
                    .font(.custom("Helvetica", size: 24))
                    .fontWeight(.bold)
                Spacer()
                rangePicker
            }
            .padding(.horizontal, 8)

            let data = vm.chartData(for: chartRange)
            
            if data.isEmpty || data.allSatisfy({ $0.amount == 0 }) {
                NoDataIntelligence(icon: "chart.bar.xaxis", message: "Waiting for transactional data signals")
            } else {
                Chart(data) { point in
                    BarMark(x: .value("Day", point.date, unit: .day), y: .value("Sales", point.amount))
                        .foregroundStyle(Color.accentColor.gradient)
                        .cornerRadius(8)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartRange == .twoWeeks ? 3 : 1)) { _ in
                        AxisValueLabel()
                            .font(.custom("Helvetica", size: 12))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.custom("Helvetica", size: 12))
                    }
                }
                .frame(height: 300)
            }
        }
        .padding(32)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }

    private var rangePicker: some View {
        HStack(spacing: 0) {
            ForEach(ChartRange.allCases, id: \.self) { range in
                Button { withAnimation(.spring()) { chartRange = range } } label: {
                    Text(range.rawValue.prefix(1))
                        .font(.custom("Helvetica", size: 12))
                        .fontWeight(.black)
                        .frame(width: 36, height: 36)
                        .background(chartRange == range ? Color.accentColor : Color.clear)
                        .foregroundColor(chartRange == range ? .white : .secondary)
                        .clipShape(Circle())
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    private var loadingOverlay: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).opacity(0.8).ignoresSafeArea()
            VStack(spacing: 24) {
                ProgressView().scaleEffect(2.0)
                Text("Aggregating Intelligence…")
                    .font(.custom("Helvetica", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatNumber(_ value: Double) -> String {
        if value >= 100_000 { return String(format: "%.1fL", value / 100_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
}

// MARK: - Global Intelligence Components (Centralized for Stability)

struct LiquidBarButton: View {
    let icon: String
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(.blue.opacity(0.3), lineWidth: 0.5))
                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
            
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct LiquidActionButton: View {
    let icon: String
    let color: Color
    var body: some View {
        Button {} label: {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .frame(height: 72)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.2), lineWidth: 0.5))
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
    }
}

struct NoDataIntelligence: View {
    let icon: String
    let message: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.2))
            Text(message)
                .font(.custom("Helvetica", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct SegmentedMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Text(title)
                    .font(.custom("Helvetica", size: 10))
                    .fontWeight(.black)
                    .tracking(1.2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.custom("Helvetica", size: 32))
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }
}

struct PerformanceIntelligenceRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .accentColor
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20, weight: .bold)).foregroundColor(.accentColor)
            }
            Text(label)
                .font(.custom("Helvetica", size: 18))
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.custom("Helvetica", size: 22))
                .fontWeight(.bold)
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }
}

struct PayoutAuditRow: View {
    let payout: CommissionPayout
    var statusColor: Color {
        switch payout.status {
        case .pending: return .orange
        case .approved: return .blue
        case .paid: return .green
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("₹\(payout.commissionAmount.formatted())")
                    .font(.custom("Helvetica", size: 28))
                    .fontWeight(.bold)
                Text("Ending \(payout.periodEnd.formatted(date: .abbreviated, time: .omitted))")
                    .font(.custom("Helvetica", size: 14))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(payout.status.rawValue.uppercased())
                .font(.custom("Helvetica", size: 11))
                .fontWeight(.black)
                .foregroundColor(statusColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(statusColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 12)
    }
}

struct ReportMetricSegmentedCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Text(title)
                    .font(.custom("Helvetica", size: 10))
                    .fontWeight(.black)
                    .tracking(1.2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.custom("Helvetica", size: 32))
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
    }
}

struct TargetIntelligenceRow: View {
    let metric: TargetMetric
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(metric.label)
                    .font(.custom("Helvetica", size: 20))
                    .fontWeight(.bold)
                Spacer()
                Text("\(Int(metric.progress * 100))%")
                    .font(.custom("Helvetica", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(metric.isMet ? .accentColor : .orange)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(UIColor.tertiarySystemGroupedBackground)).frame(height: 12)
                    Capsule().fill(metric.isMet ? Color.accentColor : Color.orange)
                        .frame(width: max(0, geo.size.width * min(metric.progress, 1.0)), height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(24)
        .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
