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
        
        // Supabase returns dates as strings, use ISO8601 formatting or standard Decode strategy
        // It's safer to map to Date if we have a DateDecoder, otherwise decode as String and map.
        // For simplicity, we decode as Date directly (assuming the client dateDecodingStrategy is ISO8601).
        if let dateString = try? container.decode(String.self, forKey: .createdAt),
           let date = ISO8601DateFormatter().date(from: dateString) {
            self.createdAt = date
        } else {
            self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        }
        
        let product = try container.decode(EmbeddedProduct.self, forKey: .products)
        self.productName = product.name
        self.productSku = product.sku
        self.productImageUrl = product.image_url
        
        let reqStore = try container.decode(EmbeddedStore.self, forKey: .requesting_store)
        self.requestingStoreName = reqStore.name
        self.requestingStoreCity = reqStore.city
        
        let fullStore = try container.decode(EmbeddedStore.self, forKey: .fulfilling_store)
        self.fulfillingStoreName = fullStore.name
        self.fulfillingStoreCity = fullStore.city
    }
}
