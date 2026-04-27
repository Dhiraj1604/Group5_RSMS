//
//  ICReportsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Reports tab.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

// No longer using CSVDocument here, moved to ICReportPDFGenerator.swift

struct ICReportsTab: View {
    @Environment(AppState.self) private var appState
    @State private var varianceData: [VarianceReportItem] = []
    @State private var heatmapData: [InventoryItem] = []
    @State private var isLoading = true
    @State private var fetchError: String? = nil
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    private var isIPad: Bool { sizeClass == .regular }
    
    private let service = ICReportsService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(RSMSTheme.Colors.accentGold)
                            .scaleEffect(1.5)
                        Text("Loading Reports...")
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                } else if let error = fetchError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(RSMSTheme.Colors.error)
                        Text(error)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadData() }
                        }
                        .buttonStyle(GoldButtonStyle())
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: isIPad ? 48 : 36) {
                            varianceReportSection
                            inventoryHeatMapSection
                        }
                        .padding(.vertical, isIPad ? 40 : 24)
                        .padding(.horizontal, isIPad ? 40 : RSMSTheme.Spacing.horizontalMargin)
                    }
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        fetchError = nil
        do {
            async let vData = service.fetchVarianceReport(storeId: appState.currentStoreID)
            async let hData = service.fetchInventoryHeatMapData(storeId: appState.currentStoreID)
            let (variance, heatmap) = try await (vData, hData)
            
            self.varianceData = variance
            self.heatmapData = heatmap
        } catch {
            self.fetchError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Variance Section
    private var varianceReportSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 24 : 16) {
            HStack {
                Text("Variance Report")
                    .font(.system(size: isIPad ? 28 : 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                let pdfData = ICReportPDFGenerator.generateVariancePDF(data: varianceData, storeName: varianceData.first?.store?.name ?? "Current Store")
                let pdfDoc = PDFReportDocument(data: pdfData, filename: "Variance_Report.pdf")
                
                ShareLink(item: pdfDoc, preview: SharePreview("Variance Report", image: Image(systemName: "doc.text.fill"))) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.Colors.accentGold)
                    .cornerRadius(8)
                }
            }
            
            Text("Latest inventory discrepancies from routine stock checks.")
                .font(.system(size: isIPad ? 16 : 13))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            
            let columns = isIPad ? [GridItem(.flexible()), GridItem(.flexible())] : [GridItem(.flexible())]
            
            LazyVGrid(columns: columns, spacing: 16) {
                if varianceData.isEmpty {
                    Text("No discrepancies found.")
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(varianceData.prefix(isIPad ? 6 : 5)) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.product?.name ?? "Unknown Product")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Store: \(item.store?.name ?? "Current")")
                                    .font(.system(size: 13))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                
                                Text(item.status.capitalized)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(item.status == "approved" ? RSMSTheme.Colors.success : (item.status == "rejected" ? RSMSTheme.Colors.error : RSMSTheme.Colors.textSecondary))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(RSMSTheme.Colors.backgroundElevated)
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(item.status == "approved" ? RSMSTheme.Colors.success : (item.status == "rejected" ? RSMSTheme.Colors.error : RSMSTheme.Colors.borderLight), lineWidth: 0.5)
                                    )
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Var: \(item.variance > 0 ? "+\(item.variance)" : "\(item.variance)")")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(item.variance < 0 ? RSMSTheme.Colors.error : RSMSTheme.Colors.success)
                                Text("Exp: \(item.expectedQuantity) • Act: \(item.actualScannedQuantity)")
                                    .font(.system(size: 12))
                                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                            }
                        }
                        .padding(16)
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                        )
                    }
                    }
                }
            }
            
            if varianceData.count > (isIPad ? 6 : 5) {
                Text("Showing \(isIPad ? 6 : 5) of \(varianceData.count) records")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Heat Map Section
    private var inventoryHeatMapSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 24 : 16) {
            HStack {
                Text("Inventory Heat Map")
                    .font(.system(size: isIPad ? 28 : 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                let pdfData = ICReportPDFGenerator.generateHeatMapPDF(heatmapData: heatmapData, storeName: heatmapData.first?.store?.name ?? "Current Store")
                let pdfDoc = PDFReportDocument(data: pdfData, filename: "Inventory_HeatMap.pdf")
                
                ShareLink(item: pdfDoc, preview: SharePreview("Inventory Heat Map", image: Image(systemName: "grid"))) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RSMSTheme.Colors.accentGold)
                    .cornerRadius(8)
                }
            }
            
            Text("Product distribution by Category vs. Stock Health.")
                .font(.system(size: isIPad ? 16 : 13))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            
            heatMapGrid
        }
    }
    
        let categories = Array(Set(heatmapData.compactMap { $0.product?.category ?? "Other" })).sorted()
        let statuses = ["Out of Stock", "Low", "Healthy", "Overstock", "Floor", "Backroom"]
        
        // Configuration for iPad vs iPhone
        let categoryWidth: CGFloat = isIPad ? 180 : 100
        let statusWidth: CGFloat = isIPad ? 110 : 70
        let cellHeight: CGFloat = isIPad ? 60 : 40
        let headerHeight: CGFloat = isIPad ? 44 : 30
        let fontSize: CGFloat = isIPad ? 14 : 12
        let subFontSize: CGFloat = isIPad ? 13 : 11
        
        // Matrix maps Category -> Status -> Product Count
        var matrix: [String: [String: Int]] = [:]
        for item in heatmapData {
            let cat = item.product?.category ?? "Other"
            
            let minStock = item.minStockLevel ?? 5
            let maxStock = item.maxStockLevel ?? 50
            
            let status: String
            if item.stockQuantity == 0 {
                status = "Out of Stock"
            } else if item.stockQuantity < minStock {
                status = "Low"
            } else if item.stockQuantity > maxStock {
                status = "Overstock"
            } else {
                status = "Healthy"
            }
            
            let current = matrix[cat]?[status] ?? 0
            matrix[cat, default: [:]][status] = current + 1
            
            let locStatus = (item.isOnFloor == true) ? "Floor" : "Backroom"
            let locCurrent = matrix[cat]?[locStatus] ?? 0
            matrix[cat, default: [:]][locStatus] = locCurrent + 1
        }
        
        let maxCount = matrix.values.flatMap { $0.values }.max() ?? 1
        let safeMax = maxCount > 0 ? maxCount : 1
        
        return ScrollView(.horizontal, showsIndicators: true) {
            Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 4) {
                // Header row
                GridRow {
                    Text("Category")
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .frame(width: categoryWidth, alignment: .leading)
                    
                    ForEach(statuses, id: \.self) { status in
                        Text(status)
                            .font(.system(size: subFontSize, weight: .bold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                            .frame(width: statusWidth, height: headerHeight)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Data rows
                ForEach(categories, id: \.self) { category in
                    GridRow {
                        Text(category)
                            .font(.system(size: fontSize, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: categoryWidth, alignment: .leading)
                            .lineLimit(2)
                        
                        ForEach(statuses, id: \.self) { status in
                            let val = matrix[category]?[status] ?? 0
                            let intensity = Double(val) / Double(safeMax)
                            let cellColor = RSMSTheme.Colors.accentGold.opacity(intensity * 0.8 + 0.1)
                            
                            ZStack {
                                Rectangle()
                                    .fill(val == 0 ? RSMSTheme.Colors.backgroundElevated : cellColor)
                                
                                Text("\(val)")
                                    .font(.system(size: fontSize, weight: val > 0 ? .bold : .regular))
                                    .foregroundColor(val == 0 ? RSMSTheme.Colors.textTertiary : (intensity > 0.5 ? .black : .white))
                            }
                            .frame(width: statusWidth, height: cellHeight)
                            .cornerRadius(isIPad ? 8 : 4)
                        }
                    }
                }
            }
            .padding(isIPad ? 24 : 16)
            .background(RSMSTheme.Colors.backgroundElevated)
            .cornerRadius(isIPad ? 20 : 16)
            .overlay(
                RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
            )
        }
    }

    // CSV Generators removed as we are now using PDF Generator Utility
}
