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
    
    // For Heat Map dropdown
    @State private var availableCategories: [String] = ["All"] + ProductCategory.allCases.map { $0.rawValue }.sorted()
    @State private var selectedCategory: String = "All"
    @State private var categorySearchText: String = ""
    
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
            HStack(spacing: 12) {
                Text("Variance Report")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if varianceData.count > 5 {
                    NavigationLink(destination: VarianceReportListView(varianceData: varianceData)) {
                        HStack(spacing: 4) {
                            Text("See All")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                    }
                }
                
                let pdfData = ICReportPDFGenerator.generateVariancePDF(data: varianceData, storeName: varianceData.first?.store?.name ?? "Current Store")
                let pdfDoc = PDFReportDocument(data: pdfData, filename: "Variance_Report.pdf")
                
                ShareLink(item: pdfDoc, preview: SharePreview("Variance Report", image: Image(systemName: "doc.text.fill"))) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(RSMSTheme.Colors.accentGold)
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
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
            
            Text("Product distribution by Category vs. Stock Health.")
                .font(.system(size: 13))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            
            // Dropdown for categories
            let categories = ["All"] + Array(Set(heatmapData.compactMap { $0.product?.category ?? "Other" })).sorted()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Filter by Category")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                
                Menu {
                    // Search bar inside the menu might not be fully native without custom views, but we can do a picker or custom approach. Wait, iOS 15+ allows Menu with primary action or we can just list them. The user wants "typing functionality too so they can type out their category too, with inline suggestions".
                    // Actually, native SwiftUI Menu doesn't support an embedded textfield easily. A better way is to use a Picker or a DisclosureGroup with a TextField, or maybe just a searchable sheet?
                    // "we can have a dropdown for selecting the categories... let's have typing functionality too" -> A button that shows a sheet or we can use a native Picker.
                    // Wait, let's use a standard Picker with searchable modifier if it's in a NavigationLink, or just a simple combo-box style. 
                    // Let's implement a custom dropdown or simply use a TextField with an inline list of suggestions.
                    
                    // Actually, I'll put a custom dropdown component right below this.
                } label: {
                    // Placeholder for now, I will fix this up in another replace call to avoid making this chunk too complex.
                    EmptyView()
                }
            }
            
            heatMapDropdown
            
            heatMapGrid
        }
    }
    
    @State private var isCategoryDropdownExpanded = false
    
    private var heatMapDropdown: some View {
        let filteredCategories = categorySearchText.isEmpty ? availableCategories : availableCategories.filter { $0.localizedCaseInsensitiveContains(categorySearchText) }
        
        return VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                withAnimation { isCategoryDropdownExpanded.toggle() }
            }) {
                HStack {
                    Text(selectedCategory)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isCategoryDropdownExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
                .padding()
                .background(RSMSTheme.Colors.backgroundElevated)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                )
            }
            
            if isCategoryDropdownExpanded {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(RSMSTheme.Colors.textTertiary)
                        TextField("Search category...", text: $categorySearchText)
                            .foregroundColor(.white)
                            .tint(RSMSTheme.Colors.accentGold)
                    }
                    .padding()
                    .background(RSMSTheme.Colors.backgroundPrimary)
                    
                    Divider().background(RSMSTheme.Colors.borderLight)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(filteredCategories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                    categorySearchText = ""
                                    withAnimation { isCategoryDropdownExpanded = false }
                                }) {
                                    Text(category)
                                        .foregroundColor(selectedCategory == category ? RSMSTheme.Colors.accentGold : .white)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                Divider().background(RSMSTheme.Colors.borderLight)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .background(RSMSTheme.Colors.backgroundElevated)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                )
            }
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
            let filteredCats = categories.filter { selectedCategory == "All" || $0 == selectedCategory }
            
            if filteredCats.isEmpty {
                Text("No data for selected category")
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .padding()
            } else {
                ForEach(filteredCats, id: \.self) { category in
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
