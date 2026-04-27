//
//  Shift.swift
//  Group5_RSMS
//

import Foundation

struct Shift: Codable, Identifiable {
    let id: UUID
    let boutiqueId: UUID
    let employeeId: UUID
    var startTime: Date
    var endTime: Date
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId = "boutique_id"
        case employeeId = "employee_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case createdAt = "created_at"
    }
}
