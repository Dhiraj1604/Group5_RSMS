//
//  ICReportsService.swift
//  Group5_RSMS
//

import Foundation
import Supabase

struct VarianceReportItem: Codable, Identifiable {
    let id: UUID
    let expectedQuantity: Int
    let actualScannedQuantity: Int
    let createdAt: Date
    let product: SimpleProduct?
    let store: SimpleStore?

    enum CodingKeys: String, CodingKey {
        case id
        case expectedQuantity = "expected_quantity"
        case actualScannedQuantity = "actual_scanned_quantity"
        case createdAt = "created_at"
        case product = "products"
        case store = "stores"
    }

    var variance: Int {
        actualScannedQuantity - expectedQuantity
    }
}

struct SimpleStore: Codable {
    let name: String
}

struct SimpleProductWithCategory: Codable {
    let name: String
    let category: String?
}

struct InventoryItem: Codable {
    let productId: UUID
    let storeId: UUID
    let stockQuantity: Int
    let isOnFloor: Bool?
    let minStockLevel: Int?
    let maxStockLevel: Int?
    let product: SimpleProductWithCategory?
    let store: SimpleStore?

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case storeId = "store_id"
        case stockQuantity = "stock_quantity"
        case isOnFloor = "is_on_floor"
        case minStockLevel = "min_stock_level"
        case maxStockLevel = "max_stock_level"
        case product = "products"
        case store = "stores"
    }
}

class ICReportsService {
    private let client = SupabaseManager.shared.client

    func fetchVarianceReport(storeId: UUID?) async throws -> [VarianceReportItem] {
        var query = client
            .from("inventory_discrepancies")
            .select("*, products(name), stores(name)")
        
        if let storeId = storeId {
            query = query.eq("store_id", value: storeId)
        }
            
        let response: [VarianceReportItem] = try await query
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
        return response
    }

    func fetchInventoryHeatMapData(storeId: UUID?) async throws -> [InventoryItem] {
        var query = client
            .from("inventory")
            .select("*, products(name, category), stores(name)")
            
        if let storeId = storeId {
            query = query.eq("store_id", value: storeId)
        }
        
        let response: [InventoryItem] = try await query
            .execute()
            .value
        return response
    }
}
