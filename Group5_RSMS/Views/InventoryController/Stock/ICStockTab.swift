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
    
    // Task 16 Extensions: Stock Checks
    @State private var upcomingChecks: [StockCheck] = []
    @State private var lastAuditDate: Date? = nil
    @State private var categorySchedules: [StockCheckSchedule] = []
    @State private var isLoadingChecks: Bool = false
    @State private var allCategories: [Category] = []
    @State private var isShowingScheduleSheet = false
    @State private var selectedCheckForCompletion: StockCheck? = nil
    
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
                        stockCheckSection
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
            .sheet(isPresented: $isShowingScheduleSheet) {
                ScheduleCheckSheet(categories: allCategories) { categoryId, date in
                    Task {
                        if let storeId = appState.currentStoreID {
                            try? await StockCheckService.shared.scheduleCheck(storeId: storeId, categoryId: categoryId, date: date)
                            await fetchUpcomingChecks()
                        }
                    }
                }
            }
            .sheet(item: $selectedCheckForCompletion) { check in
                CompleteAuditSheet(
                    check: check,
                    category: allCategories.first(where: { $0.id == check.category_id }),
                    schedule: categorySchedules.first(where: { $0.category_id == check.category_id }),
                    storeId: appState.currentStoreID ?? UUID()
                ) {
                    await fetchUpcomingChecks()
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
                    title: "Total SKUs",
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
            await appState.fetchTotalInventoryCount(storeId: appState.assignedStoreId)
            await fetchLowStock()
            await fetchLocalProductsCount()
            await fetchPendingRepairs()
            await fetchCategories()
            await fetchUpcomingChecks()
            
        }
    }
    
    private func fetchLowStock() async {
        isLoadingLowStock = true
        do {
            let alerts: [LowStockAlert]
            if let storeId = appState.assignedStoreId {
                alerts = try await LowStockService.shared.fetchLowStockAlerts(forStore: storeId)
            } else {
                alerts = try await LowStockService.shared.fetchAllLowStockAlerts()
            }
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
                        NavigationLink(destination: StockLevelsListView(localInventory: localInventory)) {
                            Text("See All")
                                .font(.footnote)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                    }
                }
                
                VStack(spacing: RSMSTheme.Spacing.sm) {
                    ForEach(Array(localInventory.prefix(3))) { item in
                        NavigationLink(destination: StockLevelsListView(localInventory: localInventory)) {
                            inventoryRow(for: item)
                        }
                        .buttonStyle(.plain)
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
    
    // MARK: - Stock Checks

    /// Dashboard preview: ALL overdue + ALL today's checks + next 3 upcoming.
    /// This ensures every category scheduled for today is always visible.
    private var smartChecks: [StockCheck] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Everything past-or-today (overdue + today), sorted oldest first
        let overdueAndToday = upcomingChecks
            .filter { calendar.startOfDay(for: $0.date) <= today }
            .sorted { $0.date < $1.date }

        // Future checks — show next 3 only (full list via "See All")
        let future = upcomingChecks
            .filter { calendar.startOfDay(for: $0.date) > today }
            .sorted { $0.date < $1.date }

        return overdueAndToday + Array(future.prefix(3))
    }

    @ViewBuilder
    private var stockCheckSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            HStack {
                Text("Scheduled Audits")
                    .font(.headline)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Spacer()
                // "See All" navigates to the full list
                NavigationLink(destination: AllStockChecksView(
                    checks: upcomingChecks,
                    categories: allCategories,
                    categorySchedules: categorySchedules
                )) {
                    Text("See All")
                        .font(.footnote)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
                .opacity(upcomingChecks.isEmpty ? 0 : 1)

                Button(action: { isShowingScheduleSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Schedule")
                    }
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }

            if isLoadingChecks {
                HStack {
                    Spacer()
                    ProgressView().tint(RSMSTheme.Colors.accentGold)
                    Spacer()
                }
                .padding()
            } else if upcomingChecks.isEmpty {
                VStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text("No upcoming checks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    Text("Tap '+' to schedule a manual audit.")
                        .font(.caption2)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, RSMSTheme.Spacing.xl)
                .cardStyle()
            } else {
                VStack(spacing: RSMSTheme.Spacing.sm) {
                    ForEach(smartChecks) { check in
                        let st = check.auditStatus
                        if st == .overdue || st == .today {
                            Button { selectedCheckForCompletion = check } label: {
                                stockCheckRow(for: check)
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(destination: AllStockChecksView(
                                checks: upcomingChecks,
                                categories: allCategories,
                                categorySchedules: categorySchedules
                            )) {
                                stockCheckRow(for: check)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
    
    private func stockCheckRow(for check: StockCheck) -> some View {
        let category = allCategories.first(where: { $0.id == check.category_id })
        let schedule = categorySchedules.first(where: { $0.category_id == check.category_id })
        let status   = check.auditStatus

        // Badge style per status
        let badgeFG: Color = {
            switch status {
            case .overdue:   return .white
            case .today:     return .black
            case .upcoming:  return RSMSTheme.Colors.accentGold
            case .completed: return RSMSTheme.Colors.success
            }
        }()
        let badgeBG: Color = {
            switch status {
            case .overdue:   return RSMSTheme.Colors.error
            case .today:     return RSMSTheme.Colors.accentGold
            case .upcoming:  return RSMSTheme.Colors.accentGold.opacity(0.15)
            case .completed: return RSMSTheme.Colors.success.opacity(0.15)
            }
        }()

        return HStack(spacing: RSMSTheme.Spacing.sm) {
            // Left icon accent
            RoundedRectangle(cornerRadius: 3)
                .fill(badgeBG.opacity(status == .today ? 1 : 0.7))
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "Audit Category")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(check.date.formatted(.dateTime.day().month().year()))
                    if let sched = schedule {
                        Text("·")
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text("Every \(sched.dayName)")
                            .foregroundStyle(RSMSTheme.Colors.accentGoldDark)
                    }
                }
                .font(.caption2)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()

            Text(status.label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(badgeFG)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeBG)
                .clipShape(Capsule())
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
                stockRow(label: "Total Inventory Units", value: "\(appState.totalInventoryCount)")
                stockRow(label: "Items Below Reorder Level", value: isLoadingLowStock ? "…" : "\(lowStockCount)")
                stockRow(label: "Last Audit Date", value: lastAuditDate?.formatted(.dateTime.month().day().year()) ?? "No Record")
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
                HStack {
                    Text("Currently In Repair")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Spacer()
                    if inRepairProducts.count > 3 {
                        NavigationLink(destination: ProductsListView(showOnlyInRepair: true)) {
                            Text("See All")
                                .font(.footnote)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                        }
                    }
                }
                
                VStack(spacing: RSMSTheme.Spacing.sm) {
                    ForEach(Array(inRepairProducts.prefix(3))) { product in
                        NavigationLink(destination: ProductsListView(showOnlyInRepair: true)) {
                            repairRow(for: product)
                        }
                        .buttonStyle(.plain)
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

    private func fetchCategories() async {
        isLoadingCategories = true
        do {
            let records: [Category] = try await SupabaseManager.shared.client
                .from("categories")
                .select("id, name")
                .execute()
                .value
            
            allCategories = records
            totalCategoriesCount = records.count
            
        } catch {
            print("Failed to fetch categories: \(error)")
        }
        isLoadingCategories = false
    }
    
    private func fetchUpcomingChecks() async {
        guard let storeId = appState.currentStoreID else { 
            print("🔍 StockCheck Debug: No currentStoreID found in AppState")
            return 
        }
        print("🔍 StockCheck Debug: Fetching for Store ID: \(storeId)")
        isLoadingChecks = true
        do {
            upcomingChecks = try await StockCheckService.shared.fetchUpcomingChecks(forStore: storeId)
            lastAuditDate = try await StockCheckService.shared.fetchLastAuditDate(forStore: storeId)
            categorySchedules = try await StockCheckService.shared.fetchSchedules(forStore: storeId)
            print("🔍 StockCheck Debug: Successfully fetched \(upcomingChecks.count) checks, last audit date & \(categorySchedules.count) schedules")
        } catch {
            print("❌ StockCheck Debug: Fetch Failed! Error: \(error)")
        }
        isLoadingChecks = false
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

// MARK: - Stock Levels List View (Searchable)
struct StockLevelsListView: View {
    @Environment(AppState.self) private var appState
    var localInventory: [ICStockTab.LocalInventoryRecord]
    
    @State private var searchText = ""
    
    var filteredInventory: [ICStockTab.LocalInventoryRecord] {
        if searchText.isEmpty {
            return localInventory
        }
        return localInventory.filter { item in
            if let product = appState.products.first(where: { $0.id == item.product_id }) {
                return product.name.localizedCaseInsensitiveContains(searchText) ||
                       product.sku.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
    }
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()
            
            if filteredInventory.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(filteredInventory) { item in
                        inventoryRow(for: item)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: RSMSTheme.Spacing.xs,
                                leading: RSMSTheme.Spacing.lg,
                                bottom: RSMSTheme.Spacing.xs,
                                trailing: RSMSTheme.Spacing.lg
                            ))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Stock Levels")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search by name or SKU")
    }
    
    private var emptyView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No products found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }
    
    private func inventoryRow(for item: ICStockTab.LocalInventoryRecord) -> some View {
        let product = appState.products.first(where: { $0.id == item.product_id })
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product?.name ?? "Loading...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text(product?.sku ?? "N/A")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.stock_quantity)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(item.stock_quantity <= 5 ? RSMSTheme.Colors.warning : RSMSTheme.Colors.textPrimary)
                Text("units")
                    .font(.caption2)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
        }
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}


// MARK: - All Stock Checks View (Full List)
struct AllStockChecksView: View {
    @Environment(AppState.self) private var appState
    var checks: [StockCheck]
    var categories: [Category]
    var categorySchedules: [StockCheckSchedule]

    @State private var searchText = ""

    private var filteredChecks: [StockCheck] {
        let sorted = checks.sorted { $0.date < $1.date }
        if searchText.isEmpty { return sorted }
        return sorted.filter { check in
            let catName = categories.first(where: { $0.id == check.category_id })?.name ?? ""
            return catName.localizedCaseInsensitiveContains(searchText)
                || check.status.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if filteredChecks.isEmpty {
                VStack(spacing: RSMSTheme.Spacing.lg) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text("No audits found")
                        .font(.headline)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            } else {
                List {
                    ForEach(filteredChecks) { check in
                        auditRow(for: check)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: RSMSTheme.Spacing.xs,
                                leading: RSMSTheme.Spacing.lg,
                                bottom: RSMSTheme.Spacing.xs,
                                trailing: RSMSTheme.Spacing.lg
                            ))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("All Scheduled Audits")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search by category or status")
    }

    private func auditRow(for check: StockCheck) -> some View {
        let category = categories.first(where: { $0.id == check.category_id })
        let schedule = categorySchedules.first(where: { $0.category_id == check.category_id })
        let status   = check.auditStatus

        let badgeFG: Color = {
            switch status {
            case .overdue:   return .white
            case .today:     return .black
            case .upcoming:  return RSMSTheme.Colors.accentGold
            case .completed: return RSMSTheme.Colors.success
            }
        }()
        let badgeBG: Color = {
            switch status {
            case .overdue:   return RSMSTheme.Colors.error
            case .today:     return RSMSTheme.Colors.accentGold
            case .upcoming:  return RSMSTheme.Colors.accentGold.opacity(0.15)
            case .completed: return RSMSTheme.Colors.success.opacity(0.15)
            }
        }()

        return HStack(spacing: RSMSTheme.Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(badgeBG.opacity(status == .today ? 1 : 0.7))
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "Audit Category")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(check.date.formatted(.dateTime.day().month().year()))
                    if let sched = schedule {
                        Text("·").foregroundStyle(RSMSTheme.Colors.textTertiary)
                        Text("Every \(sched.dayName)")
                            .foregroundStyle(RSMSTheme.Colors.accentGoldDark)
                    }
                }
                .font(.caption2)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }
            Spacer()

            Text(status.label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(badgeFG)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(badgeBG)
                .clipShape(Capsule())
        }
        .padding(RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(status == .today ? RSMSTheme.Colors.accentGold.opacity(0.4) : RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}

// MARK: - Schedule Check Sheet
struct ScheduleCheckSheet: View {
    @Environment(\.dismiss) private var dismiss
    let categories: [Category]
    let onSchedule: (UUID, Date) -> Void
    
    @State private var selectedCategoryId: UUID?
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: RSMSTheme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                        Text("Category")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        
                        Picker("Select Category", selection: $selectedCategoryId) {
                            Text("Select a category").tag(Optional<UUID>.none)
                            ForEach(categories) { cat in
                                Text(cat.name).tag(Optional(cat.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                    }
                    
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                        Text("Audit Date")
                            .font(.subheadline)
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(RSMSTheme.Colors.accentGold)
                            .padding()
                            .background(RSMSTheme.Colors.backgroundElevated)
                            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                    }
                    
                    Spacer()
                    
                    Button {
                        if let catId = selectedCategoryId {
                            onSchedule(catId, selectedDate)
                            dismiss()
                        }
                    } label: {
                        Text("Confirm Schedule")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GoldButtonStyle())
                    .disabled(selectedCategoryId == nil)
                    .opacity(selectedCategoryId == nil ? 0.6 : 1.0)
                }
                .padding(RSMSTheme.Spacing.lg)
            }
            .navigationTitle("Manual Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Complete Audit Sheet
/// Presented when an IC taps an Overdue or Today check row.
/// Step 1: Confirm completion.  Step 2 (optional): Enter actual stock counts and log discrepancies.
struct CompleteAuditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let check: StockCheck
    let category: Category?
    let schedule: StockCheckSchedule?
    let storeId: UUID
    let onCompleted: () async -> Void

    // MARK: State
    @State private var step: Int = 1
    @State private var isMarkingComplete = false

    // Step 2 — product count entry
    @State private var products: [StockCheckService.CategoryProduct] = []
    @State private var inventoryMap: [UUID: Int] = [:]          // productId → system qty
    @State private var actualCounts: [UUID: Int] = [:]          // productId → IC entry
    @State private var isLoadingProducts = false
    @State private var isSubmitting = false
    @State private var submissionResult: SubmissionResult? = nil

    enum SubmissionResult { case allMatch; case mismatch(Int) }

    // MARK: Body
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                Group {
                    if step == 1 { step1View }
                    else         { step2View  }
                }
            }
            .navigationTitle(step == 1 ? "Complete Audit" : "Enter Stock Count")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(step == 1 ? "Cancel" : "Skip") {
                        if step == 2 { step = 1 } else { dismiss() }
                    }
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: Step 1 — Confirm Completion
    private var step1View: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {

            // Check summary card
            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                    Text(category?.name ?? "Audit Category")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                }
                Divider().background(RSMSTheme.Colors.borderLight)
                infoRow(label: "Scheduled Date", value: check.date.formatted(.dateTime.day().month(.wide).year()))
                if let sched = schedule {
                    infoRow(label: "Recurring", value: "Every \(sched.dayName)")
                }
                infoRow(label: "Status", value: check.auditStatus.label)
            }
            .padding(RSMSTheme.Spacing.lg)
            .background(RSMSTheme.Colors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))

            Spacer()

            VStack(spacing: RSMSTheme.Spacing.sm) {
                // Primary: mark complete then go to count entry
                Button {
                    Task { await markComplete(thenGoToStep2: true) }
                } label: {
                    HStack {
                        if isMarkingComplete { ProgressView().tint(.black) }
                        Text(isMarkingComplete ? "Marking…" : "Mark as Completed")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(isMarkingComplete)

                // Secondary: just close after marking done (skip count)
                Button("Mark as Completed & Close") {
                    Task { await markComplete(thenGoToStep2: false) }
                }
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .disabled(isMarkingComplete)
            }
        }
        .padding(RSMSTheme.Spacing.lg)
    }

    // MARK: Step 2 — Count Entry
    private var step2View: some View {
        VStack(spacing: 0) {
            if isLoadingProducts {
                Spacer()
                ProgressView("Loading products…").tint(RSMSTheme.Colors.accentGold)
                Spacer()
            } else if products.isEmpty {
                Spacer()
                VStack(spacing: RSMSTheme.Spacing.md) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    Text("No products found in this category.")
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                Spacer()
            } else if let result = submissionResult {
                resultView(result)
            } else {
                // Product list
                List {
                    Section {
                        ForEach(products) { product in
                            countRow(for: product)
                                .listRowBackground(RSMSTheme.Colors.backgroundElevated)
                                .listRowSeparatorTint(RSMSTheme.Colors.borderLight)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Physical Count Entry")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                            Text("'Expected' = what your system shows. Use +/− to enter your actual physical count.")
                                .font(.caption2)
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        }
                        .textCase(nil)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                // Submit button
                Button {
                    Task { await submitCounts() }
                } label: {
                    HStack {
                        if isSubmitting { ProgressView().tint(.black) }
                        Text(isSubmitting ? "Submitting…" : "Submit Count")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GoldButtonStyle())
                .disabled(isSubmitting)
                .padding(RSMSTheme.Spacing.lg)
            }
        }
    }

    // MARK: Count Row
    private func countRow(for product: StockCheckService.CategoryProduct) -> some View {
        let systemQty = inventoryMap[product.id] ?? 0
        let actualQty = actualCounts[product.id] ?? systemQty
        let mismatch  = actualQty != systemQty

        return VStack(spacing: RSMSTheme.Spacing.sm) {
            // Product name
            HStack {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Spacer()
                if mismatch {
                    Text("Mismatch")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RSMSTheme.Colors.warning)
                        .clipShape(Capsule())
                }
            }

            // Expected vs Your Count side by side
            HStack(spacing: RSMSTheme.Spacing.md) {
                // Expected (from system)
                VStack(spacing: 2) {
                    Text("\(systemQty)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    Text("Expected\n(in system)")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, RSMSTheme.Spacing.sm)
                .background(RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))

                // Your physical count (editable)
                VStack(spacing: 2) {
                    Text("\(actualQty)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(mismatch ? RSMSTheme.Colors.warning : RSMSTheme.Colors.textPrimary)
                    Text("Your Count\n(physical)")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, RSMSTheme.Spacing.sm)
                .background(mismatch ? RSMSTheme.Colors.warning.opacity(0.1) : RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                        .stroke(mismatch ? RSMSTheme.Colors.warning.opacity(0.4) : Color.clear, lineWidth: 1)
                )
            }

            // Stepper to adjust count
            Stepper(
                "Adjust count",
                value: Binding(
                    get: { actualCounts[product.id] ?? systemQty },
                    set: { actualCounts[product.id] = $0 }
                ),
                in: 0...9999
            )
            .labelsHidden()
        }
        .padding(.vertical, RSMSTheme.Spacing.xs)
    }

    // MARK: Result View
    private func resultView(_ result: SubmissionResult) -> some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            Spacer()
            switch result {
            case .allMatch:
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                Text("All counts match!")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("No discrepancies found.")
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)

            case .mismatch(let count):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(RSMSTheme.Colors.warning)
                Text("\(count) discrepanc\(count == 1 ? "y" : "ies") found")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                Text("Logged in inventory discrepancies.\nA manager can review and approve adjustments.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
            }

            Spacer()
            Button("Done") { dismiss() }
                .frame(maxWidth: .infinity)
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.bottom, RSMSTheme.Spacing.lg)
        }
    }

    // MARK: Helpers
    private func infoRow(label: String, value: String) -> some View {
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
    }

    // MARK: Actions
    private func markComplete(thenGoToStep2: Bool) async {
        isMarkingComplete = true
        do {
            try await StockCheckService.shared.markAsCompleted(checkId: check.id)
            await onCompleted()
        } catch {
            print("❌ markAsCompleted error: \(error)")
        }
        isMarkingComplete = false

        if thenGoToStep2 {
            step = 2
            await loadProducts()
        } else {
            dismiss()
        }
    }

    private func loadProducts() async {
        isLoadingProducts = true
        do {
            async let productsResult  = StockCheckService.shared.fetchCategoryProducts(categoryId: check.category_id)
            async let inventoryResult = StockCheckService.shared.fetchStoreInventoryMap(storeId: storeId)
            let (prods, invMap) = try await (productsResult, inventoryResult)
            products     = prods
            inventoryMap = invMap
            // Pre-fill actual counts with system quantities (IC adjusts where different)
            for p in prods {
                actualCounts[p.id] = invMap[p.id] ?? 0
            }
        } catch {
            print("❌ loadProducts error: \(error)")
        }
        isLoadingProducts = false
    }

    private func submitCounts() async {
        isSubmitting = true
        var payloads: [DiscrepancyPayload] = []
        for product in products {
            let systemQty = inventoryMap[product.id] ?? 0
            let actual    = actualCounts[product.id] ?? systemQty
            if actual != systemQty {
                payloads.append(DiscrepancyPayload(
                    product_id:             product.id,
                    store_id:               storeId,
                    expected_quantity:      systemQty,
                    actual_scanned_quantity: actual,
                    created_by:             appState.managerAuthId
                ))
            }
        }
        do {
            try await StockCheckService.shared.submitDiscrepancies(payloads)
            submissionResult = payloads.isEmpty ? .allMatch : .mismatch(payloads.count)
        } catch {
            print("❌ submitDiscrepancies error: \(error)")
        }
        isSubmitting = false
    }
}
