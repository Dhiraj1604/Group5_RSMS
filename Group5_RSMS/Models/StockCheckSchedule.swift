//
//  StockCheckSchedule.swift
//  Group5_RSMS
//
//  Represents a recurring stock-check schedule for a category.
//  day_of_week: 1 = Monday … 7 = Sunday (ISO weekday).
//

import Foundation

struct StockCheckSchedule: Codable, Identifiable {
    let id: UUID
    let store_id: UUID
    let category_id: UUID
    let day_of_week: Int  // 1 = Monday … 7 = Sunday

    enum CodingKeys: String, CodingKey {
        case id, day_of_week
        case store_id    = "store_id"
        case category_id = "category_id"
    }

    /// Human-readable day name derived from the ISO weekday integer.
    var dayName: String {
        let names = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard day_of_week >= 1 && day_of_week <= 7 else { return "Unknown" }
        return names[day_of_week]
    }
}
