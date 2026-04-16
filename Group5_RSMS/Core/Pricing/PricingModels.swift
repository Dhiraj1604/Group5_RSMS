//
//  PricingModels.swift
//  Group5_RSMS
//
//  Core/Pricing
//

import Foundation

/// Represents a retail product in the inventory.
public struct Product: Identifiable, Codable, Equatable {
    public let id: UUID
    public let sku: String
    public let name: String
    public let basePrice: Double
    public let categoryId: UUID?
    public let description: String?
    public let imageUrl: String?
    public let inRepair: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case name
        case basePrice = "base_price"
        case categoryId = "category_id"
        case description
        case imageUrl = "image_url"
        case inRepair
    }
    
    public init(
        id: UUID = UUID(),
        sku: String,
        name: String,
        basePrice: Double,
        categoryId: UUID? = nil,
        description: String? = nil,
        imageUrl: String? = nil,
        inRepair: Bool = false
    ) {
        self.id = id
        self.sku = sku
        self.name = name
        self.basePrice = basePrice
        self.categoryId = categoryId
        self.description = description
        self.imageUrl = imageUrl
        self.inRepair = inRepair
    }
    
    // Custom decoder to provide defaults for missing keys
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.sku = try container.decode(String.self, forKey: .sku)
        self.name = try container.decode(String.self, forKey: .name)
        self.basePrice = try container.decode(Double.self, forKey: .basePrice)
        self.categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.inRepair = (try? container.decode(Bool.self, forKey: .inRepair)) ?? false
    }
}

/// Defines a regional tax rule aligned with the `tax_rules` Supabase table.
public struct TaxRule: Identifiable, Codable, Equatable {
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
public struct PricingBreakdown: Equatable {
    public let subtotal: Double
    public let taxAmount: Double
    public let total: Double
    
    public init(subtotal: Double, taxAmount: Double, total: Double) {
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.total = total
    }
}
