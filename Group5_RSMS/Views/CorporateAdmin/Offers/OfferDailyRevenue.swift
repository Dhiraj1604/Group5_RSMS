//
//  OfferDailyRevenue.swift
//  Group5_RSMS
//
//  Created by Apple on 27/04/26.
//

import Foundation
import Supabase
import Combine


struct OfferDailyRevenue: Identifiable {
    let id = UUID()
    let day: String
    let revenue: Double
}

@MainActor
class OfferMetricsViewModel: ObservableObject {
    @Published var revenue: Double = 0
    @Published var orderCount: Int = 0
    @Published var aov: Double = 0
    @Published var dailyRevenue: [OfferDailyRevenue] = []
    @Published var isLoading: Bool = false

    func load(for offer: Offer) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let client = SupabaseManager.shared.client

            // Fetch orders directly linked to this offer via offer_id
            let orders: [RawOrder] = try await client
                .from("customer_orders")
                .select("id, total_amount, store_id, created_at")
                .eq("offer_id", value: offer.id)
                .execute()
                .value

            let totalRevenue = orders.reduce(0) { $0 + $1.totalAmount }
            let count = orders.count
            let avgOrderValue = count > 0 ? totalRevenue / Double(count) : 0

            // Group by actual date for chart
            var dateMap: [String: Double] = [:]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"

            for order in orders.sorted(by: { $0.createdAt < $1.createdAt }) {
                let label = dateFormatter.string(from: order.createdAt)
                dateMap[label, default: 0] += order.totalAmount
            }

            var seen: [String] = []
            for order in orders.sorted(by: { $0.createdAt < $1.createdAt }) {
                let label = dateFormatter.string(from: order.createdAt)
                if !seen.contains(label) { seen.append(label) }
            }

            self.revenue = totalRevenue
            self.orderCount = count
            self.aov = avgOrderValue
            self.dailyRevenue = seen.map { OfferDailyRevenue(day: $0, revenue: dateMap[$0] ?? 0) }

        } catch {
            print("❌ OfferMetricsViewModel fetch error: \(error)")
        }
    }
}

// Lightweight decodable just for this fetch
private struct RawOrder: Decodable {
    let id: UUID
    let totalAmount: Double
    let storeId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case totalAmount = "total_amount"
        case storeId = "store_id"
        case createdAt = "created_at"
    }
}
