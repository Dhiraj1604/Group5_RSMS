//
//  SalesTransactionsViewModel.swift
//  Group5_RSMS
//
//  Corporate Admin — Sales Transactions ViewModel
//  Fetches full transactions from customer_orders, supports store/date filtering.
//

import Foundation
import Combine
import Supabase

@MainActor
class SalesTransactionsViewModel: ObservableObject {

    // MARK: - Published State
    @Published var transactions: [SalesTransaction] = []
    @Published var stores: [TxnStore] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Filters
    @Published var selectedStoreId: UUID? = nil
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @Published var endDate: Date = Date()
    @Published var searchText: String = ""

    private let client = SupabaseManager.shared.client

    // MARK: - Models

    struct TxnStore: Identifiable, Decodable {
        let id: UUID
        let name: String
        let city: String
    }

    // MARK: - Computed

    var filteredTransactions: [SalesTransaction] {
        var list = transactions
        if !searchText.isEmpty {
            list = list.filter {
                $0.storeName.localizedCaseInsensitiveContains(searchText) ||
                ($0.category ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }

    // MARK: - Fetch

    private struct RawTransaction: Decodable {
        let id: UUID
        let store_id: UUID?
        let item_count: Int
        let total_amount: Double
        let category: String?
        let created_at: String
    }

    func fetchTransactions() async {
        isLoading = true
        errorMessage = nil

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        do {
            var query = client
                .from("customer_orders")
                .select("id, store_id, item_count, total_amount, category, created_at")
                .gte("created_at", value: isoFormatter.string(from: startDate))
                .lte("created_at", value: isoFormatter.string(from: endDate))

            if let storeId = selectedStoreId {
                query = query.eq("store_id", value: storeId)
            }

            let rows: [RawTransaction] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value

            let storeMap = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0.name) })

            let dateParser = ISO8601DateFormatter()
            dateParser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let fallback = ISO8601DateFormatter()

            self.transactions = rows.compactMap { row in
                guard let date = dateParser.date(from: row.created_at)
                        ?? fallback.date(from: row.created_at) else { return nil }
                let storeName = row.store_id.flatMap { storeMap[$0] } ?? "Unknown Store"
                return SalesTransaction(
                    id: row.id,
                    date: date,
                    storeId: row.store_id,
                    storeName: storeName,
                    itemCount: row.item_count,
                    totalAmount: row.total_amount,
                    category: row.category
                )
            }
        } catch {
            errorMessage = "Failed to load transactions."
            print("❌ SalesTransactionsVM: \(error)")
        }

        isLoading = false
    }

    func fetchStores() async {
        do {
            let result: [TxnStore] = try await client
                .from("stores")
                .select("id, name, city")
                .order("name")
                .execute()
                .value
            self.stores = result
        } catch {
            print("❌ Failed to fetch stores: \(error)")
        }
    }
}

// MARK: - SalesTransaction Model

struct SalesTransaction: Identifiable {
    let id: UUID
    let date: Date
    let storeId: UUID?
    let storeName: String
    let itemCount: Int
    let totalAmount: Double
    let category: String?
}
