//
//  BMDashboardViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

@MainActor
final class BMDashboardViewModel: ObservableObject {
    @Published var dailyTarget: Double = 0.0
    @Published var actualSales: Double = 0.0
    @Published var isLoading: Bool = false
    
    var progress: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(actualSales / dailyTarget, 1.0)
    }
    
    var rawProgress: Double {
        guard dailyTarget > 0 else { return 0 }
        return actualSales / dailyTarget
    }

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
            self.actualSales = self.dailyTarget * Double.random(in: 0.98...1.05) // End of day target achievement
        } else {
            let elapsedFraction = max(0, min(elapsedMinutes / totalOpenMinutes, 1.0))
            // Start with a small baseline so it's not $0 right at opening
            let morningBaseline = 0.05 
            let adjustedFraction = morningBaseline + (elapsedFraction * (1.0 - morningBaseline))
            
            self.actualSales = self.dailyTarget * adjustedFraction * Double.random(in: 0.85...1.1)
        }
        
        isLoading = false
    }
}
