//
//  StockAnalysisViewModel.swift
//  Group5_RSMS
//
//  ViewModel for the Corporate Admin Stock Analysis feature.
//  Fetches inventory data for a selected store and computes
//  low-stock / overstock flags.
//

import Foundation
import Supabase
import Combine

@MainActor
class StockAnalysisViewModel: ObservableObject {

    // MARK: - Published State
    @Published var inventoryItems: [StockItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var selectedFilter: StockFilter = .all

    private let client = SupabaseManager.shared.client

    // MARK: - Stock Item Model

    struct StockItem: Identifiable, Equatable {
        let productId: UUID
        let storeId: UUID
        let productName: String
        let sku: String
        let category: String
        let stockQuantity: Int
        let basePrice: Double

        var id: String { "\(productId)-\(storeId)" }

        var stockStatus: StockStatus {
            if stockQuantity <= 0 { return .outOfStock }
            if stockQuantity < kLowStockThreshold { return .low }
            if stockQuantity > kHighStockThreshold { return .overstock }
            return .normal
        }
    }

    enum StockStatus: String, CaseIterable {
        case outOfStock = "Out of Stock"
        case low = "Low Stock"
        case normal = "In Stock"
        case overstock = "Overstock"

        var color: String {
            switch self {
            case .outOfStock: return "red"
            case .low: return "orange"
            case .normal: return "green"
            case .overstock: return "blue"
            }
        }

        var icon: String {
            switch self {
            case .outOfStock: return "xmark.circle.fill"
            case .low: return "exclamationmark.triangle.fill"
            case .normal: return "checkmark.circle.fill"
            case .overstock: return "arrow.up.circle.fill"
            }
        }
    }

    enum StockFilter: String, CaseIterable {
        case all = "All"
        case low = "Low Stock"
        case overstock = "Overstock"
        case outOfStock = "Out of Stock"
    }

    // MARK: - Computed

    var filteredItems: [StockItem] {
        var result = inventoryItems

        switch selectedFilter {
        case .all: break
        case .low: result = result.filter { $0.stockStatus == .low }
        case .overstock: result = result.filter { $0.stockStatus == .overstock }
        case .outOfStock: result = result.filter { $0.stockStatus == .outOfStock }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.productName.lowercased().contains(q) ||
                $0.sku.lowercased().contains(q)
            }
        }

        return result.sorted { $0.stockQuantity < $1.stockQuantity }
    }

    var summary: (total: Int, low: Int, overstock: Int, outOfStock: Int) {
        let low = inventoryItems.filter { $0.stockStatus == .low }.count
        let over = inventoryItems.filter { $0.stockStatus == .overstock }.count
        let oos = inventoryItems.filter { $0.stockStatus == .outOfStock }.count
        return (inventoryItems.count, low, over, oos)
    }

    // MARK: - Fetch

    /// Decodable struct matching the PostgREST nested join:
    /// `inventory?select=product_id,store_id,stock_quantity,products(*)`
    private struct InventoryRow: Decodable {
        let product_id: UUID
        let store_id: UUID
        let stock_quantity: Int
        let products: EmbeddedProduct

        struct EmbeddedProduct: Decodable {
            let name: String
            let sku: String
            let category: String?
            let base_price: Double
        }
    }

    func fetchInventory(forStore storeId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            let rows: [InventoryRow] = try await client
                .from("inventory")
                .select("product_id, store_id, stock_quantity, products(name, sku, category, base_price)")
                .eq("store_id", value: storeId)
                .order("stock_quantity", ascending: true)
                .execute()
                .value

            self.inventoryItems = rows.map { row in
                StockItem(
                    productId: row.product_id,
                    storeId: row.store_id,
                    productName: row.products.name,
                    sku: row.products.sku,
                    category: row.products.category ?? "Other",
                    stockQuantity: row.stock_quantity,
                    basePrice: row.products.base_price
                )
            }
        } catch {
            print("❌ Failed to fetch inventory: \(error)")
            errorMessage = "Failed to load inventory: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
