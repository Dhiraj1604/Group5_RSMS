//
//  AuditLog.swift
//  Group5_RSMS
//

import Foundation

// MARK: - Model
struct AuditLog: Identifiable, Codable {
    let id: UUID?
    let action: String
    let eventType: AuditEntityType
    let userName: String
    let entity: String
    let beforeData: [String: String]?
    let afterData: [String: String]?
    let createdAt: Date?
    
    // We keep these for the UI color coding
    var actionType: AuditActionType {
        if action.lowercased().contains("created") { return .created }
        if action.lowercased().contains("deleted") { return .deleted }
        return .updated
    }

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case eventType = "event_type"
        case userName = "user_name"
        case entity
        case beforeData = "before_data"
        case afterData = "after_data"
        case createdAt = "created_at"
    }

    var formattedTimestamp: String {
        guard let createdAt = createdAt else { return "Unknown" }
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy, h:mm a"
        return f.string(from: createdAt)
    }

    var relativeTimestamp: String {
        guard let createdAt = createdAt else { return "Just now" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Entity Type (Category filter)
enum AuditEntityType: String, CaseIterable, Codable {
    case product   = "Products"
    case promotion = "Promotions"
    case user      = "Users"
    case tax       = "Tax"

    var iconName: String {
        switch self {
        case .product:   return "tag.fill"
        case .promotion: return "gift.fill"
        case .user:      return "person.fill"
        case .tax:       return "doc.text.fill"
        }
    }
}

// MARK: - Action Type (Operation filter - UI Only)
enum AuditActionType: String, CaseIterable {
    case created = "Created"
    case updated = "Updated"
    case deleted = "Deleted"

    var iconName: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .updated: return "pencil.circle.fill"
        case .deleted: return "trash.circle.fill"
        }
    }
}

// MARK: - Category Filter Enum
enum AuditCategoryFilter: String, CaseIterable {
    case all        = "All"
    case products   = "Products"
    case promotions = "Promotions"
    case users      = "Users"
    case tax        = "Tax"
}

// MARK: - Action Filter Enum
enum AuditOperationFilter: String, CaseIterable {
    case all     = "All"
    case created = "Created"
    case updated = "Updated"
    case deleted = "Deleted"
}
extension AuditLog {
    static func createEntry(
        action: String,
        type: AuditEntityType,
        entityName: String,
        before: [String: String]? = nil,
        after: [String: String]? = nil
    ) -> AuditLog {
        return AuditLog(
            id: nil, // Supabase generates this
            action: action,
            eventType: type,
            userName: "Current Admin", // Replace with actual Auth user name
            entity: entityName,
            beforeData: before,
            afterData: after,
            createdAt: nil // Supabase generates this
        )
    }
}
