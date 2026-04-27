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
                        VStack(spacing: 36) {
                            varianceReportSection
                            inventoryHeatMapSection
                        }
                        .padding(.vertical, 24)
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
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
            if !(error is CancellationError) {
                self.fetchError = error.localizedDescription
            }
        }
        isLoading = false
    }

    // MARK: - Variance Section
    private var varianceReportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Variance Report")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                let pdfData = ICReportPDFGenerator.generateVariancePDF(data: varianceData, storeName: varianceData.first?.store?.name ?? "Current Store")
                let pdfDoc = PDFReportDocument(data: pdfData, filename: "Variance_Report.pdf")
                
                ShareLink(item: pdfDoc, preview: SharePreview("Variance Report", image: Image(systemName: "doc.text.fill"))) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Text("Latest inventory discrepancies from routine stock checks.")
                .font(.system(size: 13))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            
            VStack(spacing: 12) {
                if varianceData.isEmpty {
                    Text("No discrepancies found.")
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(varianceData.prefix(5)) { item in
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
                    if varianceData.count > 5 {
                        NavigationLink(destination: VarianceReportListView(varianceData: varianceData)) {
                            HStack(spacing: 4) {
                                Text("See All \(varianceData.count) Records")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 12)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Heat Map Section
    private var inventoryHeatMapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Inventory Heat Map")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                let pdfData = ICReportPDFGenerator.generateHeatMapPDF(heatmapData: heatmapData, storeName: heatmapData.first?.store?.name ?? "Current Store")
                let pdfDoc = PDFReportDocument(data: pdfData, filename: "Inventory_HeatMap.pdf")
                
                ShareLink(item: pdfDoc, preview: SharePreview("Inventory Heat Map", image: Image(systemName: "grid"))) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Text("Product distribution by Category vs. Stock Health.")
                .font(.system(size: 13))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            
            heatMapGrid
        }
    }
    
    private var heatMapGrid: some View {
        let categories = Array(Set(heatmapData.compactMap { $0.product?.category ?? "Other" })).sorted()
        let statuses = ["Out of Stock", "Low", "Healthy", "Overstock", "Floor", "Backroom"]
        
        // Matrix maps Category -> Status -> Product Count
        var matrix: [String: [String: Int]] = [:]
        for item in heatmapData {
            let cat = item.product?.category ?? "Other"
            
            let minStock = item.minStockLevel ?? 5
            let maxStock = item.maxStockLevel ?? 50
            
            let status: String
            if item.stockQuantity <= 2 {
                status = "Critical"
            } else if item.stockQuantity < minStock {
                status = "Low"
            } else if item.stockQuantity > maxStock {
                status = "In-Stock"
            } else {
                status = "Healthy"
            }
            
            let current = matrix[cat]?[status] ?? 0
            matrix[cat, default: [:]][status] = current + 1
            
            let locStatus = (item.isOnFloor == true) ? "Floor" : "Backroom"
            let locCurrent = matrix[cat]?[locStatus] ?? 0
            matrix[cat, default: [:]][locStatus] = locCurrent + 1
        }
        
        return VStack(spacing: 12) {
            ForEach(categories, id: \.self) { category in
                VStack(alignment: .leading, spacing: 14) {
                    Text(category)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    
                    VStack(spacing: 8) {
                        // Health metrics
                        HStack(spacing: 8) {
                            heatMapPill(title: "Critical", value: matrix[category]?["Critical"] ?? 0, highlightColor: RSMSTheme.Colors.error)
                            heatMapPill(title: "Low", value: matrix[category]?["Low"] ?? 0, highlightColor: RSMSTheme.Colors.warning)
                            heatMapPill(title: "Good", value: matrix[category]?["Healthy"] ?? 0, highlightColor: RSMSTheme.Colors.success)
                            heatMapPill(title: "In-Stock", value: matrix[category]?["In-Stock"] ?? 0, highlightColor: RSMSTheme.Colors.textSecondary)
                        }
                        
                        // Location metrics
                        HStack(spacing: 8) {
                            heatMapPill(title: "Floor", value: matrix[category]?["Floor"] ?? 0, highlightColor: RSMSTheme.Colors.accentGold)
                            heatMapPill(title: "Backroom", value: matrix[category]?["Backroom"] ?? 0, highlightColor: RSMSTheme.Colors.accentGoldDark)
                        }
                    }
                }
                .padding(16)
                .background(RSMSTheme.Colors.backgroundElevated)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
                )
            }
        }
    }
    
    private func heatMapPill(title: String, value: Int, highlightColor: Color) -> some View {
        return VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(highlightColor.opacity(0.8))
                .textCase(.uppercase)
            
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(highlightColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(highlightColor.opacity(0.1))
        .cornerRadius(8)
    }

    // CSV Generators removed as we are now using PDF Generator Utility
}
