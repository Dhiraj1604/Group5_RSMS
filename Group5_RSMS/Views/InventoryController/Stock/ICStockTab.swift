//
//  ICStockTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Stock Overview tab (Task 16).
//  Displays stock level summary cards, low-stock alerts,
//  and warehouse metrics. Serves as the primary landing tab.
//

import SwiftUI
import PostgREST
import Supabase

struct ICStockTab: View {
    @Environment(AppState.self) private var appState
    @State private var totalCategoriesCount: Int = 0
    @State private var isLoadingCategories: Bool = false
    @State private var showProductsList = false
    @State private var lowStockCount: Int = 0
    @State private var isLoadingLowStock: Bool = false
    @State private var pendingRepairs: [LocalRepairRecord] = []
    @State private var localProductsCount: Int = 0
    @State private var isLoadingLocalProducts: Bool = false
    @State private var localInventory: [LocalInventoryRecord] = []
    @State private var showAllInventory: Bool = false
    
    struct LocalInventoryRecord: Decodable, Identifiable {
        let product_id: UUID
        let stock_quantity: Int
        var id: UUID { product_id }
    }
    
    struct LocalRepairRecord: Decodable {
        let product_id: UUID
        let sent_at: String
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: RSMSTheme.Spacing.xl) {
                        stockKPISection
                        stockDetailsSection
                        localInventorySection
                        repairTrackingSection
                        Spacer().frame(height: RSMSTheme.Spacing.xxl)
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                }
            }
            .navigationTitle(appState.stores.first(where: { $0.id == appState.currentStoreID })?.name ?? "Stock")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            appState.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                    }
                }
            }
        }
    }
    
    // MARK: - Stock KPIs
    
    private var stockKPISection: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            // Total Items — tappable, navigates to ProductsListView
            NavigationLink(destination: ProductsListView()) {
                stockKPICard(
                    title: "Total Items",
                    value: isLoadingLocalProducts
                    ? "…"
                    : "\(localProductsCount)",
                    icon: "shippingbox.fill",
                    color: RSMSTheme.Colors.accentGold
                )
            }
            .buttonStyle(.plain)
            
            NavigationLink(destination: ProductsListView(showOnlyInRepair: true)) {
                stockKPICard(
                    title: "In Repair",
                    value: appState.isLoadingProducts ? "…" : "\(appState.products.filter { $0.inRepair }.count)",
                    icon: "wrench.and.screwdriver.fill",
                    color: .orange
                )
            }
            .buttonStyle(.plain)
        }
        .task {
            if appState.stores.isEmpty {
                await appState.loadStores()
            }
            await appState.fetchProducts()
            await appState.fetchTotalInventoryCount()
            await fetchLowStock()
            await fetchLocalProductsCount()
            await fetchPendingRepairs()
            await fetchCategoriesCount()
            
        }
    }
    
    private func fetchLowStock() async {
        isLoadingLowStock = true
        do {
            let alerts = try await LowStockService.shared.fetchAllLowStockAlerts()
            lowStockCount = alerts.count
        } catch {
            print("Failed to fetch low stock alerts: \(error)")
        }
        isLoadingLowStock = false
    }
    
    
    private func stockKPICard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Local Inventory List
    
    @ViewBuilder
    private var localInventorySection: some View {
        if !localInventory.isEmpty {
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                HStack {
                    Text("Stock Levels")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Spacer()
                    if localInventory.count > 3 {
                        Button(action: {
                            withAnimation { showAllInventory.toggle() }
                        }) {
                            Text(showAllInventory ? "Show Less" : "See All")
                                .font(.footnote)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                    }
                }
                
                VStack(spacing: RSMSTheme.Spacing.sm) {
                    let displayedItems = showAllInventory ? localInventory : Array(localInventory.prefix(3))
                    
                    ForEach(displayedItems) { item in
                        inventoryRow(for: item)
                    }
                }
            }
        }
    }
    
    private func inventoryRow(for item: LocalInventoryRecord) -> some View {
        let product = appState.products.first(where: { $0.id == item.product_id })
        
        return HStack {
            VStack(alignment: .leading) {
                Text(product?.name ?? "Loading...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(product?.sku ?? "N/A")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(item.stock_quantity)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(item.stock_quantity <= 5 ? RSMSTheme.Colors.warning : RSMSTheme.Colors.textPrimary)
                Text("units")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
        }
        .cardStyle()
    }
    
    // MARK: - Stock Details
    
    private var stockDetailsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Warehouse Overview")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            VStack(spacing: RSMSTheme.Spacing.sm) {
                stockRow(label: "Total SKUs Tracked", value: isLoadingLocalProducts ? "…" : "\(localProductsCount)")
                stockRow(label: "Total Inventory Units", value: "\(appState.totalInventoryCount)")
                stockRow(label: "Items Below Reorder Level", value: isLoadingLowStock ? "…" : "\(lowStockCount)")
                stockRow(label: "Last Audit Date", value: Date().formatted(.dateTime.month().day().year()))
            }
            .cardStyle()
        }
    }
    
    private func stockRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
        .padding(.vertical, RSMSTheme.Spacing.xs)
    }
    
    // MARK: - Repair Tracking
    
    @ViewBuilder
    private var repairTrackingSection: some View {
        let inRepairProducts = appState.products.filter { $0.inRepair }
        
        if !inRepairProducts.isEmpty {
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                Text("Currently In Repair")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                
                VStack(spacing: RSMSTheme.Spacing.sm) {
                    ForEach(inRepairProducts) { product in
                        repairRow(for: product)
                    }
                }
            }
        }
    }
    
    private func repairRow(for product: Product) -> some View {
        let repairRecord = pendingRepairs.first(where: { $0.product_id == product.id })
        
        // Calculate days passed since it was sent
        let daysInRepair: Int? = {
            if let dateString = repairRecord?.sent_at,
               let sentDate = ISO8601DateFormatter().date(from: dateString) {
                return Calendar.current.dateComponents([.day], from: sentDate, to: Date()).day
            }
            return nil
        }()
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(product.sku)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let days = daysInRepair {
                    Text("\(days) \(days == 1 ? "day" : "days")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(days > 7 ? RSMSTheme.Colors.warning : RSMSTheme.Colors.accentGoldLight)
                } else {
                    Text("...")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                Text("in repair")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
        }
        .cardStyle()
    }

    private func fetchCategoriesCount() async {
        isLoadingCategories = true
        do {
            struct CategoryRecord: Decodable {
                let id: UUID
            }
            
            let records: [CategoryRecord] = try await SupabaseManager.shared.client
                .from("categories")
                .select("id")
                .execute()
                .value
            
            totalCategoriesCount = records.count
            
        } catch {
            print("Failed to fetch categories count: \(error)")
        }
        isLoadingCategories = false
    }
    
    private func fetchPendingRepairs() async {
        do {
            let records: [LocalRepairRecord] = try await SupabaseManager.shared.client
                .from("repair")
                .select("product_id, sent_at")
                .eq("status", value: "Pending")
                .execute()
                .value
            
            pendingRepairs = records
        } catch {
            print("Failed to fetch pending repairs: \(error)")
        }
    }
    
    private func fetchLocalProductsCount() async {
        isLoadingLocalProducts = true
        do {
            if let storeId = appState.currentStoreID {
                let records: [LocalInventoryRecord] = try await SupabaseManager.shared.client
                    .from("inventory")
                    .select("product_id, stock_quantity")
                    .eq("store_id", value: storeId)
                    .order("stock_quantity", ascending: false)
                    .execute()
                    .value
                
                localInventory = records
                localProductsCount = records.count
            } else {
                localProductsCount = 0
                localInventory = []
            }
        } catch {
            print("Failed to fetch local inventory count: \(error)")
        }
        isLoadingLocalProducts = false
    }
    
}

#Preview {
    ICStockTab()
        .environment(AppState())
}
