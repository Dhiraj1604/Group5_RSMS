//
//  PricingModels.swift
//  Group5_RSMS
//
//  Core/Pricing
//

import Foundation

/// Represents a retail product in the inventory.
public struct Product: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let sku: String
    public let name: String
    public let basePrice: Double
    public let categoryId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case name
        case basePrice = "base_price"
        case categoryId = "category_id"
    }
    
    public init(id: UUID = UUID(), sku: String, name: String, basePrice: Double, categoryId: UUID? = nil) {
        self.id = id
        self.sku = sku
        self.name = name
        self.basePrice = basePrice
        self.categoryId = categoryId
    }
}

/// Defines a regional tax rule aligned with the `tax_rules` Supabase table.
public struct TaxRule: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var rate: Double          // e.g. 0.20 = 20%
    public var isInclusive: Bool
    public var storeId: UUID

    // MARK: - CodingKeys for Supabase (Read)
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rate
        case isInclusive = "is_inclusive"
        case storeId = "store_id"
    }

    // MARK: - Insert/Update Payload for Supabase (Write)
    public struct DBPayload: Encodable {
        let name: String
        let rate: Double
        let is_inclusive: Bool
        let store_id: UUID
    }

    public var dbPayload: DBPayload {
        DBPayload(
            name: name,
            rate: rate,
            is_inclusive: isInclusive,
            store_id: storeId
        )
    }

    public init(
        id: UUID = UUID(),
        name: String,
        rate: Double,
        isInclusive: Bool,
        storeId: UUID = UUID()
    ) {
        self.id = id
        self.name = name
        self.rate = rate
        self.isInclusive = isInclusive
        self.storeId = storeId
    }
}

/// The result format of a pricing calculation.
public struct PricingBreakdown: Equatable, Hashable {
    public let subtotal: Double
    public let taxAmount: Double
    public let total: Double
    
    public init(subtotal: Double, taxAmount: Double, total: Double) {
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.total = total
    }
}
