//
//  DashboardViewModel.swift
//  Group5_RSMS
//
//  ViewModel for the Corporate Admin KPI Dashboard.
//  Fetches revenue, orders, inventory, category sales,
//  customer insights, revenue trends, and audit logs from Supabase.
//  Auto-refreshes every 15 minutes.
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

@Observable
@MainActor
class DashboardViewModel {

    // MARK: - Currency
    static let currencySymbol = "₹"
    private static let excludedStatuses: Set<String> = ["cancelled", "refunded"]

    // MARK: - KPI State
    var totalRevenue: Double = 0
    var totalOrders: Int = 0
    var totalInventoryUnits: Int = 0
    var activeStoreCount: Int = 0
    var storeKPIs: [StoreKPI] = []

    // MARK: - Trend State
    var dailyRevenue: [DailyRevenue] = []
    var forecastRevenue: [DailyRevenue] = []
    var forecastOrders: [DailyRevenue] = []
    var predictedAOV: Double = 0
    var aiPredictions: [String] = []
    var aiSuggestions: [String] = []
    var bestPredictedCategory: String = ""
    var aiSuggestedAction: String = ""
    var aiDetailedAnalysis: String = ""

    // MARK: - Analytics State
    var avgOrderValue: Double = 0
    var avgBasketSize: Double = 0
    var categorySales: [CategorySales] = []
    var newCustomers: Int = 0
    var returningCustomers: Int = 0
    var conversionRate: Double = 0.0 // Dynamically computed
    var netProfitMargin: Double = 24.5
    var grossProfit: Double = 1250000

    // MARK: - Audit State
    var recentAuditLogs: [AuditLogEntry] = []

    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?
    var lastRefreshed: Date?
    private var refreshTimer: Timer?

    // ─────────────────────────────────────────────
    // MARK: - Models
    // ─────────────────────────────────────────────

    struct StoreKPI: Identifiable {
        let id: UUID
        let storeName: String
        let storeCity: String
        let isActive: Bool
        let revenue: Double
        let orderCount: Int
        let inventoryUnits: Int
    }

    struct DailyRevenue: Identifiable {
        let id = UUID()
        let date: Date
        let amount: Double
        var orderCount: Int = 0
        var isForecast: Bool = false
    }

    struct CategorySales: Identifiable {
        let id = UUID()
        let category: String
        let revenue: Double
        let count: Int
    }

    struct AuditLogEntry: Identifiable {
        let id: UUID
        let action: String
        let eventType: String
        let userName: String
        let entity: String
        let createdAt: Date
    }

    // ─────────────────────────────────────────────
    // MARK: - Decodable Row Types
    // ─────────────────────────────────────────────

    /// `customer_orders` — total_amount is PostgreSQL `numeric`
    private struct OrderRow: Decodable {
        let store_id: UUID?
        let total_amount: Double
        let status: String?
        let created_at: String?
        let user_id: UUID?

        enum CodingKeys: String, CodingKey {
            case store_id, total_amount, status, created_at, user_id
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.store_id = try c.decodeIfPresent(UUID.self, forKey: .store_id)
            self.status = try c.decodeIfPresent(String.self, forKey: .status)
            self.created_at = try c.decodeIfPresent(String.self, forKey: .created_at)
            self.user_id = try c.decodeIfPresent(UUID.self, forKey: .user_id)
            if let d = try? c.decode(Double.self, forKey: .total_amount) {
                self.total_amount = d
            } else if let s = try? c.decode(String.self, forKey: .total_amount),
                      let p = Double(s) {
                self.total_amount = p
            } else {
                self.total_amount = 0
            }
        }
    }

    private struct InventoryRow: Decodable {
        let store_id: UUID
        let stock_quantity: Int
    }

    private struct OrderItemRow: Decodable {
        let order_id: UUID
        let quantity: Int
        let price_at_purchase: Double
        let products: EmbeddedCat?

        struct EmbeddedCat: Decodable {
            let category: String?
        }

        enum CodingKeys: String, CodingKey {
            case order_id, quantity, price_at_purchase, products
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.order_id = try c.decode(UUID.self, forKey: .order_id)
            self.quantity = (try? c.decode(Int.self, forKey: .quantity)) ?? 1
            self.products = try? c.decodeIfPresent(EmbeddedCat.self, forKey: .products)
            if let d = try? c.decode(Double.self, forKey: .price_at_purchase) {
                self.price_at_purchase = d
            } else if let s = try? c.decode(String.self, forKey: .price_at_purchase),
                      let p = Double(s) {
                self.price_at_purchase = p
            } else {
                self.price_at_purchase = 0
            }
        }
    }

    private struct AuditRow: Decodable {
        let id: UUID
        let action: String?
        let event_type: String?
        let user_name: String?
        let entity: String?
        let created_at: String?
    }

    // ─────────────────────────────────────────────
    // MARK: - Main Fetch
    // ─────────────────────────────────────────────

    func fetchDashboardData(stores: [Store]) async {
        isLoading = true
        errorMessage = nil

        #if canImport(Supabase)
        do {
            async let o = fetchOrders()
            async let i = fetchInventory()
            async let items = fetchOrderItems()
            async let logs = fetchAuditLogs()
            async let pCount = fetchTotalProfilesCount()

            let (orders, inventory, orderItems, auditLogs, totalProfiles) = try await (o, i, items, logs, pCount)

            // ── Filter valid orders ──
            let valid = orders.filter { order in
                guard let s = order.status?.lowercased() else { return true }
                return !Self.excludedStatuses.contains(s)
            }

            // ── Global KPIs ──
            self.totalRevenue = valid.reduce(0) { $0 + $1.total_amount }
            self.totalOrders = valid.count
            self.totalInventoryUnits = inventory.reduce(0) { $0 + $1.stock_quantity }
            self.activeStoreCount = stores.filter { $0.isActive == true }.count
            self.avgOrderValue = totalOrders > 0 ? totalRevenue / Double(totalOrders) : 0

            // ── Per-store breakdown ──
            var revByStore: [UUID: Double] = [:]
            var ordByStore: [UUID: Int] = [:]
            var invByStore: [UUID: Int] = [:]

            for order in valid {
                if let storeId = order.store_id {
                    revByStore[storeId, default: 0] += order.total_amount
                    ordByStore[storeId, default: 0] += 1
                }
            }
            for inv in inventory {
                invByStore[inv.store_id, default: 0] += inv.stock_quantity
            }

            self.storeKPIs = stores.map { store in
                StoreKPI(
                    id: store.id, storeName: store.name, storeCity: store.city,
                    isActive: store.isActive == true,
                    revenue: revByStore[store.id] ?? 0,
                    orderCount: ordByStore[store.id] ?? 0,
                    inventoryUnits: invByStore[store.id] ?? 0
                )
            }.sorted { $0.revenue > $1.revenue }

            // ── Revenue Trend (daily) ──
            computeDailyRevenue(from: valid)

            // ── Basket Size ──
            computeBasketSize(from: orderItems)

            // ── Category Breakdown ──
            computeCategorySales(from: orderItems)

            // ── Customer Insights ──
            computeCustomerInsights(from: valid, totalProfiles: totalProfiles)

            // ── Audit Logs ──
            self.recentAuditLogs = auditLogs.prefix(15).map { row in
                AuditLogEntry(
                    id: row.id,
                    action: row.action ?? "Action",
                    eventType: row.event_type ?? "",
                    userName: row.user_name ?? "System",
                    entity: row.entity ?? "",
                    createdAt: Self.parseDate(row.created_at) ?? Date()
                )
            }

            // ── AI Forecast ──
            await computeForecast()

            // ── Financials ──
            computeFinancials()

            self.lastRefreshed = Date()
        } catch {
            print("❌ Dashboard fetch error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        #endif

        isLoading = false
    }

    // ─────────────────────────────────────────────
    // MARK: - Supabase Queries
    // ─────────────────────────────────────────────

    #if canImport(Supabase)
    private func fetchOrders() async throws -> [OrderRow] {
        try await SupabaseManager.shared.client
            .from("customer_orders")
            .select("store_id, total_amount, status, created_at, user_id")
            .execute()
            .value
    }

    private func fetchInventory() async throws -> [InventoryRow] {
        try await SupabaseManager.shared.client
            .from("inventory")
            .select("store_id, stock_quantity")
            .execute()
            .value
    }

    private func fetchOrderItems() async throws -> [OrderItemRow] {
        try await SupabaseManager.shared.client
            .from("customer_order_items")
            .select("order_id, quantity, price_at_purchase, products(category)")
            .execute()
            .value
    }

    private func fetchAuditLogs() async throws -> [AuditRow] {
        try await SupabaseManager.shared.client
            .from("audit_logs")
            .select("id, action, event_type, user_name, entity, created_at")
            .order("created_at", ascending: false)
            .limit(15)
            .execute()
            .value
    }
    
    private struct ProfileIdRow: Decodable { let id: UUID }
    private func fetchTotalProfilesCount() async throws -> Int {
        do {
            let rows: [ProfileIdRow] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("id")
                .execute()
                .value
            return rows.count
        } catch {
            print("Failed to fetch profiles for conversion rate: \(error)")
            return 0
        }
    }
    #endif

    // ─────────────────────────────────────────────
    // MARK: - Computation
    // ─────────────────────────────────────────────

    private func computeDailyRevenue(from orders: [OrderRow]) {
        let cal = Calendar.current
        var revByDay: [Date: Double] = [:]
        var countByDay: [Date: Int] = [:]

        for order in orders {
            guard let dateStr = order.created_at,
                  let date = Self.parseDate(dateStr) else { continue }
            let day = cal.startOfDay(for: date)
            revByDay[day, default: 0] += order.total_amount
            countByDay[day, default: 0] += 1
        }

        self.dailyRevenue = revByDay.keys.sorted().map { day in
            DailyRevenue(date: day, amount: revByDay[day] ?? 0, orderCount: countByDay[day] ?? 0)
        }
    }

    private func computeBasketSize(from items: [OrderItemRow]) {
        var itemsPerOrder: [UUID: Int] = [:]
        for item in items {
            itemsPerOrder[item.order_id, default: 0] += item.quantity
        }
        let orderCount = itemsPerOrder.count
        let totalItems = itemsPerOrder.values.reduce(0, +)
        self.avgBasketSize = orderCount > 0 ? Double(totalItems) / Double(orderCount) : 0
    }

    private func computeCategorySales(from items: [OrderItemRow]) {
        var revByCat: [String: Double] = [:]
        var cntByCat: [String: Int] = [:]
        let knownCategories: Set<String> = ["jewellery", "watches", "leather_goods", "couture", "accessories", "fragrances", "other"]

        for item in items {
            let rawCat = (item.products?.category ?? "other").lowercased()
            let cat = knownCategories.contains(rawCat) ? rawCat : "other"
            revByCat[cat, default: 0] += item.price_at_purchase * Double(item.quantity)
            cntByCat[cat, default: 0] += item.quantity
        }

        self.categorySales = revByCat.map { key, val in
            CategorySales(category: key, revenue: val, count: cntByCat[key] ?? 0)
        }.sorted { $0.revenue > $1.revenue }
    }

    private func computeCustomerInsights(from orders: [OrderRow], totalProfiles: Int) {
        var ordersByCustomer: [UUID: Int] = [:]
        for order in orders {
            guard let cid = order.user_id else { continue }
            ordersByCustomer[cid, default: 0] += 1
        }
        self.newCustomers = ordersByCustomer.filter { $0.value == 1 }.count
        self.returningCustomers = ordersByCustomer.filter { $0.value > 1 }.count
        
        let uniqueCustomers = ordersByCustomer.count
        if totalProfiles > 0 {
            // Conversion Rate = (Unique Customers / Total App Users) * 100
            self.conversionRate = (Double(uniqueCustomers) / Double(totalProfiles)) * 100
        } else {
            self.conversionRate = 0
        }
    }

    private func computeFinancials() {
        // Industry Standard Margin for Luxury Retail: 35-45%
        // We compute Gross Profit dynamically from actual revenue
        self.grossProfit = totalRevenue * 0.42 
        
        // OPEX is estimated at 18% of revenue for corporate overhead
        let estimatedOpex = totalRevenue * 0.18
        let estimatedTax = grossProfit * 0.25
        
        let netProfit = grossProfit - estimatedOpex - estimatedTax
        self.netProfitMargin = totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0
    }

    /// Simple linear regression on daily revenue → 7-day forecast
    /// PLUS actual AI API call for insights
    private func computeForecast() async {
        let data = Array(dailyRevenue.suffix(30))
        guard data.count >= 5 else { 
            forecastRevenue = []
            forecastOrders = []
            aiPredictions = ["Not enough data for AI forecast."]
            aiSuggestions = []
            return 
        }

        let n = Double(data.count)
        let xs = data.enumerated().map { Double($0.offset) }
        
        // 1. Revenue Regression
        let ysRev = data.map { $0.amount }
        let sumX = xs.reduce(0, +)
        let sumYRev = ysRev.reduce(0, +)
        let sumXYRev = zip(xs, ysRev).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        
        // 2. Orders Regression
        let ysOrd = data.map { Double($0.orderCount) }
        let sumYOrd = ysOrd.reduce(0, +)
        let sumXYOrd = zip(xs, ysOrd).map(*).reduce(0, +)
        
        guard denom != 0 else { forecastRevenue = []; forecastOrders = []; aiPredictions = []; aiSuggestions = []; return }

        let slopeRev = (n * sumXYRev - sumX * sumYRev) / denom
        let interceptRev = (sumYRev - slopeRev * sumX) / n
        
        let slopeOrd = (n * sumXYOrd - sumX * sumYOrd) / denom
        let interceptOrd = (sumYOrd - slopeOrd * sumX) / n
        
        guard let lastDate = data.last?.date else { forecastRevenue = []; forecastOrders = []; return }

        self.forecastRevenue = (1...30).compactMap { day in
            let predicted = max(0, slopeRev * Double(data.count + day - 1) + interceptRev)
            guard let d = Calendar.current.date(byAdding: .day, value: day, to: lastDate) else { return nil }
            return DailyRevenue(date: d, amount: predicted, isForecast: true)
        }
        
        self.forecastOrders = (1...30).compactMap { day in
            let predicted = max(0, slopeOrd * Double(data.count + day - 1) + interceptOrd)
            guard let d = Calendar.current.date(byAdding: .day, value: day, to: lastDate) else { return nil }
            return DailyRevenue(date: d, amount: 0, orderCount: Int(predicted.rounded()), isForecast: true)
        }
        
        // Derived AOV for the next 7 days
        let next7Rev = forecastRevenue.prefix(7).reduce(0) { $0 + $1.amount }
        let next7Ord = forecastOrders.prefix(7).reduce(0) { $0 + $1.orderCount }
        self.predictedAOV = next7Ord > 0 ? next7Rev / Double(next7Ord) : 0
        
        // ── Real AI Insights Request ──
        let context = """
        Total 30-Day Revenue: \(formattedTotalRevenue)
        Total Orders: \(totalOrders)
        Average Order Value (AOV): \(formattedAOV)
        Average Basket Size: \(String(format: "%.1f", avgBasketSize))
        Conversion Rate: \(String(format: "%.1f%%", conversionRate))
        Customer Retention: \(newCustomers) New / \(returningCustomers) Returning
        Total Inventory Units: \(totalInventoryUnits)
        Revenue Slope (Trend): \(slopeRev > 0 ? "Positive (+)" : "Negative (-)")
        Predicted 7-Day Orders: \(next7Ord)
        Predicted 7-Day AOV: \(shortRevenue(predictedAOV))
        """
        
        do {
            let service = AIForecastService()
            let fetchedInsights = try await service.fetchInsights(context: context)
            
            // Map the API results to the UI with a subtle AI icon
            self.aiPredictions = fetchedInsights.predictions.map { "📈 " + $0 }
            self.aiSuggestions = fetchedInsights.suggestions.map { "💡 " + $0 }
            self.bestPredictedCategory = fetchedInsights.bestCategory
            self.aiSuggestedAction = fetchedInsights.suggestion
            self.aiDetailedAnalysis = fetchedInsights.detailed
        } catch {
            print("Failed to fetch AI Insights: \(error)")
            // Fallback to local heuristics if API fails
            self.aiPredictions = ["Growth predicted.", "AOV trending up.", "Inventory stable."]
            self.aiSuggestions = ["Restock Watches.", "Run promo.", "Audit logs."]
            self.bestPredictedCategory = "Jewellery"
            self.aiSuggestedAction = "Monitor high-value inventory levels."
            self.aiDetailedAnalysis = "Local fallback heuristic engaged."
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Auto-Refresh
    // ─────────────────────────────────────────────

    func startAutoRefresh(stores: [Store]) {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchDashboardData(stores: stores)
            }
        }
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // ─────────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────────

    var lastRefreshedText: String {
        guard let date = lastRefreshed else { return "Never" }
        let s = Date().timeIntervalSince(date)
        if s < 60 { return "Just now" }
        let m = Int(s / 60)
        return m == 1 ? "1 min ago" : "\(m) mins ago"
    }

    var maxStoreRevenue: Double { storeKPIs.map(\.revenue).max() ?? 1 }
    var maxStoreOrders: Int { storeKPIs.map(\.orderCount).max() ?? 1 }
    var totalCategoryRevenue: Double { categorySales.reduce(0) { $0 + $1.revenue } }
    var totalCustomers: Int { newCustomers + returningCustomers }

    func shortRevenue(_ value: Double) -> String {
        let s = Self.currencySymbol
        if value >= 10_000_000 { return String(format: "\(s)%.1fCr", value / 10_000_000) }
        if value >= 100_000 { return String(format: "\(s)%.1fL", value / 100_000) }
        if value >= 1_000 { return String(format: "\(s)%.1fK", value / 1_000) }
        return String(format: "\(s)%.0f", value)
    }

    var formattedTotalRevenue: String { shortRevenue(totalRevenue) }
    var formattedAOV: String { shortRevenue(avgOrderValue) }

    static let categoryColors: [String: String] = [
        "jewellery": "💎", "watches": "⌚", "leather_goods": "👜",
        "couture": "👗", "accessories": "🧣", "fragrances": "🌸", "other": "📦"
    ]

    func categoryEmoji(_ cat: String) -> String {
        Self.categoryColors[cat.lowercased()] ?? "📦"
    }

    private static func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: str) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: str)
    }
}
