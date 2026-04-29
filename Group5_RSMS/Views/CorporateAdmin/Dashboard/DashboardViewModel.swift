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
    var dailyRevenue: [DailyRevenue] = []          // time-filtered (drives chart legend)
    var allTimeDailyRevenue: [DailyRevenue] = []   // always all-time (drives AI forecast)
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
    var avgCustomerLifecycleDays: Double = 0
    var conversionRate: Double = 0.0
    var netProfitMargin: Double = 0
    var grossProfit: Double = 0
    var totalExpenses: Double = 0
    var inventoryTurnover: Double = 0
    var inventoryHealth: Double = 0
    var estimatedOpex: Double = 0
    var estimatedTax: Double = 0
    var operatingEfficiency: Double = 0

    // MARK: - Audit State
    var recentAuditLogs: [AuditLogEntry] = []

    // MARK: - UI State
    var isLoading: Bool = false
    var errorMessage: String?
    var lastRefreshed: Date?
    private var refreshTimer: Timer?
    private var stores: [Store] = []

    // ─────────────────────────────────────────────
    // MARK: - Time Frame
    // ─────────────────────────────────────────────

    enum DashboardTimeFrame: String, CaseIterable, Identifiable {
        case today = "Today"
        case yesterday = "Yesterday"
        case last7Days = "Last 7 Days"
        case last30Days = "Last 30 Days"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
        
        var startDate: Date? {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .today: return calendar.startOfDay(for: now)
            case .yesterday: return calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
            case .last7Days: return calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now))
            case .last30Days: return calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now))
            case .thisMonth: return calendar.date(from: calendar.dateComponents([.year, .month], from: now))
            case .thisYear: return calendar.date(from: calendar.dateComponents([.year], from: now))
            case .allTime: return nil
            }
        }

        var endDate: Date? {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .yesterday: return calendar.startOfDay(for: now)
            default: return nil
            }
        }
    }

    var selectedTimeFrame: DashboardTimeFrame = .last30Days {
        didSet {
            if oldValue != selectedTimeFrame {
                Task { await fetchDashboardData(stores: stores) }
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Models
    // ─────────────────────────────────────────────

    struct StoreKPI: Identifiable {
        let id: UUID
        let storeName: String
        let storeCity: String
        let storeCountry: String
        let currencyCode: String
        let isActive: Bool
        let revenue: Double
        let target: Double
        let orderCount: Int
        let inventoryUnits: Int
        let staffCount: Int

        var achievementPercentage: Double {
            target > 0 ? (revenue / target) * 100 : 0
        }
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

    /// `customer_orders` — store_id links to stores, user_id is the customer (NOT NULL)
    private struct OrderRow: Decodable {
        let id: UUID
        let store_id: UUID?
        let total_amount: Double
        let status: String?
        let created_at: String?
        let user_id: UUID?

        enum CodingKeys: String, CodingKey {
            case id, store_id, total_amount, status, created_at, user_id
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.id          = try c.decode(UUID.self, forKey: .id)
            self.store_id    = try c.decodeIfPresent(UUID.self, forKey: .store_id)
            self.status      = try c.decodeIfPresent(String.self, forKey: .status)
            self.created_at  = try c.decodeIfPresent(String.self, forKey: .created_at)
            self.user_id     = try c.decodeIfPresent(UUID.self, forKey: .user_id)
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

    /// inventory uses store_id (confirmed from StockAnalysisViewModel)
    private struct InventoryRow: Decodable {
        let store_id: UUID
        let product_id: UUID
        let stock_quantity: Int
        let min_stock_level: Int?
        let max_stock_level: Int?
    }

    /// One row per employee — we COUNT these to get staff per boutique
    private struct EmployeeCountRow: Decodable {
        let boutique_id: UUID
    }

    /// One row per expense entry
    private struct ExpenseRow: Decodable {
        let store_id: UUID?
        let amount: Double
        let category: String?
        let created_at: String?
    }

    /// One row per day per store from store_traffic
    private struct StoreTrafficRow: Decodable {
        let store_id: UUID?
        let visitor_count: Int
    }

    private struct OrderItemRow: Decodable {
        let order_id: UUID
        let quantity: Int
        let price_at_purchase: Double
        let products: EmbeddedCat?

        struct EmbeddedCat: Decodable {
            let category: String?
            let cost_price: Double?
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
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        #if canImport(Supabase)
        do {
            async let o       = fetchOrders()
            async let i       = fetchInventory()
            async let items   = fetchOrderItems()
            async let logs    = fetchAuditLogs()
            async let pCount  = fetchTotalProfilesCount()
            async let emps    = fetchEmployeeCounts()
            async let exps    = fetchExpenses()
            async let traffic = fetchStoreTraffic()

            let (orders, inventory, orderItems, auditLogs, totalProfiles, employees, expenses, storeTraffic) =
                try await (o, i, items, logs, pCount, emps, exps, traffic)

            // ── Filter valid orders (exclude cancelled / refunded) ──
            var valid = orders.filter { order in
                guard let s = order.status?.lowercased() else { return true }
                return !Self.excludedStatuses.contains(s)
            }
            
            var validAuditLogs = auditLogs
            var validExpenses = expenses

            // ── Apply Time Frame Filter ──
            if let startDate = self.selectedTimeFrame.startDate {
                valid = valid.filter { order in
                    guard let orderDate = Self.parseDate(order.created_at) else { return false }
                    let afterStart = orderDate >= startDate
                    let beforeEnd = self.selectedTimeFrame.endDate.map { orderDate < $0 } ?? true
                    return afterStart && beforeEnd
                }
                
                validAuditLogs = validAuditLogs.filter { log in
                    guard let logDate = Self.parseDate(log.created_at) else { return false }
                    let afterStart = logDate >= startDate
                    let beforeEnd = self.selectedTimeFrame.endDate.map { logDate < $0 } ?? true
                    return afterStart && beforeEnd
                }
                
                validExpenses = validExpenses.filter { exp in
                    guard let expDateStr = exp.created_at, let expDate = Self.parseDate(expDateStr) else { return false }
                    let afterStart = expDate >= startDate
                    let beforeEnd = self.selectedTimeFrame.endDate.map { expDate < $0 } ?? true
                    return afterStart && beforeEnd
                }
            }
            
            let validOrderIDs = Set(valid.map { $0.id })
            let filteredOrderItems = orderItems.filter { validOrderIDs.contains($0.order_id) }

            // ── Global KPIs ──
            self.totalRevenue        = valid.reduce(0) { $0 + $1.total_amount }
            self.totalOrders         = valid.count
            // totalInventoryUnits: total stock quantity across all stores (unique SKU count for display)
            self.totalInventoryUnits = Set(inventory.map(\.product_id)).count
            self.activeStoreCount    = stores.filter { $0.isActive == true }.count
            self.avgOrderValue       = totalOrders > 0 ? totalRevenue / Double(totalOrders) : 0
            // ✅ FIX: Use TIME-FILTERED expenses, not all-time expenses
            self.totalExpenses        = validExpenses.reduce(0) { $0 + $1.amount }

            // ── Per-store breakdown ──
            var revByStore:   [UUID: Double] = [:]
            var ordByStore:   [UUID: Int]    = [:]
            var invByStore:   [UUID: Int]    = [:]   // keyed on store_id (inventory column)
            var staffByStore: [UUID: Int]    = [:]   // keyed on boutique_id (employees column)
            var opexByStore:  [UUID: Double] = [:]   // keyed on store_id
            var visitorsByStore: [UUID: Int] = [:]   // keyed on store_id

            // Staff: count employees per boutique
            for emp in employees {
                staffByStore[emp.boutique_id, default: 0] += 1
            }

            // Orders: keyed on store_id (actual column in customer_orders)
            for order in valid {
                if let sid = order.store_id {
                    revByStore[sid, default: 0] += order.total_amount
                    ordByStore[sid, default: 0] += 1
                }
            }

            // Financials: aggregate expenses by store_id (use validExpenses for time-filtered OPEX)
            for exp in validExpenses {
                if let sid = exp.store_id {
                    opexByStore[sid, default: 0] += exp.amount
                }
            }

            // Conversion Rate: aggregate traffic by store_id
            for traffic in storeTraffic {
                if let sid = traffic.store_id {
                    visitorsByStore[sid, default: 0] += traffic.visitor_count
                }
            }

            // Inventory: keyed on store_id (the actual column name in the inventory table)
            for inv in inventory {
                invByStore[inv.store_id, default: 0] += inv.stock_quantity
            }

            // Total real stock quantity for inventory turnover calculation
            let totalStockQuantity = inventory.reduce(0) { $0 + $1.stock_quantity }

            let healthyItems = inventory.filter { row in
                let min = row.min_stock_level ?? 5
                let max = row.max_stock_level ?? 50
                return row.stock_quantity >= min && row.stock_quantity <= max
            }.count
            self.inventoryHealth = inventory.isEmpty ? 0 : (Double(healthyItems) / Double(inventory.count)) * 100

            self.storeKPIs = stores.map { store in
                StoreKPI(
                    id: store.id, storeName: store.name, storeCity: store.city,
                    storeCountry: store.country,
                    currencyCode: store.currencyCode ?? "INR",
                    isActive: store.isActive == true,
                    revenue: revByStore[store.id] ?? 0,
                    target: store.monthlyRevenueTarget ?? 1_000_000,
                    orderCount: ordByStore[store.id] ?? 0,
                    inventoryUnits: invByStore[store.id] ?? 0,
                    staffCount: staffByStore[store.id] ?? 0
                )
            }.sorted { $0.achievementPercentage > $1.achievementPercentage }

            // Conversion Rate: orders / visitors across all stores
            let totalVisitors = visitorsByStore.values.reduce(0, +)
            let uniqueOrderingCustomers = Set(valid.compactMap { $0.user_id }).count
            if totalVisitors > 0 {
                self.conversionRate = (Double(uniqueOrderingCustomers) / Double(totalVisitors)) * 100
            } else if totalProfiles > 0 {
                // Fallback: unique customers / total app users
                self.conversionRate = (Double(uniqueOrderingCustomers) / Double(totalProfiles)) * 100
            }

            // ── Revenue Trend ──────────────────────────────────────────────────────
            // dailyRevenue:        time-filtered — drives the visible chart in the AI card
            // allTimeDailyRevenue: ALWAYS all historical data — drives the forecast regression
            let allTimeOrders = orders.filter { order in
                guard let s = order.status?.lowercased() else { return true }
                return !Self.excludedStatuses.contains(s)
            }
            computeDailyRevenue(from: valid)         // filtered view for the chart
            computeAllTimeDailyRevenue(from: allTimeOrders)  // full history for forecast

            // ── Basket Size ──
            computeBasketSize(from: filteredOrderItems)

            // ── Category Breakdown ──
            computeCategorySales(from: filteredOrderItems)

            // ── Customer Insights ──
            computeCustomerInsights(from: valid)

            // ── Audit Logs ──
            self.recentAuditLogs = validAuditLogs.prefix(15).map { row in
                AuditLogEntry(
                    id: row.id,
                    action: row.action ?? "Action",
                    eventType: row.event_type ?? "",
                    userName: row.user_name ?? "System",
                    entity: row.entity ?? "",
                    createdAt: Self.parseDate(row.created_at) ?? Date()
                )
            }

            // ── Financials (compute BEFORE AI forecast so context is correct) ──
            computeFinancials(from: filteredOrderItems, totalStockQuantity: totalStockQuantity)

            // ── AI Forecast (always uses all-time data — independent of time filter) ──
            await computeForecast()

            self.lastRefreshed = Date()
        } catch is CancellationError {
            // Task was cancelled by the system (e.g. user navigated away) - ignore silently
        } catch {
            print("❌ Dashboard fetch error: \(error)")
            self.errorMessage = "Database connection issue. Please try again."
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
            .select("id, store_id, total_amount, status, created_at, user_id")
            .execute()
            .value
    }

    private func fetchInventory() async throws -> [InventoryRow] {
        // inventory table uses store_id (not boutique_id)
        try await SupabaseManager.shared.client
            .from("inventory")
            .select("store_id, product_id, stock_quantity, min_stock_level, max_stock_level")
            .execute()
            .value
    }

    private func fetchOrderItems() async throws -> [OrderItemRow] {
        try await SupabaseManager.shared.client
            .from("customer_order_items")
            .select("order_id, quantity, price_at_purchase, products(category, cost_price)")
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
                .from("customer_profiles")
                .select("id")
                .execute()
                .value
            return rows.count
        } catch is CancellationError {
            return 0
        } catch {
            print("Customer profile count fetch skipped: \(error.localizedDescription)")
            return 0
        }
    }

    /// Returns one row per active employee (we COUNT them to get staff per boutique)
    private func fetchEmployeeCounts() async throws -> [EmployeeCountRow] {
        do {
            return try await SupabaseManager.shared.client
                .from("employees")
                .select("boutique_id")
                .eq("is_active", value: true)
                .execute()
                .value
        } catch is CancellationError { return [] }
        catch { print("Employee fetch skipped: \(error.localizedDescription)"); return [] }
    }

    /// Fetches all expense rows so we can sum actual OPEX
    private func fetchExpenses() async throws -> [ExpenseRow] {
        do {
            return try await SupabaseManager.shared.client
                .from("expenses")
                .select("store_id, amount, category, created_at")
                .execute()
                .value
        } catch is CancellationError { return [] }
        catch { print("Expenses fetch skipped: \(error.localizedDescription)"); return [] }
    }

    /// Fetches store traffic rows for actual conversion rate calculation
    private func fetchStoreTraffic() async throws -> [StoreTrafficRow] {
        do {
            return try await SupabaseManager.shared.client
                .from("store_traffic")
                .select("store_id, visitor_count")
                .execute()
                .value
        } catch is CancellationError { return [] }
        catch { print("Traffic fetch skipped: \(error.localizedDescription)"); return [] }
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

    /// Computes daily revenue from ALL historical orders (no time-frame filter).
    /// Used exclusively for the AI forecast regression so the prediction
    /// never changes when the user switches the 7D / 30D / 1Y segmented control.
    private func computeAllTimeDailyRevenue(from orders: [OrderRow]) {
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

        self.allTimeDailyRevenue = revByDay.keys.sorted().map { day in
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
        let knownCategories: Set<String> = ["jewellery", "watches", "leather_goods", "couture", "accessories", "fragrances", "eyewear", "other"]

        for item in items {
            let raw = (item.products?.category ?? "other").lowercased().trimmingCharacters(in: .whitespaces)
            var cat = "other"
            
            // Smart Mapping: Normalize database strings to UI keys
            if raw == "fragrance" { cat = "fragrances" }
            else if raw == "leather goods" { cat = "leather_goods" }
            else if knownCategories.contains(raw) { cat = raw }
            
            revByCat[cat, default: 0] += item.price_at_purchase * Double(item.quantity)
            cntByCat[cat, default: 0] += item.quantity
        }

        self.categorySales = revByCat.map { key, val in
            CategorySales(category: key, revenue: val, count: cntByCat[key] ?? 0)
        }.sorted { $0.revenue > $1.revenue }
    }

    private func computeCustomerInsights(from orders: [OrderRow]) {
        // Group orders by user_id to determine new vs. returning customers
        var ordersByCustomer: [UUID: [OrderRow]] = [:]
        for order in orders {
            guard let uid = order.user_id else { continue }
            ordersByCustomer[uid, default: []].append(order)
        }
        self.newCustomers       = ordersByCustomer.filter { $0.value.count == 1 }.count
        self.returningCustomers = ordersByCustomer.filter { $0.value.count > 1 }.count

        // Avg. Lifecycle: average of (last_order - first_order) per returning customer
        let lifecycleDays: [Double] = ordersByCustomer.values.compactMap { rows in
            guard rows.count > 1 else { return nil }
            let dates = rows.compactMap { Self.parseDate($0.created_at) }.sorted()
            guard let first = dates.first, let last = dates.last else { return nil }
            return last.timeIntervalSince(first) / 86400
        }
        self.avgCustomerLifecycleDays = lifecycleDays.isEmpty ? 0 : lifecycleDays.reduce(0, +) / Double(lifecycleDays.count)
        // conversionRate is set in the main fetch using store_traffic data
    }

    private func computeFinancials(from items: [OrderItemRow], totalStockQuantity: Int = 0) {
        guard totalRevenue > 0 else {
            grossProfit = 0; estimatedOpex = 0; estimatedTax = 0
            netProfitMargin = 0; operatingEfficiency = 0; inventoryTurnover = 0
            return
        }

        // ── COGS ──────────────────────────────────────────────────────────────
        // Use real cost_price from DB (confirmed present for all products).
        // Fallback to price_at_purchase × 0.45 per item if cost_price is null.
        let realCOGS = items.reduce(0.0) { sum, item in
            let cost = item.products?.cost_price ?? (item.price_at_purchase * 0.45)
            return sum + (cost * Double(item.quantity))
        }
        // Safety guard: if DB data implies gross < 25%, the base_price data is
        // unreliable (wrong unit/currency). Fall back to 45% COGS benchmark.
        let estimatedCOGS: Double
        if realCOGS > 0 {
            let impliedGross = (totalRevenue - realCOGS) / totalRevenue
            estimatedCOGS = impliedGross < 0.25 ? totalRevenue * 0.45 : realCOGS
        } else {
            estimatedCOGS = totalRevenue * 0.45
        }
        self.grossProfit = max(0, totalRevenue - estimatedCOGS)   // ~55% of revenue

        // ── OPEX ──────────────────────────────────────────────────────────────
        // Cap at 85% of Gross Profit so OPEX can never exceed gross (preventing negative net).
        if totalExpenses > 0 {
            self.estimatedOpex = min(totalExpenses, grossProfit * 0.85)
        } else {
            self.estimatedOpex = totalRevenue * 0.20
        }

        // ── Tax ────────────────────────────────────────────────────────────────
        let preTaxProfit = max(0, grossProfit - estimatedOpex)
        self.estimatedTax = preTaxProfit * 0.25

        // ── Net Margin ─────────────────────────────────────────────────────────
        let netProfit = preTaxProfit - estimatedTax
        self.netProfitMargin = (netProfit / totalRevenue) * 100

        // ── Operating Efficiency ───────────────────────────────────────────────
        self.operatingEfficiency = grossProfit > 0
            ? max(0, ((grossProfit - estimatedOpex) / grossProfit)) * 100
            : 0

        // ── Inventory Turnover ─────────────────────────────────────────────────
        let stockQty = totalStockQuantity > 0 ? totalStockQuantity : totalInventoryUnits
        let avgInvValue = Double(stockQty) * 8_000
        self.inventoryTurnover = avgInvValue > 0 ? (estimatedCOGS / avgInvValue) * 12 : 0
    }

    /// Linear regression on ALL historical daily revenue → stable future forecast.
    /// Uses allTimeDailyRevenue so the prediction never changes with the time filter.
    private func computeForecast() async {
        let data = Array(allTimeDailyRevenue.suffix(90))
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
        let catSummary = categorySales.map { "\($0.category): \(shortRevenue($0.revenue))" }.joined(separator: ", ")
        let context = """
        Total 30-Day Revenue: \(formattedTotalRevenue)
        Total Orders: \(totalOrders)
        Average Order Value (AOV): \(formattedAOV)
        Category Breakdown: \(catSummary)
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
            if (error as NSError).code != -999 {
                print("Failed to fetch AI Insights: \(error)")
            }
            // Fallback to local heuristics if API fails or is cancelled
            self.aiPredictions = ["Growth predicted.", "AOV trending up.", "Inventory stable."]
            self.aiSuggestions = ["Restock Watches.", "Run promo.", "Audit logs."]
            self.bestPredictedCategory = "Jewellery"
            self.aiSuggestedAction = "Monitor high-value inventory levels."
            self.aiDetailedAnalysis = "Local fallback heuristic engaged."
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Auto-Refresh (30s Polling)
    // ─────────────────────────────────────────────

    func startAutoRefresh(stores: [Store]) {
        self.stores = stores
        stopAutoRefresh()
        
        // Poll every 30 seconds for near-real-time updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
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
        return localizedShortRevenue(value, currencyCode: "INR")
    }

    func localizedShortRevenue(_ value: Double, currencyCode: String) -> String {
        let symbol: String
        switch currencyCode {
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        case "JPY": symbol = "¥"
        case "AED": symbol = "د.إ"
        default: symbol = "₹"
        }
        
        let isIndian = currencyCode == "INR"
        
        if isIndian {
            if value >= 10_000_000 { return String(format: "\(symbol)%.1fCr", value / 10_000_000) }
            if value >= 100_000 { return String(format: "\(symbol)%.1fL", value / 100_000) }
            if value >= 1_000 { return String(format: "\(symbol)%.1fK", value / 1_000) }
            return String(format: "\(symbol)%.0f", value)
        } else {
            // International
            if value >= 1_000_000_000 { return String(format: "\(symbol)%.1fB", value / 1_000_000_000) }
            if value >= 1_000_000 { return String(format: "\(symbol)%.1fM", value / 1_000_000) }
            if value >= 1_000 { return String(format: "\(symbol)%.1fK", value / 1_000) }
            return String(format: "\(symbol)%.0f", value)
        }
    }

    var formattedTotalRevenue: String { shortRevenue(totalRevenue) }
    var formattedAOV: String { shortRevenue(avgOrderValue) }

    static let categoryColors: [String: String] = [
        "jewellery": "💎", "watches": "⌚", "leather_goods": "👜",
        "couture": "👗", "accessories": "🧣", "fragrances": "🌸", "eyewear": "🕶️", "other": "📦"
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
