//
//  Product.swift
//  Group5_RSMS
//
//  Created by Apple on 16/04/26.
//

import Foundation


struct InventoryProduct: Codable, Identifiable {
    let id: UUID
    let sku: String
    let name: String
    let description: String?
    let base_Price: Double
    let category_id: UUID?
    let image_Url: String?
    let created_at: Date
    let inRepair: Bool
    let is_on_floor: Bool
    let last_moved_to_floor: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, sku, name, description, created_at
        case base_Price = "base_price"
        case category_id = "category_id"
        case image_Url = "image_url"
        case is_on_floor, last_moved_to_floor
        case inRepair = "in_repair"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.sku = try container.decodeIfPresent(String.self, forKey: .sku) ?? "N/A"
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.base_Price = try container.decodeIfPresent(Double.self, forKey: .base_Price) ?? 0.0
        self.category_id = try container.decodeIfPresent(UUID.self, forKey: .category_id)
        self.image_Url = try container.decodeIfPresent(String.self, forKey: .image_Url)
        self.inRepair = try container.decodeIfPresent(Bool.self, forKey: .inRepair) ?? false
        self.is_on_floor = try container.decodeIfPresent(Bool.self, forKey: .is_on_floor) ?? false
        
        self.created_at = try container.decodeIfPresent(Date.self, forKey: .created_at) ?? Date()
        self.last_moved_to_floor = try container.decodeIfPresent(Date.self, forKey: .last_moved_to_floor)
    }

    // Manual initializer for joined mapping
    init(id: UUID, sku: String, name: String, description: String?, base_Price: Double, category_id: UUID?, image_Url: String?, created_at: Date, inRepair: Bool, is_on_floor: Bool, last_moved_to_floor: Date?) {
        self.id = id
        self.sku = sku
        self.name = name
        self.description = description
        self.base_Price = base_Price
        self.category_id = category_id
        self.image_Url = image_Url
        self.created_at = created_at
        self.inRepair = inRepair
        self.is_on_floor = is_on_floor
        self.last_moved_to_floor = last_moved_to_floor
    }
}


// MARK: - Repair Models

struct Repair: Codable, Identifiable {
    let id: UUID
    let product_id: UUID
    let status: String
    let issue_description: String
    let repair_cost: Double
    let technician_id: UUID?
    let sent_at: Date
    let resolved_at: Date?

    enum CodingKeys: String, CodingKey {
        case id, product_id, status, issue_description, repair_cost
        case technician_id, sent_at, resolved_at
    }
}

struct RepairInsertPayload: Encodable {
    let product_id: UUID
    let status: String
    let issue_description: String
    let repair_cost: Double
    let technician_id: UUID?
    let sent_at: String

    init(
        product_id: UUID,
        issueDescription: String,
        repairCost: Double,
        technicianId: UUID? = nil
    ) {
        self.product_id = product_id
        self.status = "Pending"
        self.issue_description = issueDescription
        self.repair_cost = repairCost
        self.technician_id = technicianId
        self.sent_at = Date().ISO8601Format()
    }
}
