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
        
        // --- Yearly Performance (from customer_orders) ---
        let performance = (try? await MerchandisingService.shared.fetchYearlyPerformance(forStore: boutiqueId)) ?? (totalSales: 0, totalOrders: 0, monthlyTrend: [])
        self.totalSales = performance.totalSales
        self.totalRevenue = self.totalSales * 0.72
        self.totalOrders = performance.totalOrders
        self.dailySalesData = performance.monthlyTrend.map { DailySalesPoint(date: $0.date, amount: $0.amount) }
        
        // --- sold products (for month) ---
        self.soldProducts = soldItems
        
        // --- Footfall (Items in stock > 30 days) ---
        self.footfall = slowItems.count
        self.unsoldProducts = slowItems
        
        // --- Dormant employees (active but no payout this year) ---
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)) ?? today
        let yearlyPayouts = payouts.filter { $0.periodEnd >= startOfYear }
        let recentEmployeeIds = Set(yearlyPayouts.map { $0.employeeId })
        let activeEmployees = employees.filter { $0.isActive ?? true }
        self.dormantStaffDetails = activeEmployees.filter {
            !recentEmployeeIds.contains($0.id)
        }
        self.dormantEmployees = self.dormantStaffDetails.count
        
        // --- Targets vs Actual (Yearly Targets) ---
        self.targetMetrics = [
            TargetMetric(label: "Sales",    target: 5000000, actual: self.totalSales),
            TargetMetric(label: "Slow Items", target: 500,    actual: Double(self.footfall)),
            TargetMetric(label: "Revenue",  target: 3500000, actual: self.totalRevenue)
        ]

        
        isLoading = false
    }
    
    // MARK: - Filtered chart data
    func chartData(for range: ChartRange) -> [DailySalesPoint] {
        return dailySalesData
    }

    
    var targetsMet: Int {
        targetMetrics.filter { $0.isMet }.count
    }
    
    var targetsMissed: Int {
        targetMetrics.filter { !$0.isMet }.count
    }
}

enum ChartRange: String, CaseIterable {
    case yearly = "Yearly"
}


