//
//  MerchandisingModels.swift
//  Group5_RSMS
//
//  Models for merchandising analytics and trends.
//

import Foundation

struct SoldProduct: Identifiable, Codable {
    let id: UUID
    let name: String
    let sku: String
    let imageUrl: String?
    let quantitySold: Int
    let totalRevenue: Double
    
    // For manual grouping/display
    var displayQuantity: String {
        "\(quantitySold) units"
    }
}

enum TrendDirection: String, Codable {
    case up
    case steady
    case down
    
    var label: String {
        switch self {
        case .up: return "Trending Up"
        case .steady: return "Stable"
        case .down: return "Cooling"
        }
    }
}

struct FastMovingProduct: Identifiable {
    let id: UUID
    let name: String
    let sku: String
    let imageUrl: String?
    let recentUnitsSold: Int
    let previousUnitsSold: Int
    let currentStock: Int
    let isOnFloor: Bool
    let lastMovedToFloor: Date?
    
    var trendDirection: TrendDirection {
        if recentUnitsSold > previousUnitsSold { return .up }
        if recentUnitsSold < previousUnitsSold { return .down }
        return .steady
    }
    
    var velocityDelta: Int {
        recentUnitsSold - previousUnitsSold
    }
    
    var growthRate: Double? {
        guard previousUnitsSold > 0 else {
            return recentUnitsSold > 0 ? 1.0 : nil
        }
        return Double(velocityDelta) / Double(previousUnitsSold)
    }
    
    var recommendationText: String {
        switch trendDirection {
        case .up:
            return isOnFloor ? "Keep this in a prime sightline." : "Move this to the floor now."
        case .steady:
            return isOnFloor ? "Performing steadily on the floor." : "Optional floor placement."
        case .down:
            return isOnFloor ? "Consider rotating this out soon." : "Low urgency for floor space."
        }
    }
}

struct SalesTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct MerchandisingInsights {
    let totalSalesCount: Int
    let fallbackCount: Int
    let weeklyTrend: [SalesTrendData]
}
