//
//  StockCheck.swift
//  Group5_RSMS
//

import Foundation

// MARK: - Audit Status

enum AuditStatus {
    case overdue    // pending & date is in the past
    case today      // scheduled for today
    case upcoming   // scheduled in the future
    case completed  // already done

    var label: String {
        switch self {
        case .overdue:   return "Overdue"
        case .today:     return "Today"
        case .upcoming:  return "Upcoming"
        case .completed: return "Completed"
        }
    }
}

// MARK: - StockCheck Model

struct StockCheck: Codable, Identifiable {
    let id: UUID
    let store_id: UUID
    let category_id: UUID
    var status: String
    let scheduled_date: String // Decode as String to avoid Supabase date formatting issues
    let schedule_id: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, status, scheduled_date, schedule_id
        case store_id = "store_id"
        case category_id = "category_id"
    }
    
    // Helper to convert String to Date for UI
    var date: Date {
        let formats = ["yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy"]
        let formatter = DateFormatter()
        for format in formats {
            formatter.dateFormat = format
            if let d = formatter.date(from: scheduled_date) {
                return d
            }
        }
        return Date()
    }
    
    // True when the check falls on today's calendar date
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Legacy helper (kept for backward compat)
    var isOverdue: Bool {
        status == "Pending" && Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date())
    }
    
    // Rich status computed from date + status
    var auditStatus: AuditStatus {
        if status == "Completed" { return .completed }
        let today = Calendar.current.startOfDay(for: Date())
        let checkDay = Calendar.current.startOfDay(for: date)
        if checkDay < today  { return .overdue }
        if checkDay == today { return .today }
        return .upcoming
    }
}
