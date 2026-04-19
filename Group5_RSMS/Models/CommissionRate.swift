//
//  CommissionRate.swift
//  Group5_RSMS
//
//  Created by Apple on 19/04/26.
//

import Foundation

struct CommissionRate: Codable, Identifiable {
    let id: UUID
    let boutiqueId: UUID
    let employeeId: UUID
    let ratePercentage: Double
    let effectiveFrom: Date
    let effectiveTo: Date?
    let createdBy: UUID?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId       = "boutique_id"
        case employeeId       = "employee_id"
        case ratePercentage   = "rate_percentage"
        case effectiveFrom    = "effective_from"
        case effectiveTo      = "effective_to"
        case createdBy        = "created_by"
        case createdAt        = "created_at"
    }
}
