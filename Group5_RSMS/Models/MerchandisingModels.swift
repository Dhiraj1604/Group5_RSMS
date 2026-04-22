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
