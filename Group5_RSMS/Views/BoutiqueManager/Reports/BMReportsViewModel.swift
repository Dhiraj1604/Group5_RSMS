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
    
    @Published var targetMetrics: [TargetMetric] = []
    @Published var dailySalesData: [DailySalesPoint] = []
    
    @Published var isLoading = false
    
    // MARK: - Load All Reports Data
    func loadReports(boutiqueId: UUID) async {
        isLoading = true
        
        let calendar = Calendar.current
        let today = Date()
        let currentMonth = calendar.component(.month, from: today)
        let currentYear  = calendar.component(.year,  from: today)
        
        async let payoutsFetch   = SupabaseSyncManager.shared.fetchAllPayouts(boutiqueId: boutiqueId)
        async let employeesFetch = SupabaseSyncManager.shared.fetchEmployees(boutiqueId: boutiqueId)
        
        let payouts   = (try? await payoutsFetch)   ?? []
        let employees = (try? await employeesFetch) ?? []
        
        print("Reports → payouts: \(payouts.count), employees: \(employees.count)")
        
        // --- Filter this month's payouts ---
        let monthPayouts = payouts.filter {
            calendar.component(.month, from: $0.periodEnd) == currentMonth &&
            calendar.component(.year,  from: $0.periodEnd) == currentYear
        }
        
        self.totalSales   = monthPayouts.reduce(0.0) { $0 + $1.totalSalesAmount }
        self.totalRevenue = self.totalSales * 0.72
        self.totalOrders  = monthPayouts.count
        self.footfall     = monthPayouts.count
        
        // --- Dormant employees (active but no payout this month) ---
        let activeEmployeeIds = Set(monthPayouts.map { $0.employeeId })
        let activeEmployees   = employees.filter { $0.isActive ?? true }
        self.dormantEmployees = activeEmployees.filter {
            !activeEmployeeIds.contains($0.id)
        }.count
        
        // --- Targets vs Actual ---
        self.targetMetrics = [
            TargetMetric(label: "Sales",    target: 500000, actual: self.totalSales),
            TargetMetric(label: "Footfall", target: 150,    actual: Double(self.footfall)),
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
