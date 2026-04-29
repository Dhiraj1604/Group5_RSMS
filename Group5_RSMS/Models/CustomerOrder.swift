//
//  CustomerOrder.swift
//  Group5_RSMS
//

import Foundation

struct CustomerOrder: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let orderNumber: String
    var status: String
    let subtotal: Double
    let taxes: Double
    let deliveryFee: Double
    let shippingAddress: String?
    let paymentMethod: String?
    let estimatedDelivery: Date?
    let createdAt: Date
    let updatedAt: Date
    let pointsEarned: Int?
    let pointsRedeemed: Int?
    let discountAmount: Double?
    let storeId: UUID?
    let totalAmount: Double
    let itemCount: Int?
    let category: String?
    
    // Joined relationship array mapping to supabase "customer_order_items"
    let items: [CustomerOrderItem]?
    
    var consolidatedItems: [CustomerOrderItem] {
        guard let items = items else { return [] }
        var dict: [UUID: CustomerOrderItem] = [:]
        
        for item in items {
            if let existing = dict[item.productId] {
                var merged = existing
                merged.quantity += item.quantity
                dict[item.productId] = merged
            } else {
                dict[item.productId] = item
            }
        }
        return Array(dict.values).sorted { $0.createdAt < $1.createdAt }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case orderNumber = "order_number"
        case status
        case subtotal
        case taxes
        case deliveryFee = "delivery_fee"
        case shippingAddress = "shipping_address"
        case paymentMethod = "payment_method"
        case estimatedDelivery = "estimated_delivery"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case pointsEarned = "points_earned"
        case pointsRedeemed = "points_redeemed"
        case discountAmount = "discount_amount"
        case storeId = "store_id"
        case totalAmount = "total_amount"
        case itemCount = "item_count"
        case category
        case items = "customer_order_items"
    }
}

struct SimpleProduct: Codable {
    let name: String?
    let imageUrl: String?
    let description: String?
    let category: String?
    let basePrice: Double?
    let material: String?
    let originCountry: String?
    let craftsmanshipNotes: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case imageUrl = "image_url"
        case description
        case category
        case basePrice = "base_price"
        case material
        case originCountry = "origin_country"
        case craftsmanshipNotes = "craftsmanship_notes"
    }
}

struct CustomerOrderItem: Codable, Identifiable {
    let id: UUID
    let orderId: UUID
    let productId: UUID
    let variant: String?
    var quantity: Int
    let priceAtPurchase: Double
    let productName: String
    let productImageUrl: String?
    let createdAt: Date
    
    // Optional joined product mapping (if we need more product details)
    let product: SimpleProduct?
    
    enum CodingKeys: String, CodingKey {
        case id
        case orderId = "order_id"
        case productId = "product_id"
        case variant
        case quantity
        case priceAtPurchase = "price_at_purchase"
        case productName = "product_name"
        case productImageUrl = "product_image_url"
        case createdAt = "created_at"
        case product = "products"
    }
}
