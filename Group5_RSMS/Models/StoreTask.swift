import Foundation

enum TaskStatus: String, Codable {
    case pending = "pending"
    case completedByStaff = "completed_by_staff"
    case verified = "verified"
}

struct StoreTask: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var boutiqueId: UUID
    var title: String
    var description: String?
    var assignedTo: UUID? // Employee ID
    var status: TaskStatus = .pending
    var dueDate: Date?
    var createdAt: Date? = Date()
    
    // Virtual property for UI grouping
    var isOverdue: Bool {
        guard let due = dueDate, status == .pending else { return false }
        return due < Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId = "boutique_id"
        case title
        case description
        case assignedTo = "assigned_to"
        case status
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}
