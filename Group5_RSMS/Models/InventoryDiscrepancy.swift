//
//  InventoryDiscrepancy.swift
//  Group5_RSMS
//
//  Model for the `inventory_discrepancies` Supabase table.
//  Logged when an IC's physical count differs from the system quantity.
//

import Foundation

// MARK: - Model (for reads)

struct InventoryDiscrepancy: Codable, Identifiable {
    let id: UUID
    let product_id: UUID
    let store_id: UUID
    let expected_quantity: Int
    let actual_scanned_quantity: Int
    let created_by: UUID?
    let created_at: Date?

    /// Positive = surplus, negative = shrinkage
    var discrepancy: Int { actual_scanned_quantity - expected_quantity }
    var isShrinkage: Bool { discrepancy < 0 }
    var hasMismatch: Bool { discrepancy != 0 }
}

// MARK: - Insert Payload (for writes)

struct DiscrepancyPayload: Encodable {
    let product_id: UUID
    let store_id: UUID
    let expected_quantity: Int
    let actual_scanned_quantity: Int
    let created_by: UUID?
}
