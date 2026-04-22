//
//  RevenueTrendsViewModel.swift
//  Group5_RSMS
//
//  Corporate Admin — Revenue Trends ViewModel
//  Fetches transactions from Supabase, aggregates daily/weekly/monthly revenue,
//  supports date-range filtering, store filtering, current-vs-previous period
//  comparison, and CSV export.
//

import Foundation
import Combine
import Supabase
import UniformTypeIdentifiers

@MainActor
class RevenueTrendsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var dailyData:   [RevenuePoint] = []
    @Published var weeklyData:  [RevenuePoint] = []
    @Published var monthlyData: [RevenuePoint] = []

    // Previous-period comparison
    @Published var prevDailyData:   [RevenuePoint] = []
    @Published var prevWeeklyData:  [RevenuePoint] = []
    @Published var prevMonthlyData: [RevenuePoint] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedPeriod: Period = .daily
    @Published var selectedStoreId: UUID? = nil    // nil = all stores
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @Published var endDate: Date = Date()
    @Published var showComparison: Bool = false

    private let client = SupabaseManager.shared.client

    // MARK: - Models

    struct RevenuePoint: Identifiable {
        let id = UUID()
        let label: String               // "21 Apr", "W/O 14 Apr", "Apr 2026"
        let periodStart: Date
        let revenue: Double
        let transactionCount: Int
        let avgOrderValue: Double
        let trend: Trend
    }

    enum Trend { case up, down, flat }

    enum Period: String, CaseIterable {
        case daily   = "Daily"
        case weekly  = "Weekly"
        case monthly = "Monthly"
    }

    // MARK: - Computed

    var activeTrendData: [RevenuePoint] {
        switch selectedPeriod {
        case .daily:   return dailyData
        case .weekly:  return weeklyData
        case .monthly: return monthlyData
        }
    }

    var prevTrendData: [RevenuePoint] {
        switch selectedPeriod {
        case .daily:   return prevDailyData
        case .weekly:  return prevWeeklyData
        case .monthly: return prevMonthlyData
        }
    }

    var totalRevenue: Double {
        activeTrendData.map(\.revenue).reduce(0, +)
    }

    var totalTransactions: Int {
        activeTrendData.map(\.transactionCount).reduce(0, +)
    }

    var avgOrderValue: Double {
        guard totalTransactions > 0 else { return 0 }
        return totalRevenue / Double(totalTransactions)
    }

    var prevTotalRevenue: Double {
        prevTrendData.map(\.revenue).reduce(0, +)
    }

    var revenueGrowthPercent: Double? {
        guard prevTotalRevenue > 0 else { return nil }
        return ((totalRevenue - prevTotalRevenue) / prevTotalRevenue) * 100
    }

    /// Duration in days of the selected range
    var rangeDays: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }

    // MARK: - Quick Range Helpers

    enum QuickRange: String, CaseIterable {
        case last7   = "7D"
        case last14  = "14D"
        case last30  = "30D"
        case last90  = "90D"

        var days: Int {
            switch self {
            case .last7:  return 7
            case .last14: return 14
            case .last30: return 30
            case .last90: return 90
            }
        }
    }

    func applyQuickRange(_ range: QuickRange) {
        endDate = Date()
        startDate = Calendar.current.date(byAdding: .day, value: -range.days, to: endDate)!
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

    func fetchRevenue() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch current period
            let currentRows = try await fetchRows(from: startDate, to: endDate)
            let currentParsed = parseRows(currentRows)

            self.dailyData   = aggregateDaily(currentParsed)
            self.weeklyData  = aggregateWeekly(currentParsed)
            self.monthlyData = aggregateMonthly(currentParsed)

            // Fetch previous period (same duration, shifted back)
            let duration = endDate.timeIntervalSince(startDate)
            let prevEnd   = startDate
            let prevStart = prevEnd.addingTimeInterval(-duration)

            let prevRows = try await fetchRows(from: prevStart, to: prevEnd)
            let prevParsed = parseRows(prevRows)

            self.prevDailyData   = aggregateDaily(prevParsed)
            self.prevWeeklyData  = aggregateWeekly(prevParsed)
            self.prevMonthlyData = aggregateMonthly(prevParsed)

        } catch {
            print("❌ Failed to fetch revenue: \(error)")
            errorMessage = "Failed to load revenue data."
        }

        isLoading = false
    }

    private func fetchRows(from start: Date, to end: Date) async throws -> [TransactionRow] {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        var query = client
            .from("customer_orders")
            .select("id, store_id, item_count, total_amount, category, created_at")
            .gte("created_at", value: isoFormatter.string(from: start))
            .lte("created_at", value: isoFormatter.string(from: end))

        if let storeId = selectedStoreId {
            query = query.eq("store_id", value: storeId)
        }

        return try await query
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    // MARK: - Parsing

    private struct ParsedTransaction {
        let date: Date
        let amount: Double
        let itemCount: Int
    }

    private func parseRows(_ rows: [TransactionRow]) -> [ParsedTransaction] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()

        return rows.compactMap { row in
            guard let date = formatter.date(from: row.created_at)
                    ?? fallback.date(from: row.created_at) else { return nil }
            return ParsedTransaction(date: date, amount: row.total_amount, itemCount: row.item_count)
        }
    }

    // MARK: - Aggregation

    private func aggregateDaily(_ txns: [ParsedTransaction]) -> [RevenuePoint] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: txns) { txn -> Date in
            cal.startOfDay(for: txn.date)
        }

        let sorted = grouped.sorted { $0.key < $1.key }
        var points: [RevenuePoint] = []
        var prevRev: Double?

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"

        for (dayStart, txns) in sorted {
            let revenue = txns.map(\.amount).reduce(0, +)
            let count = txns.count
            let aov = count > 0 ? revenue / Double(count) : 0
            let trend = calcTrend(current: revenue, previous: prevRev)

            points.append(RevenuePoint(
                label: dateFormatter.string(from: dayStart),
                periodStart: dayStart,
                revenue: revenue,
                transactionCount: count,
                avgOrderValue: aov,
                trend: trend
            ))
            prevRev = revenue
        }
        return points
    }

    private func aggregateWeekly(_ txns: [ParsedTransaction]) -> [RevenuePoint] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: txns) { txn -> Date in
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: txn.date)
            return cal.date(from: comps) ?? txn.date
        }

        let sorted = grouped.sorted { $0.key < $1.key }
        var points: [RevenuePoint] = []
        var prevRev: Double?

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM"

        for (weekStart, txns) in sorted {
            let revenue = txns.map(\.amount).reduce(0, +)
            let count = txns.count
            let aov = count > 0 ? revenue / Double(count) : 0
            let trend = calcTrend(current: revenue, previous: prevRev)

            points.append(RevenuePoint(
                label: "W/O \(dateFormatter.string(from: weekStart))",
                periodStart: weekStart,
                revenue: revenue,
                transactionCount: count,
                avgOrderValue: aov,
                trend: trend
            ))
            prevRev = revenue
        }
        return points
    }

    private func aggregateMonthly(_ txns: [ParsedTransaction]) -> [RevenuePoint] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: txns) { txn -> Date in
            let comps = cal.dateComponents([.year, .month], from: txn.date)
            return cal.date(from: comps) ?? txn.date
        }

        let sorted = grouped.sorted { $0.key < $1.key }
        var points: [RevenuePoint] = []
        var prevRev: Double?

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        for (monthStart, txns) in sorted {
            let revenue = txns.map(\.amount).reduce(0, +)
            let count = txns.count
            let aov = count > 0 ? revenue / Double(count) : 0
            let trend = calcTrend(current: revenue, previous: prevRev)

            points.append(RevenuePoint(
                label: dateFormatter.string(from: monthStart),
                periodStart: monthStart,
                revenue: revenue,
                transactionCount: count,
                avgOrderValue: aov,
                trend: trend
            ))
            prevRev = revenue
        }
        return points
    }

    private func calcTrend(current: Double, previous: Double?) -> Trend {
        guard let prev = previous else { return .flat }
        let threshold = prev * 0.02 // 2% change threshold
        if current > prev + threshold { return .up }
        if current < prev - threshold { return .down }
        return .flat
    }

    // MARK: - CSV Export

    func generateCSV() -> String {
        var csv = "Period,Revenue (₹),Transactions,Avg Order Value (₹),Trend\n"

        for point in activeTrendData {
            let trendStr: String
            switch point.trend {
            case .up:   trendStr = "↑"
            case .down: trendStr = "↓"
            case .flat: trendStr = "→"
            }
            csv += "\(point.label),\(String(format: "%.2f", point.revenue)),\(point.transactionCount),\(String(format: "%.2f", point.avgOrderValue)),\(trendStr)\n"
        }

        // Summary row
        csv += "\nSummary\n"
        csv += "Total Revenue,₹\(String(format: "%.2f", totalRevenue))\n"
        csv += "Total Transactions,\(totalTransactions)\n"
        csv += "Avg Order Value,₹\(String(format: "%.2f", avgOrderValue))\n"

        if let growth = revenueGrowthPercent {
            csv += "Growth vs Previous Period,\(String(format: "%.1f", growth))%\n"
        }

        return csv
    }

    func csvFileURL() -> URL? {
        let csv = generateCSV()
        let fileName = "revenue_report_\(DateFormatter.fileTimestamp.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("❌ Failed to write CSV: \(error)")
            return nil
        }
    }

    // Simple Excel export – we generate a CSV file with .xlsx extension; Excel can open it.
    func excelFileURL() -> URL? {
        let csv = generateCSV()
        let fileName = "revenue_report_\(DateFormatter.fileTimestamp.string(from: Date())).xlsx"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("❌ Failed to write Excel (CSV) file: \(error)")
            return nil
        }
    }
}

// MARK: - DateFormatter extension

private extension DateFormatter {
    static let fileTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()
}
