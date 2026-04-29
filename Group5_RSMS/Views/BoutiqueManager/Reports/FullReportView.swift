//
//  FullReportView.swift
//  Group5_RSMS
//
//  Boutique Manager — Consolidated Multi-Period Performance Report.
//

import SwiftUI
import Charts

struct FullReportView: View {
    let storeName: String
    let boutiqueId: UUID
    @ObservedObject var vm: BMReportsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: ConsolidatedPeriod = .threeMonth
    @State private var isExportingPDF = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    private var report: ConsolidatedReportData? { vm.consolidatedReport }

    private var dateRangeLabel: String {
        guard let r = report else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "dd MMM yyyy"
        return "\(fmt.string(from: r.fromDate)) — \(fmt.string(from: r.toDate))"
    }

    private var targetAchievementRate: Int {
        guard let r = report, !r.targetMetrics.isEmpty else { return 0 }
        let total = r.targetMetrics.reduce(0.0) { $0 + min($1.progress, 1.0) }
        return Int((total / Double(r.targetMetrics.count)) * 100)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: -150, y: -250)

                if vm.isLoadingConsolidated {
                    VStack(spacing: 16) {
                        ProgressView().tint(RSMSTheme.Colors.accentGold).scaleEffect(1.5)
                        Text("Building Consolidated Report…")
                            .font(.system(size: 14))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 28) {

                            // MARK: - Header
                            VStack(alignment: .leading, spacing: 14) {
                                Label("CONSOLIDATED PERFORMANCE REPORT", systemImage: "chart.bar.doc.horizontal.fill")
                                    .font(.system(size: 11, weight: .black))
                                    .tracking(1.5)
                                    .foregroundColor(RSMSTheme.Colors.accentGold)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(storeName)
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                    Rectangle()
                                        .fill(RSMSTheme.Colors.accentGold.opacity(0.4))
                                        .frame(width: 60, height: 4)
                                        .cornerRadius(2)
                                }

                                if !dateRangeLabel.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar")
                                            .foregroundColor(RSMSTheme.Colors.accentGold)
                                        Text(dateRangeLabel)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    }
                                }
                            }
                            .padding(.top, 20)

                            // MARK: - Period Picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SELECT REPORT PERIOD")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(RSMSTheme.Colors.textTertiary)

                                HStack(spacing: 8) {
                                    ForEach(ConsolidatedPeriod.allCases) { period in
                                        Button {
                                            selectedPeriod = period
                                            Task {
                                                await vm.loadConsolidatedReport(boutiqueId: boutiqueId, period: period)
                                            }
                                        } label: {
                                            Text(period.shortLabel)
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(selectedPeriod == period ? .black : RSMSTheme.Colors.textSecondary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(selectedPeriod == period ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
                                                .cornerRadius(12)
                                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                                        }
                                    }
                                }
                            }

                            if let r = report {

                                // MARK: - Achievement Card
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(alignment: .bottom) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Overall Target Achievement")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                                            Text("\(targetAchievementRate)%")
                                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                                        }
                                        Spacer()
                                        StatusBadge(rate: targetAchievementRate)
                                    }
                                    Text("Aggregated across Sales, Revenue & Orders for \(r.period.rawValue.lowercased()).")
                                        .font(.system(size: 12))
                                        .italic()
                                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                                    ProgressView(value: Double(targetAchievementRate), total: 100)
                                        .tint(RSMSTheme.Colors.goldGradient)
                                        .scaleEffect(x: 1, y: 2, anchor: .center)
                                        .clipShape(Capsule())
                                }
                                .padding(22)
                                .background(RSMSTheme.Colors.backgroundElevated.opacity(0.6))
                                .background(.ultraThinMaterial)
                                .cornerRadius(22)
                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))

                                // MARK: - Warnings
                                if !r.missingDataFlags.isEmpty {
                                    WarningBanner(flags: Array(r.missingDataFlags.keys))
                                }

                                // MARK: - Financials Grid
                                VStack(alignment: .leading, spacing: 16) {
                                    SectionHeader(title: "FINANCIAL SUMMARY")
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                                        ModernMetricCard(
                                            title: "Total Sales",
                                            value: "₹\(formatLargeNumber(r.totalSales))",
                                            icon: "indianrupeesign.circle.fill",
                                            color: RSMSTheme.Colors.accentGold)
                                        ModernMetricCard(
                                            title: "Net Revenue",
                                            value: "₹\(formatLargeNumber(r.totalRevenue))",
                                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                                            color: RSMSTheme.Colors.success)
                                        ModernMetricCard(
                                            title: "Avg Monthly Sales",
                                            value: "₹\(formatLargeNumber(r.averageMonthlySales))",
                                            icon: "calendar.badge.clock",
                                            color: RSMSTheme.Colors.accentGoldLight)
                                        ModernMetricCard(
                                            title: "Total Orders",
                                            value: "\(r.totalOrders)",
                                            icon: "bag.circle.fill",
                                            color: RSMSTheme.Colors.warning)
                                    }
                                }

                                // MARK: - Top Products
                                VStack(alignment: .leading, spacing: 14) {
                                    SectionHeader(title: "TOP PERFORMING PRODUCTS")
                                    if r.topProducts.isEmpty {
                                        ReportEmptyStateView(message: "No sales data for the selected period.")
                                    } else {
                                        VStack(spacing: 10) {
                                            ForEach(r.topProducts) { product in
                                                PremiumProductRow(product: product)
                                            }
                                        }
                                    }
                                }

                                // MARK: - Targets
                                VStack(alignment: .leading, spacing: 14) {
                                    SectionHeader(title: "STRATEGIC TARGETS — \(r.period.rawValue.uppercased())")
                                    VStack(spacing: 14) {
                                        ForEach(r.targetMetrics) { metric in
                                            PremiumTargetRow(metric: metric)
                                        }
                                    }
                                }

                                // MARK: - Export Button
                                Button(action: { generatePDF(report: r) }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Export PDF Report")
                                    }
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RSMSTheme.Colors.goldGradient)
                                    .cornerRadius(16)
                                    .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.3), radius: 10, y: 5)
                                }
                                .padding(.top, 10)

                                Text("Synced: \(Date().formatted(.dateTime.hour().minute()))")
                                    .font(.system(size: 11))
                                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.bottom, 40)
                            }
                        }
                        .padding(.horizontal, 22)
                    }
                    .refreshable {
                        await vm.loadConsolidatedReport(boutiqueId: boutiqueId, period: selectedPeriod)
                    }
                }
            }
            .navigationTitle("Consolidated Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ReportShareSheet(activityItems: [url])
                }
            }
            .task {
                await vm.loadConsolidatedReport(boutiqueId: boutiqueId, period: selectedPeriod)
            }
        }
    }

    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 100_000 { return String(format: "%.1fL", value / 100_000) }
        if value >= 1_000   { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }

    // MARK: - PDF Generation (uses consolidated report data)
    @MainActor
    private func generatePDF(report: ConsolidatedReportData) {
        isExportingPDF = true
        let printableContent = PrintableReportView(storeName: storeName, report: report)
        let renderer = ImageRenderer(content: printableContent)
        let fileName = "Consolidated_Report_\(storeName.replacingOccurrences(of: " ", with: "_")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let pdfContext = CGContext(url as CFURL, mediaBox: &box, nil) else { return }
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
            DispatchQueue.main.async {
                self.pdfURL = url
                self.isExportingPDF = false
                self.showShareSheet = true
            }
        }
    }
}

// MARK: - Printable View (Optimized for PDF export)
struct PrintableReportView: View {
    let storeName: String
    let report: ConsolidatedReportData

    private var accentColor = Color(red: 0.74, green: 0.60, blue: 0.35)

    init(storeName: String, report: ConsolidatedReportData) {
        self.storeName = storeName
        self.report = report
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(accentColor).frame(height: 8)

            VStack(alignment: .leading, spacing: 28) {
                // Identity
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CONSOLIDATED PERFORMANCE AUDIT")
                            .font(.system(size: 10, weight: .black)).tracking(2)
                            .foregroundColor(accentColor)
                        Text(storeName).font(.system(size: 28, weight: .bold)).foregroundColor(.black)
                        let fmt = DateFormatter()
                        let _ = { fmt.dateFormat = "dd MMM yyyy" }()
                        Text("Period: \(fmt.string(from: report.fromDate)) — \(fmt.string(from: report.toDate))")
                            .font(.system(size: 11)).foregroundColor(.secondary)
                        Text(report.period.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold)).foregroundColor(accentColor)
                    }
                    Spacer()
                    Image(systemName: "crown.fill").font(.system(size: 36)).foregroundColor(accentColor)
                }
                .padding(.bottom, 8)

                // Financial Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("FINANCIAL EXECUTIVE SUMMARY")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                    HStack(spacing: 16) {
                        PrintableMetricBox(label: "TOTAL SALES",       value: "₹\(Int(report.totalSales))",          color: .black)
                        PrintableMetricBox(label: "NET REVENUE",       value: "₹\(Int(report.totalRevenue))",        color: accentColor)
                        PrintableMetricBox(label: "AVG MONTHLY SALES", value: "₹\(Int(report.averageMonthlySales))", color: .black)
                    }
                }

                // Product Table
                VStack(alignment: .leading, spacing: 10) {
                    Text("TOP PERFORMING INVENTORY")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                    VStack(spacing: 0) {
                        HStack {
                            Text("PRODUCT").frame(width: 240, alignment: .leading)
                            Text("SKU").frame(width: 110, alignment: .leading)
                            Text("UNITS").frame(width: 60, alignment: .trailing)
                            Spacer()
                            Text("REVENUE").frame(width: 120, alignment: .trailing)
                        }
                        .font(.system(size: 8, weight: .bold)).foregroundColor(.secondary)
                        .padding(.vertical, 8).padding(.horizontal, 14)
                        .background(Color.gray.opacity(0.1))

                        ForEach(Array(report.topProducts.prefix(5))) { product in
                            PrintableProductRow(product: product)
                            Divider()
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }

                // Targets
                VStack(alignment: .leading, spacing: 10) {
                    Text("STRATEGIC GOAL TRACKING")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                    ForEach(Array(report.targetMetrics.prefix(3))) { metric in
                        PrintableTargetRow(metric: metric)
                    }
                }

                Spacer()

                // Signature
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 36) {
                        Text("MANAGER SIGNATURE").font(.system(size: 8, weight: .bold))
                        Rectangle().fill(Color.black).frame(width: 200, height: 1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 36) {
                        Text("DATE OF APPROVAL").font(.system(size: 8, weight: .bold))
                        Rectangle().fill(Color.black).frame(width: 150, height: 1)
                    }
                }
                .padding(.bottom, 30)

                HStack {
                    Text("CONFIDENTIAL • FOR CORPORATE REVIEW ONLY")
                    Spacer()
                    Text("GENERATED \(Date().formatted())")
                }
                .font(.system(size: 7, weight: .medium)).foregroundColor(.secondary)
            }
            .padding(40)
        }
        .frame(width: 595, height: 842)
        .background(.white)
    }
}

struct PrintableProductRow: View {
    let product: SoldProduct

    init(product: SoldProduct) {
        self.product = product
    }

    var body: some View {
        HStack {
            Text(product.name).frame(width: 240, alignment: .leading)
                .font(.system(size: 11, weight: .semibold))
            Text(product.sku).frame(width: 110, alignment: .leading)
                .font(.system(size: 10, design: .monospaced))
            Text("\(product.quantitySold)").frame(width: 60, alignment: .trailing)
            Spacer()
            Text("₹\(Int(product.totalRevenue))").frame(width: 120, alignment: .trailing)
                .font(.system(size: 11, weight: .bold))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}

struct PrintableTargetRow: View {
    let metric: TargetMetric
    private var accentColor = Color(red: 0.74, green: 0.60, blue: 0.35)

    init(metric: TargetMetric) {
        self.metric = metric
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(metric.label).font(.system(size: 11, weight: .semibold))
                Spacer()
                Text("\(Int(metric.progress * 100))%").font(.system(size: 11, weight: .bold))
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.1)).frame(height: 4)
                RoundedRectangle(cornerRadius: 2).fill(accentColor).frame(width: 480 * min(metric.progress, 1.0), height: 4)
            }
        }
        .padding(.bottom, 6)
    }
}

struct PrintableMetricBox: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 7, weight: .bold)).foregroundColor(.secondary).tracking(1)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Reusable UI Components

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.0)
            .foregroundColor(RSMSTheme.Colors.textTertiary)
    }
}

struct StatusBadge: View {
    let rate: Int
    var body: some View {
        let isGood   = rate >= 80
        let isOk     = rate >= 50
        let label    = isGood ? "ON TRACK" : (isOk ? "AT RISK" : "CRITICAL")
        let bg       = isGood ? RSMSTheme.Colors.success  : (isOk ? RSMSTheme.Colors.warning  : RSMSTheme.Colors.error)
        return Text(label)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(bg.opacity(0.2))
            .foregroundColor(bg)
            .cornerRadius(20)
    }
}

struct ModernMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RSMSTheme.Colors.backgroundElevated.opacity(0.4))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct WarningBanner: View {
    let flags: [String]
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3).foregroundColor(RSMSTheme.Colors.warning)
            VStack(alignment: .leading, spacing: 4) {
                Text("Incomplete Reporting Segments")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text("Data gaps in: \(flags.joined(separator: ", ")). Results may be skewed.")
                    .font(.system(size: 12)).foregroundColor(RSMSTheme.Colors.textSecondary)
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.warning.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSTheme.Colors.warning.opacity(0.3), lineWidth: 1))
    }
}

struct PremiumProductRow: View {
    let product: SoldProduct
    var body: some View {
        HStack(spacing: 14) {
            if let urlStr = product.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RSMSTheme.Colors.surfacePrimary
                }
                .frame(width: 52, height: 52).cornerRadius(12)
            } else {
                ZStack {
                    RSMSTheme.Colors.surfacePrimary
                    Image(systemName: "tag.fill").foregroundColor(RSMSTheme.Colors.textTertiary)
                }
                .frame(width: 52, height: 52).cornerRadius(12)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.system(size: 15, weight: .bold)).foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(product.sku).font(.system(size: 12, weight: .medium)).foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(product.quantitySold) sold")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text("₹\(String(format: "%.0f", product.totalRevenue))")
                    .font(.system(size: 12)).foregroundColor(RSMSTheme.Colors.textTertiary)
            }
        }
        .padding(14)
        .background(RSMSTheme.Colors.backgroundElevated.opacity(0.3))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct PremiumTargetRow: View {
    let metric: TargetMetric
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.label).font(.system(size: 14, weight: .bold)).foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text(metric.isMet ? "Goal Achieved" : "\(Int((1 - metric.progress) * 100))% remaining")
                        .font(.system(size: 11))
                        .foregroundColor(metric.isMet ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                }
                Spacer()
                Text("\(Int(min(metric.progress, 1.0) * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(metric.isMet ? RSMSTheme.Colors.success : RSMSTheme.Colors.accentGold)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(RSMSTheme.Colors.surfacePrimary.opacity(0.5)).frame(height: 8)
                    if metric.isMet {
                        RoundedRectangle(cornerRadius: 4).fill(RSMSTheme.Colors.success.gradient)
                            .frame(width: geo.size.width * min(metric.progress, 1.0), height: 8)
                    } else {
                        RoundedRectangle(cornerRadius: 4).fill(RSMSTheme.Colors.goldGradient)
                            .frame(width: geo.size.width * min(metric.progress, 1.0), height: 8)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(RSMSTheme.Colors.backgroundElevated.opacity(0.4))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct ReportEmptyStateView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 38)).foregroundColor(RSMSTheme.Colors.textTertiary.opacity(0.5))
            Text(message).font(.system(size: 13)).foregroundColor(RSMSTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 36)
    }
}

struct ReportShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
