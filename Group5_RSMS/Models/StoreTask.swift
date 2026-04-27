import Foundation

struct StoreTask: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var boutiqueId: UUID
    var title: String
    var description: String?
    var assignedTo: UUID? // Employee ID
    var isCompleted: Bool = false
    var dueDate: Date?
    var createdAt: Date? = Date()
    
    // Virtual property for UI grouping
    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId = "boutique_id"
        case title
        case description
        case assignedTo = "assigned_to"
        case isCompleted = "is_completed"
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}
