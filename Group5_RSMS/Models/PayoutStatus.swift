//
//  PayoutStatus.swift
//  Group5_RSMS
//
//  Created by Apple on 19/04/26.
//

import Foundation

enum PayoutStatus: String, Codable {
    case pending  = "pending"
    case approved = "approved"
    case paid     = "paid"
}

struct CommissionPayout: Codable, Identifiable {
    let id: UUID
    let boutiqueId: UUID
    let employeeId: UUID
    let periodStart: Date
    let periodEnd: Date
    let totalSalesAmount: Double
    let commissionRate: Double
    let commissionAmount: Double
    let status: PayoutStatus
    let approvedBy: UUID?
    let approvedAt: Date?
    let payoutDate: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId        = "boutique_id"
        case employeeId        = "employee_id"
        case periodStart       = "period_start"
        case periodEnd         = "period_end"
        case totalSalesAmount  = "total_sales_amount"
        case commissionRate    = "commission_rate"
        case commissionAmount  = "commission_amount"
        case status
        case approvedBy        = "approved_by"
        case approvedAt        = "approved_at"
        case payoutDate        = "payout_date"
        case createdAt         = "created_at"
    }
}
