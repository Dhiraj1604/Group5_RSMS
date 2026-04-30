//
//  FullReportView.swift
//  Group5_RSMS
//
//  Created by Apple on 24/04/26.
//  Boutique Manager — Consolidated Performance Report (iOS Premium Standard).
//

import SwiftUI
import Charts

struct FullReportView: View {
    let storeName: String
    let vm: BMReportsViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isExportingPDF = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    private var weekRange: String {
        let cal = Calendar.current
        let today = Date()
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        let endOfWeek = cal.date(byAdding: .day, value: 6, to: startOfWeek) ?? today
        let fmt = DateFormatter()
        fmt.dateFormat = "dd MMM yyyy"
        return "\(fmt.string(from: startOfWeek)) — \(fmt.string(from: endOfWeek))"
    }

    private var targetAchievementRate: Int {
        guard !vm.targetMetrics.isEmpty else { return 0 }
        let totalProgress = vm.targetMetrics.reduce(0.0) { $0 + min($1.progress, 1.0) }
        return Int((totalProgress / Double(vm.targetMetrics.count)) * 100)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                // Background Glow
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: -150, y: -250)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {

                        // MARK: - Glass Header
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label("CONSOLIDATED PERFORMANCE REPORT", systemImage: "chart.bar.doc.horizontal.fill")
                                    .font(.system(size: 12, weight: .black))
                                    .tracking(1.5)
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                                Spacer()
                                Text("V1.0.4")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(storeName)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                                
                                Rectangle()
                                    .fill(RSMSTheme.Colors.accentGold.opacity(0.3))
                                    .frame(width: 60, height: 4)
                                    .cornerRadius(2)
                            }
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(RSMSTheme.Colors.accentGold)
                                Text(weekRange)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                        }
                        .padding(.top, 20)

                        // MARK: - Overall Progress Breakdown
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Overall Target Achievement")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                    Text("\(targetAchievementRate)%")
                                        .font(.system(size: 48, weight: .bold, design: .rounded))
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Status")
                                        .font(.system(size: 12))
                                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                                    StatusBadge(rate: targetAchievementRate)
                                }
                            }
                            
                            Text("Aggregated performance across Sales, Inventory Floor Rotation, and Revenue targets.")
                                .font(.system(size: 13))
                                .italic()
                                .foregroundColor(RSMSTheme.Colors.textTertiary)
                                .padding(.top, -8)

                            ProgressView(value: Double(targetAchievementRate), total: 100)
                                .tint(RSMSTheme.Colors.goldGradient)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                                .clipShape(Capsule())
                        }
                        .padding(24)
                        .background(RSMSTheme.Colors.backgroundElevated.opacity(0.6))
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))

                        // MARK: - Missing Data Flags
                        if !vm.missingDataFlags.isEmpty {
                            WarningBanner(flags: Array(vm.missingDataFlags.keys))
                        }

                        // MARK: - Key Metrics Grid
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(title: "FINANCIAL SUMMARY")

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ModernMetricCard(title: "Gross Sales", value: "₹\(formatLargeNumber(vm.totalSales))", icon: "indianrupeesign.circle.fill", color: RSMSTheme.Colors.accentGold)
                                ModernMetricCard(title: "Net Revenue", value: "₹\(formatLargeNumber(vm.totalRevenue))", icon: "chart.line.uptrend.xyaxis.circle.fill", color: RSMSTheme.Colors.success)
                                ModernMetricCard(title: "Store Footfall", value: "\(vm.footfall)", icon: "figure.walk.circle.fill", color: RSMSTheme.Colors.accentGoldLight)
                                ModernMetricCard(title: "Total Orders", value: "\(vm.totalOrders)", icon: "bag.circle.fill", color: RSMSTheme.Colors.warning)
                            }
                        }

                        // MARK: - Top Products
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(title: "TOP PERFORMING PRODUCTS")

                            if vm.topProducts.isEmpty {
                                ReportEmptyStateView(message: "No sales data available for this week.")
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(vm.topProducts) { product in
                                        PremiumProductRow(product: product)
                                    }
                                }
                            }
                        }

                        // MARK: - Detailed Targets
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(title: "STRATEGIC TARGETS")

                            VStack(spacing: 16) {
                                ForEach(vm.targetMetrics) { metric in
                                    PremiumTargetRow(metric: metric)
                                }
                            }
                        }

                        // MARK: - Footer / Export
                        VStack(spacing: 20) {
                            Button(action: generatePDF) {
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
                            
                            Text("Last Data Sync: \(Date().formatted(.dateTime.hour().minute()))")
                                .font(.system(size: 11))
                                .foregroundColor(RSMSTheme.Colors.textTertiary)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Performance")
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
        }
    }

    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 100_000 { return String(format: "%.1fL", value / 100_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
    
    // MARK: - Real PDF Generation Logic
    @MainActor
    private func generatePDF() {
        isExportingPDF = true
        
        // 1. Prepare the printable view
        let printableContent = PrintableReportView(storeName: storeName, vm: vm)
        let renderer = ImageRenderer(content: printableContent)
        
        // 2. Define export URL
        let fileName = "Weekly_Report_\(storeName.replacingOccurrences(of: " ", with: "_")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // 3. Render to PDF
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            
            guard let pdfContext = CGContext(url as CFURL, mediaBox: &box, nil) else {
                print("Failed to create PDF Context")
                return
            }
            
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

// MARK: - Printable View (Optimized for PDF)
struct PrintableReportView: View {
    let storeName: String
    let vm: BMReportsViewModel
    
    private var accentColor = Color(red: 0.74, green: 0.60, blue: 0.35) // RSMS Gold
    
    init(storeName: String, vm: BMReportsViewModel) {
        self.storeName = storeName
        self.vm = vm
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Premium Header Strip
            Rectangle()
                .fill(accentColor)
                .frame(height: 8)
            
            VStack(alignment: .leading, spacing: 30) {
                // 2. Corporate Identity
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WEEKLY PERFORMANCE AUDIT")
                            .font(.system(size: 10, weight: .black))
                            .tracking(2)
                            .foregroundColor(accentColor)
                        
                        Text(storeName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Report Period: \(Date().addingTimeInterval(-604800).formatted(date: .abbreviated, time: .omitted)) — \(Date().formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(accentColor)
                }
                .padding(.bottom, 10)
                
                // 3. Financial Summary Bento Box
                VStack(alignment: .leading, spacing: 15) {
                    Text("FINANCIAL EXECUTIVE SUMMARY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        PrintableMetricBox(label: "GROSS SALES", value: "₹\(Int(vm.totalSales))", color: .black)
                        PrintableMetricBox(label: "NET REVENUE", value: "₹\(Int(vm.totalRevenue))", color: accentColor)
                        PrintableMetricBox(label: "STORE FOOTFALL", value: "\(vm.footfall)", color: .black)
                    }
                }
                
                // 4. Product Intelligence Table
                VStack(alignment: .leading, spacing: 15) {
                    Text("TOP PERFORMING INVENTORY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 0) {
                        // Table Header
                        HStack {
                            Text("PRODUCT DETAILS").frame(width: 250, alignment: .leading)
                            Text("SKU").frame(width: 100, alignment: .leading)
                            Text("UNITS").frame(width: 60, alignment: .trailing)
                            Spacer()
                            Text("TOTAL REVENUE").frame(width: 120, alignment: .trailing)
                        }
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 15)
                        .background(Color.gray.opacity(0.1))
                        
                        ForEach(Array(vm.topProducts.prefix(5))) { product in
                            PrintableProductRow(product: product)
                            Divider()
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
                
                // 5. Strategic Target Achievement
                VStack(alignment: .leading, spacing: 15) {
                    Text("STRATEGIC GOAL TRACKING")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    
                    ForEach(vm.targetMetrics.prefix(3)) { metric in
                        PrintableTargetRow(metric: metric)
                    }
                }
                
                Spacer()
                
                // 6. Formal Approval Section
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 40) {
                        Text("MANAGER SIGNATURE").font(.system(size: 8, weight: .bold))
                        Rectangle().fill(Color.black).frame(width: 200, height: 1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 40) {
                        Text("DATE OF APPROVAL").font(.system(size: 8, weight: .bold))
                        Rectangle().fill(Color.black).frame(width: 150, height: 1)
                    }
                }
                .padding(.bottom, 40)
                
                // Footer
                HStack {
                    Text("CONFIDENTIAL DOCUMENT • FOR CORPORATE REVIEW ONLY")
                    Spacer()
                    Text("GENERATED AT \(Date().formatted())")
                }
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
            }
            .padding(40)
        }
        .frame(width: 595, height: 842) // A4 Size at 72 DPI
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
            Text(product.name).frame(width: 250, alignment: .leading)
                .font(.system(size: 12, weight: .semibold))
            Text(product.sku).frame(width: 100, alignment: .leading)
                .font(.system(size: 10, design: .monospaced))
            Text("\(product.quantitySold)").frame(width: 60, alignment: .trailing)
            Spacer()
            Text("₹\(Int(product.totalRevenue))").frame(width: 120, alignment: .trailing)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 15)
    }
}

struct PrintableTargetRow: View {
    let metric: TargetMetric
    private var accentColor = Color(red: 0.74, green: 0.60, blue: 0.35)
    
    init(metric: TargetMetric) {
        self.metric = metric
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(metric.label).font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(Int(metric.progress * 100))%").font(.system(size: 12, weight: .bold))
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.gray.opacity(0.1)).frame(height: 4)
                RoundedRectangle(cornerRadius: 2).fill(accentColor).frame(width: 480 * min(metric.progress, 1.0), height: 4)
            }
        }
        .padding(.bottom, 8)
    }
}

struct PrintableMetricBox: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.0)
            .foregroundColor(RSMSTheme.Colors.textTertiary)
    }
}

struct StatusBadge: View {
    let rate: Int
    var body: some View {
        Text(rate >= 80 ? "ON TRACK" : (rate >= 50 ? "AT RISK" : "CRITICAL"))
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(rate >= 80 ? RSMSTheme.Colors.success.opacity(0.2) : (rate >= 50 ? RSMSTheme.Colors.warning.opacity(0.2) : RSMSTheme.Colors.error.opacity(0.2)))
            .foregroundColor(rate >= 80 ? RSMSTheme.Colors.success : (rate >= 50 ? RSMSTheme.Colors.warning : RSMSTheme.Colors.error))
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
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(RSMSTheme.Colors.backgroundElevated.opacity(0.4))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct WarningBanner: View {
    let flags: [String]
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundColor(RSMSTheme.Colors.warning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Incomplete Reporting Segments")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text("Data gaps detected in: \(flags.joined(separator: ", ")). Results may be skewed.")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
        }
        .padding(18)
        .background(RSMSTheme.Colors.warning.opacity(0.08))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSTheme.Colors.warning.opacity(0.3), lineWidth: 1))
    }
}

struct PremiumProductRow: View {
    let product: SoldProduct

    var body: some View {
        HStack(spacing: 16) {
            if let urlStr = product.imageUrl, let url = URL(string: urlStr) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    RSMSTheme.Colors.surfacePrimary
                }
                .frame(width: 54, height: 54)
                .cornerRadius(12)
            } else {
                ZStack {
                    RSMSTheme.Colors.surfacePrimary
                    Image(systemName: "tag.fill")
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                }
                .frame(width: 54, height: 54)
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(product.sku)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(product.quantitySold) sold")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text("₹\(String(format: "%.0f", product.totalRevenue))")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }
        }
        .padding(14)
        .background(RSMSTheme.Colors.backgroundElevated.opacity(0.3))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct PremiumTargetRow: View {
    let metric: TargetMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text(metric.isMet ? "Goal Achieved" : "\(Int((1 - metric.progress) * 100))% remaining")
                        .font(.system(size: 12))
                        .foregroundColor(metric.isMet ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
                }
                Spacer()
                Text("\(Int(min(metric.progress, 1.0) * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(metric.isMet ? RSMSTheme.Colors.success : RSMSTheme.Colors.accentGold)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RSMSTheme.Colors.surfacePrimary.opacity(0.5))
                        .frame(height: 8)
                    if metric.isMet {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(RSMSTheme.Colors.success.gradient)
                            .frame(width: geo.size.width * min(metric.progress, 1.0), height: 8)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(RSMSTheme.Colors.goldGradient)
                            .frame(width: geo.size.width * min(metric.progress, 1.0), height: 8)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(RSMSTheme.Colors.backgroundElevated.opacity(0.4))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct ReportEmptyStateView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(RSMSTheme.Colors.textTertiary.opacity(0.5))
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(RSMSTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Helpers

struct ReportShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
