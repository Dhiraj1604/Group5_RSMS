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
    let category_id: UUID
    let image_Url: String?
    let created_at: Date
    let inRepair: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, sku, name, description, created_at, inRepair
        case base_Price = "base_price"
        case category_id = "category_id"
        case image_Url = "image_url"
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
