//
//  BMReportsViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

struct DailySalesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
}

struct TargetMetric: Identifiable {
    let id = UUID()
    let label: String
    let target: Double
    let actual: Double
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return actual / target
    }
    
    var isMet: Bool { actual >= target }
}

// MARK: - Consolidated Report Period
enum ConsolidatedPeriod: String, CaseIterable, Identifiable {
    case oneMonth   = "Last 30 Days"
    case threeMonth = "Last 90 Days"
    case sixMonth   = "Last 180 Days"
    case oneYear    = "Last 365 Days"
    
    var id: String { rawValue }
    
    var days: Int {
        switch self {
        case .oneMonth:   return 30
        case .threeMonth: return 90
        case .sixMonth:   return 180
        case .oneYear:    return 365
        }
    }
    
    var shortLabel: String {
        switch self {
        case .oneMonth:   return "1M"
        case .threeMonth: return "3M"
        case .sixMonth:   return "6M"
        case .oneYear:    return "1Y"
        }
    }
}

// MARK: - Consolidated Report Data Model
struct ConsolidatedReportData {
    let period: ConsolidatedPeriod
    let fromDate: Date
    let toDate: Date
    let totalSales: Double
    let totalRevenue: Double
    let totalOrders: Int
    let topProducts: [SoldProduct]
    let targetMetrics: [TargetMetric]
    let missingDataFlags: [String: Bool]
    
    var averageMonthlySales: Double {
        guard period.days > 0 else { return 0 }
        let months = Double(period.days) / 30.0
        return totalSales / months
    }
}

@MainActor
final class BMReportsViewModel: ObservableObject {
    
    @Published var totalSales: Double = 0
    @Published var totalRevenue: Double = 0
    @Published var totalOrders: Int = 0
    @Published var footfall: Int = 0
    @Published var dormantEmployees: Int = 0
    
    // Detailed reporting data
    @Published var soldProducts: [SoldProduct] = []
    @Published var unsoldProducts: [InventoryProduct] = []
    @Published var dormantStaffDetails: [Employee] = []
    
    @Published var targetMetrics: [TargetMetric] = []
    @Published var dailySalesData: [DailySalesPoint] = []
    
    // Top Products and Completeness Flags
    @Published var topProducts: [SoldProduct] = []
    @Published var missingDataFlags: [String: Bool] = [:]
    
    @Published var isLoading = false
    
    // MARK: - Consolidated Report State
    @Published var consolidatedReport: ConsolidatedReportData? = nil
    @Published var isLoadingConsolidated = false
    
    // MARK: - Load Weekly Reports Data (used by BMReportsTab)
    func loadReports(boutiqueId: UUID) async {
        isLoading = true
        
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        async let payoutsFetch      = SupabaseSyncManager.shared.fetchAllPayouts(boutiqueId: boutiqueId)
        async let employeesFetch    = SupabaseSyncManager.shared.fetchEmployees(boutiqueId: boutiqueId)
        async let soldProductsFetch = MerchandisingService.shared.fetchSoldProducts(forStore: boutiqueId)
        async let fallbackFetch     = MerchandisingService.shared.fetchFallbackItems(forStore: boutiqueId)
        
        let payouts   = (try? await payoutsFetch)   ?? []
        let employees = (try? await employeesFetch) ?? []
        let soldItems = (try? await soldProductsFetch) ?? []
        let slowItems = (try? await fallbackFetch) ?? []
        
        print("Reports → payouts: \(payouts.count), employees: \(employees.count), sold: \(soldItems.count), slow: \(slowItems.count)")
        
        let recentPayouts = payouts.filter { $0.periodEnd >= thirtyDaysAgo }
        self.totalSales = recentPayouts.reduce(0.0) { $0 + $1.totalSalesAmount }
        self.totalRevenue = self.totalSales * 0.72
        self.totalOrders = recentPayouts.count
        self.soldProducts = soldItems
        self.footfall = slowItems.count
        self.unsoldProducts = slowItems
        
        let recentEmployeeIds = Set(recentPayouts.map { $0.employeeId })
        let activeEmployees = employees.filter { $0.isActive ?? true }
        self.dormantStaffDetails = activeEmployees.filter { !recentEmployeeIds.contains($0.id) }
        self.dormantEmployees = self.dormantStaffDetails.count
        
        self.targetMetrics = [
            TargetMetric(label: "Sales",      target: 500000, actual: self.totalSales),
            TargetMetric(label: "Slow Items", target: 50,     actual: Double(self.footfall)),
            TargetMetric(label: "Revenue",    target: 350000, actual: self.totalRevenue)
        ]
        
        var dailyData: [DailySalesPoint] = []
        for dayOffset in (0..<14).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            let dayPayouts = payouts.filter { $0.periodEnd >= startOfDay && $0.periodEnd < endOfDay }
            let daySales = dayPayouts.reduce(0.0) { $0 + $1.totalSalesAmount }
            dailyData.append(DailySalesPoint(date: startOfDay, amount: daySales))
        }
        self.dailySalesData = dailyData
        self.topProducts = Array(soldItems.prefix(5))
        
        var flags: [String: Bool] = [:]
        if self.totalSales == 0        { flags["Sales"] = true }
        if self.footfall == 0          { flags["Footfall"] = true }
        if self.targetMetrics.isEmpty  { flags["Targets"] = true }
        if self.soldProducts.isEmpty   { flags["Products"] = true }
        self.missingDataFlags = flags
        
        isLoading = false
    }
    
    // MARK: - Load Consolidated Report (configurable period, used by FullReportView)
    func loadConsolidatedReport(boutiqueId: UUID, period: ConsolidatedPeriod) async {
        isLoadingConsolidated = true
        
        let calendar = Calendar.current
        let toDate = Date()
        let fromDate = calendar.date(byAdding: .day, value: -period.days, to: toDate) ?? toDate
        
        async let payoutsFetch      = SupabaseSyncManager.shared.fetchAllPayouts(boutiqueId: boutiqueId)
        async let soldProductsFetch = MerchandisingService.shared.fetchSoldProducts(forStore: boutiqueId)
        
        let allPayouts   = (try? await payoutsFetch)      ?? []
        let allSoldItems = (try? await soldProductsFetch) ?? []
        
        // Filter to the selected period
        let periodPayouts = allPayouts.filter { $0.periodEnd >= fromDate && $0.periodEnd <= toDate }
        
        let sales   = periodPayouts.reduce(0.0) { $0 + $1.totalSalesAmount }
        let revenue = sales * 0.72
        let orders  = periodPayouts.count
        
        // Scale targets proportionally based on number of months
        let scaleFactor = Double(period.days) / 30.0
        let metrics: [TargetMetric] = [
            TargetMetric(label: "Sales Target",   target: 500000 * scaleFactor, actual: sales),
            TargetMetric(label: "Revenue Target", target: 350000 * scaleFactor, actual: revenue),
            TargetMetric(label: "Orders Target",  target: 50 * scaleFactor,     actual: Double(orders))
        ]
        
        // Sort products by units sold for this period
        let topItems = Array(allSoldItems.sorted { $0.quantitySold > $1.quantitySold }.prefix(5))
        
        var flags: [String: Bool] = [:]
        if sales == 0        { flags["Sales"] = true }
        if topItems.isEmpty  { flags["Products"] = true }
        
        self.consolidatedReport = ConsolidatedReportData(
            period: period,
            fromDate: fromDate,
            toDate: toDate,
            totalSales: sales,
            totalRevenue: revenue,
            totalOrders: orders,
            topProducts: topItems,
            targetMetrics: metrics,
            missingDataFlags: flags
        )
        
        isLoadingConsolidated = false
    }
    
    // MARK: - Filtered chart data
    func chartData(for range: ChartRange) -> [DailySalesPoint] {
        switch range {
        case .oneWeek:  return Array(dailySalesData.suffix(7))
        case .twoWeeks: return dailySalesData
        }
    }
    
    var targetsMet: Int   { targetMetrics.filter { $0.isMet }.count }
    var targetsMissed: Int { targetMetrics.filter { !$0.isMet }.count }
}

enum ChartRange: String, CaseIterable {
    case oneWeek  = "1W"
    case twoWeeks = "2W"
}
