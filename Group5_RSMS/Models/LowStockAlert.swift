//
//  LowStockAlert.swift
//  Group5_RSMS
//
//  Data model for low-stock inventory alerts.
//  Joins inventory, products, and stores tables.
//

import Foundation

/// Threshold below which an item is considered "low stock".
let kLowStockThreshold = 5

/// Threshold above which another store is considered a viable transfer source.
let kHighStockThreshold = 10

// MARK: - Low Stock Alert (Read Model)

/// Flat model decoded from a Supabase PostgREST join query:
/// `inventory?select=*,products(*),stores(*)`
struct LowStockAlert: Identifiable, Equatable {
    let productId: UUID
    let storeId: UUID
    let stockQuantity: Int
    let productName: String
    let productSku: String
    let productDescription: String?
    let productImageUrl: String?
    let productBasePrice: Double
    let storeName: String
    let storeCity: String

    /// Composite identifier
    var id: String { "\(productId.uuidString)-\(storeId.uuidString)" }
}

// MARK: - Decodable Conformance (PostgREST nested JSON)

extension LowStockAlert: Decodable {

    /// Nested product object returned by PostgREST join
    private struct EmbeddedProduct: Decodable {
        let id: UUID
        let sku: String
        let name: String
        let description: String?
        let base_price: Double
        let image_url: String?
    }

    /// Nested store object returned by PostgREST join
    private struct EmbeddedStore: Decodable {
        let id: UUID
        let name: String
        let city: String
    }

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case storeId = "store_id"
        case stockQuantity = "stock_quantity"
        case products
        case stores
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.productId = try container.decode(UUID.self, forKey: .productId)
        self.storeId = try container.decode(UUID.self, forKey: .storeId)
        self.stockQuantity = try container.decode(Int.self, forKey: .stockQuantity)

        // Resilient Product Decoding
        let product: EmbeddedProduct
        if let array = try? container.decode([EmbeddedProduct].self, forKey: .products), let first = array.first {
            product = first
        } else {
            product = try container.decode(EmbeddedProduct.self, forKey: .products)
        }
        self.productName = product.name
        self.productSku = product.sku
        self.productDescription = product.description
        self.productImageUrl = product.image_url
        self.productBasePrice = product.base_price

        // Resilient Store Decoding
        let store: EmbeddedStore
        if let array = try? container.decode([EmbeddedStore].self, forKey: .stores), let first = array.first {
            store = first
        } else {
            store = try container.decode(EmbeddedStore.self, forKey: .stores)
        }
        self.storeName = store.name
        self.storeCity = store.city
    }
}

// MARK: - Transfer Source (High-Stock Store)

/// Represents a store that has enough stock to be a transfer source.
struct TransferSource: Identifiable, Equatable {
    let storeId: UUID
    let storeName: String
    let storeCity: String
    let availableQuantity: Int

    var id: UUID { storeId }
}

extension TransferSource: Decodable {

    private struct EmbeddedStore: Decodable {
        let id: UUID
        let name: String
        let city: String
    }

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case stockQuantity = "stock_quantity"
        case stores
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.storeId = try container.decode(UUID.self, forKey: .storeId)
        self.availableQuantity = try container.decode(Int.self, forKey: .stockQuantity)

        let store = try container.decode(EmbeddedStore.self, forKey: .stores)
        self.storeName = store.name
        self.storeCity = store.city
    }
}
