//
//  ICReportsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Reports tab.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

struct CSVDocument: Transferable {
    let text: String
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { doc in
            doc.text.data(using: .utf8) ?? Data()
        }
        .suggestedFileName { doc in
            doc.filename
        }
    }
}

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
            self.fetchError = error.localizedDescription
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
                
                let csvDoc = CSVDocument(text: generateVarianceCSV(), filename: "Variance_Report.csv")
                
                ShareLink(item: csvDoc, preview: SharePreview("Variance Report")) {
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
                        Text("Showing 5 of \(varianceData.count) records")
                            .font(.system(size: 12))
                            .foregroundColor(RSMSTheme.Colors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
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
                
                let csvDoc = CSVDocument(text: generateHeatMapCSV(), filename: "HeatMap_Report.csv")
                
                ShareLink(item: csvDoc, preview: SharePreview("Inventory Heat Map")) {
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
        
        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                // Header row
                HStack(spacing: 4) {
                    Text("Category")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .frame(width: 100, alignment: .leading)
                    
                    ForEach(statuses, id: \.self) { status in
                        Text(status)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                            .frame(width: 70, height: 30)
                            .lineLimit(1)
                    }
                }
                
                // Data rows
                ForEach(categories, id: \.self) { category in
                    HStack(spacing: 4) {
                        Text(category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 100, alignment: .leading)
                            .lineLimit(1)
                        
                        ForEach(statuses, id: \.self) { status in
                            let val = matrix[category]?[status] ?? 0
                            let intensity = Double(val) / Double(safeMax)
                            let cellColor = RSMSTheme.Colors.accentGold.opacity(intensity * 0.8 + 0.1)
                            
                            ZStack {
                                Rectangle()
                                    .fill(val == 0 ? RSMSTheme.Colors.backgroundElevated : cellColor)
                                
                                Text("\(val)")
                                    .font(.system(size: 12, weight: val > 0 ? .bold : .regular))
                                    .foregroundColor(val == 0 ? RSMSTheme.Colors.textTertiary : (intensity > 0.5 ? .black : .white))
                            }
                            .frame(width: 70, height: 40)
                            .cornerRadius(4)
                        }
                    }
                }
            }
            .padding(16)
            .background(RSMSTheme.Colors.backgroundElevated)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
            )
        }
    }

    // MARK: - CSV Generators
    private func generateVarianceCSV() -> String {
        var csv = "Date,Product,Store,Expected Quantity,Actual Quantity,Variance\n"
        for item in varianceData {
            let dateStr = item.createdAt.formatted(date: .numeric, time: .omitted)
            let product = (item.product?.name ?? "Unknown").replacingOccurrences(of: ",", with: " ")
            let store = (item.store?.name ?? "Unknown").replacingOccurrences(of: ",", with: " ")
            csv += "\(dateStr),\(product),\(store),\(item.expectedQuantity),\(item.actualScannedQuantity),\(item.variance)\n"
        }
        return csv
    }
    
    private func generateHeatMapCSV() -> String {
        let categories = Array(Set(heatmapData.compactMap { $0.product?.category ?? "Other" })).sorted()
        let statuses = ["Out of Stock", "Low", "Healthy", "Overstock", "Floor", "Backroom"]
        
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
        
        var csv = "Category,Out of Stock,Low,Healthy,Overstock,Floor,Backroom\n"
        for cat in categories {
            var row = [cat.replacingOccurrences(of: ",", with: " ")]
            for status in statuses {
                let val = matrix[cat]?[status] ?? 0
                row.append("\(val)")
            }
            csv += row.joined(separator: ",") + "\n"
        }
        return csv
    }
}
