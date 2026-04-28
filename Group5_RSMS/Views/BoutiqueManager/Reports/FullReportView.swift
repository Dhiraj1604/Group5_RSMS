//
//  FullReportView.swift
//  Group5_RSMS
//
//  Premium Weekly Intelligence Report - Native iPadOS style.
//  Enhanced with symbol-only toolbars and professional intelligence styling.
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
        📊 Weekly Performance Intelligence
        \(storeName) · \(weekRange)

        Total Sales: ₹\(String(format: "%.0f", vm.totalSales))
        Revenue: ₹\(String(format: "%.0f", vm.totalRevenue))
        Footfall: \(vm.footfall)
        Targets Met: \(vm.targetsMet) / \(vm.targetMetrics.count)
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {

                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 12) {
                            Text(storeName)
                                .font(.custom("Helvetica", size: 40))
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Image(systemName: "calendar")
                                Text(weekRange)
                                    .font(.custom("Helvetica", size: 18))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.accentColor)
                        }
                        .padding(.top, 24)

                        // MARK: - Summary Grid (Segmented Style)
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Consolidated Intelligence")
                                .font(.custom("Helvetica", size: 24))
                                .fontWeight(.bold)

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)], spacing: 20) {
                                SummaryIntelligenceCard(title: "TOTAL SALES", value: "₹\(formatLargeNumber(vm.totalSales))", icon: "indianrupeesign", color: .accentColor)
                                SummaryIntelligenceCard(title: "NET REVENUE", value: "₹\(formatLargeNumber(vm.totalRevenue))", icon: "chart.line.uptrend.xyaxis", color: .green)
                                SummaryIntelligenceCard(title: "STORE FOOTFALL", value: "\(vm.footfall)", icon: "figure.walk", color: .blue)
                                SummaryIntelligenceCard(title: "ORDER VOLUME", value: "\(vm.totalOrders)", icon: "bag.fill", color: .orange)
                            }
                        }

                        // MARK: - Target Achievement
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Strategic Target Matrix")
                                .font(.custom("Helvetica", size: 24))
                                .fontWeight(.bold)

                            HStack(spacing: 16) {
                                TargetResultBadge(label: "OBJECTIVES MET", count: vm.targetsMet, color: .green)
                                TargetResultBadge(label: "OBJECTIVES MISSED", count: vm.targetsMissed, color: .red)
                            }

                            VStack(spacing: 16) {
                                ForEach(vm.targetMetrics) { metric in
                                    FullReportTargetRow(metric: metric)
                                }
                            }
                        }

                        // MARK: - Staff Insights
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Specialist Intelligence")
                                .font(.custom("Helvetica", size: 24))
                                .fontWeight(.bold)

                            HStack(spacing: 20) {
                                ZStack {
                                    Circle().fill(.ultraThinMaterial).frame(width: 60, height: 60)
                                    Image(systemName: "person.badge.minus").font(.title2).foregroundColor(.orange)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(vm.dormantEmployees) Dormant Specialists")
                                        .font(.headline.bold())
                                    Text("Zero revenue contribution signals detected.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(24)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .navigationTitle("Weekly Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.custom("Helvetica", size: 14))
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: shareText) {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                            Image(systemName: "square.and.arrow.up")
                                .font(.custom("Helvetica", size: 14))
                                .fontWeight(.bold)
                        }
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

// MARK: - Components

struct SummaryIntelligenceCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.headline).foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.custom("Helvetica", size: 28))
                    .fontWeight(.bold)
                Text(title)
                    .font(.custom("Helvetica", size: 10))
                    .fontWeight(.black)
                    .tracking(1)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
}

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
                .font(.custom("Helvetica", size: 12))
                .fontWeight(.black)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct FullReportTargetRow: View {
    let metric: TargetMetric

    private var barColor: Color {
        metric.isMet ? Color.accentColor : Color.red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(metric.label)
                    .font(.headline)
                Spacer()
                Text(metric.isMet ? "OBJECTIVE MET" : "OBJECTIVE MISSED")
                    .font(.custom("Helvetica", size: 10))
                    .fontWeight(.black)
                    .foregroundColor(barColor)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        .frame(height: 8)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * min(metric.progress, 1.0), height: 8)
                        .animation(.spring(), value: metric.progress)
                }
            }
            .frame(height: 8)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
