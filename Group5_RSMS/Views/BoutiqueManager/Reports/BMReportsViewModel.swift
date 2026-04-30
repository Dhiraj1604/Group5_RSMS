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

@MainActor
final class BMReportsViewModel: ObservableObject {
    
    @Published var totalSales: Double = 0
    @Published var totalRevenue: Double = 0
    @Published var totalOrders: Int = 0
    @Published var footfall: Int = 0
    @Published var dormantEmployees: Int = 0
    
    // New detailed reporting data
    @Published var soldProducts: [SoldProduct] = []
    @Published var unsoldProducts: [InventoryProduct] = []
    @Published var dormantStaffDetails: [Employee] = []
    
    @Published var targetMetrics: [TargetMetric] = []
    @Published var dailySalesData: [DailySalesPoint] = []
    
    // New: Top Products and Completeness Flags
    @Published var topProducts: [SoldProduct] = []
    @Published var missingDataFlags: [String: Bool] = [:]
    
    @Published var isLoading = false
    
    // MARK: - Load All Reports Data
    func loadReports(boutiqueId: UUID) async {
        isLoading = true
        
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        async let payoutsFetch   = SupabaseSyncManager.shared.fetchAllPayouts(boutiqueId: boutiqueId)
        async let employeesFetch = SupabaseSyncManager.shared.fetchEmployees(boutiqueId: boutiqueId)
        async let soldProductsFetch = MerchandisingService.shared.fetchSoldProducts(forStore: boutiqueId)
        async let fallbackFetch = MerchandisingService.shared.fetchFallbackItems(forStore: boutiqueId)
        
        let payouts   = (try? await payoutsFetch)   ?? []
        let employees = (try? await employeesFetch) ?? []
        let soldItems = (try? await soldProductsFetch) ?? []
        let slowItems = (try? await fallbackFetch) ?? []
        
        print("Reports → payouts: \(payouts.count), employees: \(employees.count), sold: \(soldItems.count), slow: \(slowItems.count)")
        
        // --- Total Sales (Sold in last 30 days) ---
        // Payouts might be monthly, but let's filter by date for the 30-day window
        let recentPayouts = payouts.filter { $0.periodEnd >= thirtyDaysAgo }
        self.totalSales = recentPayouts.reduce(0.0) { $0 + $1.totalSalesAmount }
        self.totalRevenue = self.totalSales * 0.72
        self.totalOrders = recentPayouts.count
        
        self.soldProducts = soldItems
        
        // --- Footfall (Items in stock > 30 days) ---
        self.footfall = slowItems.count
        self.unsoldProducts = slowItems
        
        // --- Dormant employees (active but no payout in last 30 days) ---
        let recentEmployeeIds = Set(recentPayouts.map { $0.employeeId })
        let activeEmployees = employees.filter { $0.isActive ?? true }
        self.dormantStaffDetails = activeEmployees.filter {
            !recentEmployeeIds.contains($0.id)
        }
        self.dormantEmployees = self.dormantStaffDetails.count
        
        // --- Targets vs Actual ---
        self.targetMetrics = [
            TargetMetric(label: "Sales",    target: 500000, actual: self.totalSales),
            TargetMetric(label: "Slow Items", target: 50,    actual: Double(self.footfall)), // "Footfall" in UI
            TargetMetric(label: "Revenue",  target: 350000, actual: self.totalRevenue)
        ]
        
        // --- Daily Sales (last 14 days) ---
        var dailyData: [DailySalesPoint] = []
        for dayOffset in (0..<14).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            
            let dayPayouts = payouts.filter { payout in
                payout.periodEnd >= startOfDay && payout.periodEnd < endOfDay
            }
            let daySales: Double = dayPayouts.reduce(0.0) { result, payout in
                result + payout.totalSalesAmount
            }
            
            dailyData.append(DailySalesPoint(date: startOfDay, amount: daySales))
        }
        self.dailySalesData = dailyData
        
        // --- Top Products ---
        self.topProducts = Array(soldItems.prefix(5))
        
        // --- Data Completeness Check ---
        var flags: [String: Bool] = [:]
        if self.totalSales == 0 { flags["Sales"] = true }
        if self.footfall == 0 { flags["Footfall"] = true }
        if self.targetMetrics.isEmpty { flags["Targets"] = true }
        if self.soldProducts.isEmpty { flags["Products"] = true }
        self.missingDataFlags = flags
        
        isLoading = false
    }
    
    // MARK: - Filtered chart data
    func chartData(for range: ChartRange) -> [DailySalesPoint] {
        switch range {
        case .oneWeek:  return Array(dailySalesData.suffix(7))
        case .twoWeeks: return dailySalesData
        }
    }
    
    var targetsMet: Int {
        targetMetrics.filter { $0.isMet }.count
    }
    
    var targetsMissed: Int {
        targetMetrics.filter { !$0.isMet }.count
    }
}

enum ChartRange: String, CaseIterable {
    case oneWeek  = "1W"
    case twoWeeks = "2W"
}
