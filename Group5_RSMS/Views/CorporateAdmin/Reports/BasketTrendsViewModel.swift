//
//  BasketTrendsViewModel.swift
//  Group5_RSMS
//
//  ViewModel for Basket Size Trends report.
//  Fetches transactions from Supabase and aggregates by week/month.
//

import Foundation
import Combine
import Supabase

@MainActor
class BasketTrendsViewModel: ObservableObject {

    // MARK: - Published State
    @Published var weeklyData: [TrendPoint] = []
    @Published var monthlyData: [TrendPoint] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPeriod: Period = .weekly
    @Published var selectedStoreId: UUID? = nil   // nil = all stores
    @Published var selectedCategory: String? = nil // nil = all categories

    private let client = SupabaseManager.shared.client

    // MARK: - Models

    struct TrendPoint: Identifiable {
        let id = UUID()
        let label: String              // "Week 1", "Jan 2026", etc.
        let periodStart: Date
        let avgBasketSize: Double       // avg items per transaction
        let avgTransactionValue: Double // avg ₹ per transaction
        let transactionCount: Int
        let trend: Trend               // growth vs decline vs flat
    }

    enum Trend {
        case up, down, flat
    }

    enum Period: String, CaseIterable {
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    // MARK: - Computed

    var activeTrendData: [TrendPoint] {
        selectedPeriod == .weekly ? weeklyData : monthlyData
    }

    var overallAvgBasket: Double {
        let data = activeTrendData
        guard !data.isEmpty else { return 0 }
        return data.map(\.avgBasketSize).reduce(0, +) / Double(data.count)
    }

    var overallAvgValue: Double {
        let data = activeTrendData
        guard !data.isEmpty else { return 0 }
        return data.map(\.avgTransactionValue).reduce(0, +) / Double(data.count)
    }

    var totalTransactions: Int {
        activeTrendData.map(\.transactionCount).reduce(0, +)
    }

    var categories: [String] {
        ["Jewelry", "Bags", "Watches", "Clothing", "Accessories"]
    }

    // MARK: - Fetch

    private struct TransactionRow: Decodable {
        let id: UUID
        let store_id: UUID
        let item_count: Int
        let total_amount: Double
        let category: String?
        let created_at: String
    }

    func fetchTrends() async {
        isLoading = true
        errorMessage = nil

        do {
            var query = client
                .from("customer_orders")
                .select("id, store_id, item_count, total_amount, category, created_at")

            if let storeId = selectedStoreId {
                query = query.eq("store_id", value: storeId)
            }
            if let cat = selectedCategory {
                query = query.eq("category", value: cat)
            }

            let rows: [TransactionRow] = try await query
                .order("created_at", ascending: true)
                .execute()
                .value

            // Parse dates
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallback = ISO8601DateFormatter()

            let parsed: [ParsedTxn] = rows.compactMap { row in
                guard let date = formatter.date(from: row.created_at)
                        ?? fallback.date(from: row.created_at) else { return nil }
                return ParsedTxn(date: date, itemCount: row.item_count, totalAmount: row.total_amount)
            }

            self.weeklyData = aggregateWeekly(parsed)
            self.monthlyData = aggregateMonthly(parsed)

        } catch {
            print("❌ Failed to fetch transactions: \(error)")
            errorMessage = "Failed to load trends."
        }

        isLoading = false
    }

    // MARK: - Aggregation

    private func aggregateWeekly(_ txns: [ParsedTxn]) -> [TrendPoint] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: txns) { txn -> Date in
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: txn.date)
            return cal.date(from: comps) ?? txn.date
        }

        let sorted = grouped.sorted { $0.key < $1.key }
        var points: [TrendPoint] = []
        var prevAvg: Double?

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"

        for (weekStart, txns) in sorted {
            let avgItems = Double(txns.map(\.itemCount).reduce(0, +)) / Double(txns.count)
            let avgValue = txns.map(\.totalAmount).reduce(0, +) / Double(txns.count)
            let trend: Trend = {
                guard let prev = prevAvg else { return .flat }
                if avgItems > prev + 0.1 { return .up }
                if avgItems < prev - 0.1 { return .down }
                return .flat
            }()

            let label = "W/O \(dateFormatter.string(from: weekStart))"

            points.append(TrendPoint(
                label: label,
                periodStart: weekStart,
                avgBasketSize: avgItems,
                avgTransactionValue: avgValue,
                transactionCount: txns.count,
                trend: trend
            ))
            prevAvg = avgItems
        }

        return points
    }

    private func aggregateMonthly(_ txns: [ParsedTxn]) -> [TrendPoint] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: txns) { txn -> Date in
            let comps = cal.dateComponents([.year, .month], from: txn.date)
            return cal.date(from: comps) ?? txn.date
        }

        let sorted = grouped.sorted { $0.key < $1.key }
        var points: [TrendPoint] = []
        var prevAvg: Double?

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        for (monthStart, txns) in sorted {
            let avgItems = Double(txns.map(\.itemCount).reduce(0, +)) / Double(txns.count)
            let avgValue = txns.map(\.totalAmount).reduce(0, +) / Double(txns.count)
            let trend: Trend = {
                guard let prev = prevAvg else { return .flat }
                if avgItems > prev + 0.1 { return .up }
                if avgItems < prev - 0.1 { return .down }
                return .flat
            }()

            points.append(TrendPoint(
                label: dateFormatter.string(from: monthStart),
                periodStart: monthStart,
                avgBasketSize: avgItems,
                avgTransactionValue: avgValue,
                transactionCount: txns.count,
                trend: trend
            ))
            prevAvg = avgItems
        }

        return points
    }

    private struct ParsedTxn {
        let date: Date
        let itemCount: Int
        let totalAmount: Double
    }
}
