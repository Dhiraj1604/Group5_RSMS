//
//  FullReportView.swift
//  Group5_RSMS
//
//  Created by Apple on 24/04/26.
//

import SwiftUI

struct FullReportView: View {
    let storeName: String
    let vm: BMReportsViewModel

    @Environment(\.dismiss) private var dismiss

    private var weekRange: String {
        let cal = Calendar.current
        let today = Date()
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let endOfWeek = cal.date(byAdding: .day, value: 6, to: startOfWeek) ?? today
        let fmt = DateFormatter()
        fmt.dateFormat = "dd MMM yyyy"
        return "\(fmt.string(from: startOfWeek)) — \(fmt.string(from: endOfWeek))"
    }

    private var shareText: String {
        """
        📊 Weekly Performance Report
        \(storeName) · \(weekRange)

        Total Sales: ₹\(String(format: "%.0f", vm.totalSales))
        Revenue: ₹\(String(format: "%.0f", vm.totalRevenue))
        Footfall: \(vm.footfall)
        Targets Met: \(vm.targetsMet) / \(vm.targetMetrics.count)
        Targets Missed: \(vm.targetsMissed) / \(vm.targetMetrics.count)
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(storeName)
                                .font(RSMSTheme.Typography.heading2)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            Text(weekRange)
                                .font(RSMSTheme.Typography.bodyCopy1)
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                        }

                        Divider().background(RSMSTheme.Colors.border)

                        // MARK: - Summary Grid
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Consolidated Summary")
                                .font(RSMSTheme.Typography.heading4)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                SummaryMetricCard(title: "Total Sales", value: "₹\(formatLargeNumber(vm.totalSales))", icon: "indianrupeesign.circle.fill", color: RSMSTheme.Colors.accentGold)
                                SummaryMetricCard(title: "Revenue", value: "₹\(formatLargeNumber(vm.totalRevenue))", icon: "chart.line.uptrend.xyaxis.circle.fill", color: RSMSTheme.Colors.success)
                                SummaryMetricCard(title: "Footfall", value: "\(vm.footfall)", icon: "figure.walk.circle.fill", color: RSMSTheme.Colors.accentGoldLight)
                                SummaryMetricCard(title: "Total Orders", value: "\(vm.totalOrders)", icon: "bag.circle.fill", color: RSMSTheme.Colors.warning)
                            }
                        }

                        Divider().background(RSMSTheme.Colors.border)

                        // MARK: - Targets Summary
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Target Achievement")
                                .font(RSMSTheme.Typography.heading4)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)

                            HStack(spacing: 16) {
                                TargetResultBadge(label: "Met", count: vm.targetsMet, color: RSMSTheme.Colors.success)
                                TargetResultBadge(label: "Missed", count: vm.targetsMissed, color: RSMSTheme.Colors.error)
                            }

                            ForEach(vm.targetMetrics) { metric in
                                FullReportTargetRow(metric: metric)
                            }
                        }

                        Divider().background(RSMSTheme.Colors.border)

                        // MARK: - Dormant Staff
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Staff Insights")
                                .font(RSMSTheme.Typography.heading4)
                                .foregroundColor(RSMSTheme.Colors.textPrimary)

                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                                    .font(.title2)
                                    .foregroundColor(RSMSTheme.Colors.warning)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(vm.dormantEmployees) Dormant")
                                        .font(RSMSTheme.Typography.heading4)
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                    Text("Staff with zero sales this month")
                                        .font(RSMSTheme.Typography.caption)
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(RSMSTheme.Colors.backgroundElevated)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Weekly Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
    }

    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 100_000 { return String(format: "%.1fL", value / 100_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
}

// MARK: - Summary Metric Card
struct SummaryMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(RSMSTheme.Typography.caption)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}

// MARK: - Target Result Badge
struct TargetResultBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text("\(count) \(label)")
                .font(RSMSTheme.Typography.bodyCopy2)
                .foregroundColor(RSMSTheme.Colors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(20)
    }
}

// MARK: - Full Report Target Row
struct FullReportTargetRow: View {
    let metric: TargetMetric

    private var barColor: Color {
        metric.isMet ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.error
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(metric.label)
                    .font(RSMSTheme.Typography.bodyCopy1)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                Text(metric.isMet ? "✓ Met" : "✗ Missed")
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(barColor)
            }
            HStack {
                Text("Target: \(formattedValue(metric.target))")
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                Spacer()
                Text("Actual: \(formattedValue(metric.actual))")
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(RSMSTheme.Colors.surfacePrimary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(metric.progress, 1.0), height: 6)
                        .animation(.easeOut(duration: 0.6), value: metric.progress)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(12)
    }

    private func formattedValue(_ val: Double) -> String {
        if val >= 1000 { return "₹\(String(format: "%.1fK", val / 1000))" }
        return String(format: "%.0f", val)
    }
}
