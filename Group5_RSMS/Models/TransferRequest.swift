//
//  TransferRequest.swift
//  Group5_RSMS
//
//  Data model for inter-store transfer requests.
//  Represents a 'Pull' action from one store to another.
//

import Foundation

enum TransferRequestStatus: String, Codable {
    case pending = "pending"
    case fulfilled = "fulfilled"
    case rejected = "rejected"
}

/// Represents a transfer request fetched via PostgREST join:
/// `transfer_requests?select=*,products(*),requesting_store:requesting_store_id(*),fulfilling_store:fulfilling_store_id(*)`
struct TransferRequest: Identifiable, Equatable {
    let id: UUID
    let requestingStoreId: UUID
    let fulfillingStoreId: UUID
    let productId: UUID
    let quantity: Int
    let status: TransferRequestStatus
    let createdAt: Date
    
    // Joined data
    let productName: String
    let productSku: String
    let productImageUrl: String?
    
    let requestingStoreName: String
    let requestingStoreCity: String
    
    let fulfillingStoreName: String
    let fulfillingStoreCity: String
}

// MARK: - Decodable Conformance (PostgREST nested JSON)

extension TransferRequest: Decodable {
    
    private struct EmbeddedProduct: Decodable {
        let name: String
        let sku: String
        let image_url: String?
    }
    
    private struct EmbeddedStore: Decodable {
        let name: String
        let city: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case requestingStoreId = "requesting_store_id"
        case fulfillingStoreId = "fulfilling_store_id"
        case productId = "product_id"
        case quantity
        case status
        case createdAt = "created_at"
        
        case products
        case requesting_store
        case fulfilling_store
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.requestingStoreId = try container.decode(UUID.self, forKey: .requestingStoreId)
        self.fulfillingStoreId = try container.decode(UUID.self, forKey: .fulfillingStoreId)
        self.productId = try container.decode(UUID.self, forKey: .productId)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        
        let statusString = try container.decode(String.self, forKey: .status)
        self.status = TransferRequestStatus(rawValue: statusString) ?? .pending
        
        // Robust Date Decoding
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        
        // Try fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            self.createdAt = date
        } else {
            // Fallback to standard ISO8601
            formatter.formatOptions = [.withInternetDateTime]
            self.createdAt = formatter.date(from: dateString) ?? Date()
        }
        
        // Resilient Product Decoding (Handle Single Object or Single-Item Array)
        let product: EmbeddedProduct
        if let array = try? container.decode([EmbeddedProduct].self, forKey: .products), let first = array.first {
            product = first
        } else {
            product = try container.decode(EmbeddedProduct.self, forKey: .products)
        }
        self.productName = product.name
        self.productSku = product.sku
        self.productImageUrl = product.image_url
        
        // Resilient Requesting Store Decoding
        let reqStore: EmbeddedStore
        if let array = try? container.decode([EmbeddedStore].self, forKey: .requesting_store), let first = array.first {
            reqStore = first
        } else {
            reqStore = try container.decode(EmbeddedStore.self, forKey: .requesting_store)
        }
        self.requestingStoreName = reqStore.name
        self.requestingStoreCity = reqStore.city
        
        // Resilient Fulfilling Store Decoding
        let fullStore: EmbeddedStore
        if let array = try? container.decode([EmbeddedStore].self, forKey: .fulfilling_store), let first = array.first {
            fullStore = first
        } else {
            fullStore = try container.decode(EmbeddedStore.self, forKey: .fulfilling_store)
        }
        self.fulfillingStoreName = fullStore.name
        self.fulfillingStoreCity = fullStore.city
    }
}
