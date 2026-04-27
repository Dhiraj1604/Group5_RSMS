//
//  StockCheckService.swift
//  Group5_RSMS
//

import Foundation
import Supabase

class StockCheckService {
    static let shared = StockCheckService()
    private let client = SupabaseManager.shared.client
    
    func fetchUpcomingChecks(forStore storeId: UUID) async throws -> [StockCheck] {
        let response: [StockCheck] = try await client
            .from("stock_checks")
            .select("*")
            .eq("store_id", value: storeId)
            // .eq("status", value: "Pending") // Temporarily disabled for debugging
            .order("scheduled_date", ascending: true)
            .execute()
            .value
        return response
    }
    
    func scheduleCheck(storeId: UUID, categoryId: UUID, date: Date) async throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let dateString = formatter.string(from: date)
        
        try await client
            .from("stock_checks")
            .insert([
                "store_id": storeId.uuidString,
                "category_id": categoryId.uuidString,
                "scheduled_date": dateString,
                "status": "Pending"
            ])
            .execute()
    }

    func fetchLastAuditDate(forStore storeId: UUID) async throws -> Date? {
        let response: [StockCheck] = try await client
            .from("stock_checks")
            .select("*")
            .eq("store_id", value: storeId)
            .eq("status", value: "Completed")
            .order("scheduled_date", ascending: false)
            .limit(1)
            .execute()
            .value
        return response.first?.date
    }

    /// Fetches all recurring stock-check schedules for a store.
    /// Each row maps a category to a fixed day_of_week (1 = Monday … 7 = Sunday).
    func fetchSchedules(forStore storeId: UUID) async throws -> [StockCheckSchedule] {
        let response: [StockCheckSchedule] = try await client
            .from("stock_check_schedules")
            .select("*")
            .eq("store_id", value: storeId)
            .execute()
            .value
        return response
    }

    // MARK: - Complete a Check

    /// Sets a stock check's status to "Completed".
    func markAsCompleted(checkId: UUID) async throws {
        try await client
            .from("stock_checks")
            .update(["status": "Completed"])
            .eq("id", value: checkId)
            .execute()
    }

    // MARK: - Category Products (for discrepancy entry)

    /// Lightweight product record — only what we need for count entry.
    struct CategoryProduct: Decodable, Identifiable {
        let id: UUID
        let name: String
        let sku: String
    }

    /// Fetches all products belonging to a specific category.
    func fetchCategoryProducts(categoryId: UUID) async throws -> [CategoryProduct] {
        let response: [CategoryProduct] = try await client
            .from("products")
            .select("id, name, sku")
            .eq("category_id", value: categoryId)
            .order("name", ascending: true)
            .execute()
            .value
        return response
    }

    /// Returns a map of productId → stockQuantity for a store (for all products).
    func fetchStoreInventoryMap(storeId: UUID) async throws -> [UUID: Int] {
        struct InventoryRow: Decodable { let product_id: UUID; let stock_quantity: Int }
        let rows: [InventoryRow] = try await client
            .from("inventory")
            .select("product_id, stock_quantity")
            .eq("store_id", value: storeId)
            .execute()
            .value
        return Dictionary(uniqueKeysWithValues: rows.map { ($0.product_id, $0.stock_quantity) })
    }

    // MARK: - Discrepancy Submission

    /// Batch-inserts discrepancy records into `inventory_discrepancies`.
    func submitDiscrepancies(_ payloads: [DiscrepancyPayload]) async throws {
        guard !payloads.isEmpty else { return }
        try await client
            .from("inventory_discrepancies")
            .insert(payloads)
            .execute()
    }

    // MARK: - Inventory Adjustment

    /// Updates the stock quantity for a product at a specific store.
    func adjustInventory(productId: UUID, storeId: UUID, newQuantity: Int) async throws {
        try await client
            .from("inventory")
            .update(["stock_quantity": newQuantity])
            .eq("product_id", value: productId)
            .eq("store_id", value: storeId)
            .execute()
    }
}
