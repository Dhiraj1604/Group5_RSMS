//
//  BMDashboardViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

struct StaffPerformanceEntry: Identifiable {
    let id: UUID          // employee id
    let name: String
    let totalSales: Double
    let thisMonthSales: Double
    let totalOrders: Int
    let avgOrderValue: Double
    let potentialCommission: Double // Added for simulation
    let commissionRate: Double      // Added to show in UI
}

@MainActor
final class BMDashboardViewModel: ObservableObject {
    @Published var dailyTarget: Double = 0.0
    @Published var actualSales: Double = 0.0
    @Published var isLoading: Bool = false
    
    // Staff Performance
    @Published var staffPerformance: [StaffPerformanceEntry] = []
    @Published var isLoadingStaff: Bool = false
    @Published var teamTotalSales: Double = 0.0
    @Published var teamThisMonthSales: Double = 0.0
    @Published var teamTotalOrders: Int = 0
    
    var progress: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(actualSales / dailyTarget, 1.0)
    }
    
    var rawProgress: Double {
        guard dailyTarget > 0 else { return 0 }
        return actualSales / dailyTarget
    }
    
    private let sync = SupabaseSyncManager.shared
    
    func loadDailyPacing(boutiqueId: UUID) async {
        isLoading = true
        // For Sprint 2: Since actual sales from POS aren't fully modeled in Supabase yet,
        // we'll calculate a realistic mock target and actual based on the store.
        
        // Simulating network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        // Generate pseudo-random deterministic sales based on date and boutique to look consistent
        let seed = abs("\(boutiqueId.uuidString)_\(formatter.string(from: Date()))".hashValue)
        
        let baseTarget = 15000.0
        self.dailyTarget = baseTarget + Double(seed % 5000)
        
        // Actual sales pacing varies based on time of day
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let storeOpenHour = 10
        let storeCloseHour = 20
        
        let totalOpenMinutes = Double((storeCloseHour - storeOpenHour) * 60)
        let elapsedMinutes = Double((currentHour - storeOpenHour) * 60 + currentMinute)
        
        if currentHour < storeOpenHour {
            self.actualSales = 0
        } else if currentHour >= storeCloseHour {
            self.actualSales = self.dailyTarget * Double.random(in: 0.98...1.05)
        } else {
            let elapsedFraction = max(0, min(elapsedMinutes / totalOpenMinutes, 1.0))
            let morningBaseline = 0.05
            let adjustedFraction = morningBaseline + (elapsedFraction * (1.0 - morningBaseline))
            
            self.actualSales = self.dailyTarget * adjustedFraction * Double.random(in: 0.85...1.1)
        }
        
        isLoading = false
    }
    
    func loadStaffPerformance(boutiqueId: UUID) async {
        isLoadingStaff = true
        
        let calendar = Calendar.current
        let today = Date()
        guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else {
            isLoadingStaff = false
            return
        }
        
        do {
            async let employeesFetch = sync.fetchEmployees(boutiqueId: boutiqueId)
            async let yearlySalesFetch = sync.fetchSalesPerEmployee(boutiqueId: boutiqueId, from: startOfYear)
            async let monthlySalesFetch = sync.fetchSalesPerEmployee(boutiqueId: boutiqueId, from: startOfMonth)
            async let storeMonthlyTotalFetch = sync.fetchStoreTotalSales(boutiqueId: boutiqueId, from: startOfMonth)
            async let commissionRatesFetch = sync.fetchCommissionRates(boutiqueId: boutiqueId)
            async let totalPerformanceFetch = MerchandisingService.shared.fetchYearlyPerformance(forStore: boutiqueId)
            
            let (employees, yearlySales, monthlySales, storeMonthlyTotal, commissionRates, totalPerf) = try await (
                employeesFetch, yearlySalesFetch, monthlySalesFetch, storeMonthlyTotalFetch, commissionRatesFetch, totalPerformanceFetch
            )
            
            // Map stats by employee ID
            var yearlyMap: [UUID: EmployeeSalesSummary] = [:]
            for s in yearlySales { yearlyMap[s.employeeId] = s }
            
            var monthlyMap: [UUID: EmployeeSalesSummary] = [:]
            for s in monthlySales { monthlyMap[s.employeeId] = s }
            
            var entries: [StaffPerformanceEntry] = []
            
            // Map commission rates by employee ID
            var rateMap: [UUID: Double] = [:]
            for r in commissionRates {
                // Use the latest effective rate
                rateMap[r.employeeId] = r.ratePercentage
            }

            for emp in employees {
                let yStats = yearlyMap[emp.id]
                let mStats = monthlyMap[emp.id]
                
                let ySales = yStats?.totalSales ?? 0.0
                let mSales = mStats?.totalSales ?? 0.0
                let yCount = yStats?.orderCount ?? 0
                
                let avg = yCount > 0 ? ySales / Double(yCount) : 0
                
                // Calculate potential commission: (Store Monthly Total * Rate) / 100
                let rate = rateMap[emp.id] ?? 0.0
                let commission = (storeMonthlyTotal * rate) / 100.0

                entries.append(StaffPerformanceEntry(
                    id: emp.id,
                    name: emp.name,
                    // Use individual sales if available, otherwise show the store total for simulation
                    totalSales: ySales > 0 ? ySales : storeMonthlyTotal, 
                    thisMonthSales: mSales > 0 ? mSales : storeMonthlyTotal,
                    totalOrders: yCount,
                    avgOrderValue: avg,
                    potentialCommission: commission,
                    commissionRate: rate
                ))
            }
            
            self.staffPerformance   = entries.sorted { $0.potentialCommission > $1.potentialCommission }
            self.teamTotalSales     = totalPerf.totalSales
            self.teamThisMonthSales = storeMonthlyTotal
            self.teamTotalOrders    = totalPerf.totalOrders
            
        } catch {
            print("Failed to load staff performance: \(error)")
        }
        
        isLoadingStaff = false
    }
}
